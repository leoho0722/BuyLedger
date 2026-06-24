import { Injectable, Logger } from '@nestjs/common';
import { Interval } from '@nestjs/schedule';

import { PrismaService } from '../prisma/prisma.service';
import { FirestoreMirrorService } from '../firebase/firestore-mirror.service';
import { OrdersService } from '../orders/orders.service';
import { rowToDto } from '../orders/order.mapper';

// 鏡像失敗自我修復掃描：
// 週期重算 dirty 列重新鏡像，使永久失敗的鏡像最終收斂；
// 一併 purge 過期 tombstone
// 只存 dirty「鍵」、從 SoT (Postgres) 重算，非持久化 payload outbox
@Injectable()
export class MirrorSweepService {
  private readonly logger = new Logger(MirrorSweepService.name);

  // 每輪批次上限：避免單輪掃描灌爆 Firestore 與後端
  private static readonly BATCH_LIMIT = 100;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mirror: FirestoreMirrorService,
    private readonly orders: OrdersService,
  ) {}

  // 每 30 秒觸發；掃描失敗只記錄、不拋出，避免拖垮排程器
  @Interval(30_000)
  async sweep(): Promise<void> {
    try {
      const remirrored = await this.sweepOrders();
      const purged = await this.orders.purgeExpiredTombstones();
      if (remirrored > 0 || purged > 0) {
        this.logger.log(`鏡像掃描：重新鏡像 ${remirrored} 筆、清除過期 tombstone ${purged} 筆`);
      }
    } catch (err) {
      this.logger.warn(`鏡像掃描失敗：${String(err)}`);
    }
  }

  // 逐筆從 Postgres 重算 DTO 重新鏡像、成功清 dirty，回傳本輪成功筆數
  private async sweepOrders(): Promise<number> {
    const dirty = await this.prisma.order.findMany({
      where: { mirrorDirty: true },
      orderBy: { mirrorPendingSinceClock: 'asc' },
      take: MirrorSweepService.BATCH_LIMIT,
    });
    let cleared = 0;
    for (const row of dirty) {
      const dto = rowToDto(row);
      const fieldClocks = (row.fieldClocks as Record<string, string> | null) ?? {};
      // tombstone 列重寫顯式 tombstone；一般列重寫帶信封的文件
      const ok = row.deletedAt
        ? await this.mirror.mirrorOrderTombstone(row.ownerUid, dto, row.deleteClock, {
            fieldClocks,
            writerId: 'server',
          })
        : await this.mirror.mirrorOrder(row.ownerUid, dto, { fieldClocks, writerId: 'server' });
      if (ok) {
        await this.prisma.order.updateMany({
          where: { id: row.id, ownerUid: row.ownerUid },
          data: { mirrorDirty: false, mirrorPendingSinceClock: null },
        });
        cleared++;
      }
    }
    return cleared;
  }
}
