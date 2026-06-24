import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FirestoreMirrorService } from '../firebase/firestore-mirror.service';
import { IdService, NowService } from '../common/now.service';
import { HlcService } from '../sync/hlc.service';
import { ClockMap, FieldMap, mergeFieldWrites } from '../sync/apply-field-writes';
import { D, Decimal } from '../domain/decimal';
import { makeMergeDraft, MergeDraft } from '../domain/order-merge';
import {
  MAX_PHOTO_COUNT,
  ORDER_STATUSES,
  RECEIPT_STATUSES,
  CUSTOMER_TIERS,
} from '../domain/constants';
import type { LedgerOrder, LedgerOrderItem } from '../data-model';
import {
  OrderDTO,
  domainToDto,
  rowToDomain,
  rowToDto,
} from './order.mapper';
import {
  BatchStatusChangeInput,
  MergeDraftInput,
  OrderInput,
  OrderPatchInput,
  ReceiptChangeInput,
  StatusChangeInput,
} from './orders.types';

interface PaymentFlags {
  isCardless: boolean;
  isBankTransfer: boolean;
  isCashOnDelivery: boolean;
}

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly now: NowService,
    private readonly ids: IdService,
    private readonly mirror: FirestoreMirrorService,
    private readonly hlc: HlcService,
  ) {}

  async list(uid: string): Promise<OrderDTO[]> {
    // 排除已軟刪除 (tombstone) 的訂單
    const rows = await this.prisma.order.findMany({
      where: { ownerUid: uid, deletedAt: null },
      orderBy: { date: 'desc' },
    });
    return rows.map(rowToDto);
  }

  async get(uid: string, id: string): Promise<OrderDTO> {
    const row = await this.prisma.order.findFirst({
      where: { id, ownerUid: uid, deletedAt: null },
    });
    if (!row) throw new NotFoundException(`找不到訂單 ${id}`);
    return rowToDto(row);
  }

  async create(uid: string, input: OrderInput): Promise<OrderDTO> {
    const isMergeCreate = (input.mergedSourceIDs ?? []).length > 0;
    // merge-create 保留 client id 走 (ownerUid,id) upsert；
    // 重生隨機 id 會使重送短路失效而重複合併
    const domain = await this.normalize(uid, input, { isNew: !isMergeCreate });
    const data = this.toPrismaData(domain, uid);

    if (domain.mergedSourceIDs.length > 0) {
      // 重送冪等：合併後訂單已存在則短路整個交易，
      // 避免回退來源較晚的並行修改
      const existingMerged = await this.prisma.order.findFirst({
        where: { id: domain.id, ownerUid: uid },
      });
      if (existingMerged) {
        return rowToDto(existingMerged);
      }

      // 來源翻 merged 受時鐘守衛：
      // 僅當 mergeClock 嚴格大於來源 status 時鐘才設，否則保留來源較晚狀態
      const mergeClock = this.hlc.encode(this.hlc.generate());
      const sources = await this.prisma.order.findMany({
        where: { id: { in: domain.mergedSourceIDs }, ownerUid: uid },
      });
      const created = await this.prisma.order.create({ data });
      for (const src of sources) {
        const clocks = ((src.fieldClocks as ClockMap | null) ?? {});
        const srcStatusClock = clocks.status ? this.hlc.decode(clocks.status) : null;
        if (srcStatusClock && this.hlc.compare(this.hlc.decode(mergeClock), srcStatusClock) <= 0) {
          continue; // 來源 status 時鐘 ≥ mergeClock：保留來源較晚狀態
        }
        await this.prisma.order.update({
          where: { id: src.id },
          data: { status: 'merged', fieldClocks: { ...clocks, status: mergeClock } },
        });
      }
      const dto = rowToDto(created);
      await this.mirror.mirrorOrder(uid, dto, { writerId: 'server' });
      // 來源訂單狀態可能改為 merged，一併重新鏡像
      await this.remirrorOrders(uid, domain.mergedSourceIDs);
      return dto;
    }

    const created = await this.prisma.order.create({ data });
    const dto = rowToDto(created);
    await this.mirror.mirrorOrder(uid, dto, { writerId: 'server' });
    return dto;
  }

  async update(uid: string, id: string, input: OrderInput): Promise<OrderDTO> {
    await this.ensureExists(uid, id);
    const domain = await this.normalize(uid, { ...input, id }, { isNew: false });
    const data = this.toPrismaData(domain, uid);
    const updated = await this.prisma.order.update({ where: { id }, data });
    const dto = rowToDto(updated);
    // 帶投影信封 (既有每欄位 HLC + writerId)，
    // 避免整份覆蓋清掉 _fieldClocks 使 pull 端退化整欄 LWW
    await this.mirror.mirrorOrder(uid, dto, {
      fieldClocks: ((updated.fieldClocks as ClockMap | null) ?? {}),
      writerId: 'server',
    });
    return dto;
  }

  // 欄位級合併寫入：以每欄位 HLC 逐欄合併 incoming patch (同欄位時鐘決勝、不同欄位各自存活)，
  // 回傳合併後 DTO 與被套用欄位的權威時鐘 (供 client 清 dirty)；對完整列重跑 normalize 重算衍生欄位
  async patch(
    uid: string,
    id: string,
    input: OrderPatchInput,
  ): Promise<{ order: OrderDTO; appliedFieldClocks: Record<string, string> }> {
    const rawFields = input.changedFields ?? {};
    const fieldClocks = input.fieldClocks ?? {};

    // status 為 sticky 終態欄：
    // 一般 PATCH 忽略它 (merged 只由合併流程寫入)，於合併前剝除
    const changedFields: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(rawFields)) {
      if (k === 'status') continue;
      changedFields[k] = v;
    }
    const fields = Object.keys(changedFields);

    // 偏移守門 + 推進伺服器 HLC (合併前必跑)：缺時鐘或超容忍即 400
    for (const field of fields) {
      const enc = fieldClocks[field];
      if (!enc) throw new BadRequestException(`欄位 ${field} 缺少時鐘`);
      const clock = this.hlc.decode(enc);
      this.hlc.assertWithinTolerance(clock);
      this.hlc.receive(clock);
    }

    // 刪除 tombstone 的時鐘亦先守門 + receive (與欄位時鐘同一套 p→c→w 比較器)
    let deleteClockEnc: string | null = null;
    if (input.delete) {
      if (!input.delete.clock) throw new BadRequestException('刪除缺少時鐘');
      const dc = this.hlc.decode(input.delete.clock);
      this.hlc.assertWithinTolerance(dc);
      this.hlc.receive(dc);
      deleteClockEnc = input.delete.clock;
    }

    const existing = await this.prisma.order.findFirst({ where: { id, ownerUid: uid } });

    // 跨使用者碰撞守門
    // (client UUID 理論上不撞；防覆蓋他人資料、且不洩漏存在性)
    if (!existing) {
      const collision = await this.prisma.order.findUnique({
        where: { id },
        select: { ownerUid: true },
      });
      if (collision && collision.ownerUid !== uid) {
        throw new NotFoundException(`找不到訂單 ${id}`);
      }
    }

    // 純刪除 (無 changedFields)：
    // 設 deletedAt + deleteClock、保留整列與 fieldClocks、鏡像顯式 tombstone
    if (fields.length === 0 && deleteClockEnc) {
      if (!existing) throw new BadRequestException('空白 patch 無法建立訂單');
      return this.applyDelete(uid, id, existing, deleteClockEnc);
    }

    if (fields.length === 0) {
      if (!existing) throw new BadRequestException('空白 patch 無法建立訂單');
      return { order: rowToDto(existing), appliedFieldClocks: {} };
    }

    // 復活判定：tombstone 列僅當任一 incoming 欄位 clock 嚴格大於 storedDeleteClock 才復活
    const storedDeleteClock =
      existing && (existing.deleteClock as string) ? (existing.deleteClock as string) : null;
    const isDeleted = !!(existing && existing.deletedAt);

    const storedValues: FieldMap = existing ? orderDomainToFlat(rowToDomain(existing)) : {};
    const storedClocks: ClockMap = (existing?.fieldClocks as ClockMap | null) ?? {};
    const merged = mergeFieldWrites(storedValues, storedClocks, { changedFields, fieldClocks });

    // photos 內容雜湊 union：含 photos 時一律與 stored 取聯集、不受時鐘門檻吞掉 (兩端新增皆存活)；
    // photos 欄位 clock 取兩端 max，確保聯集值在投影傳播 (否則停在較低 clock 會被既有較高 stored 略過)
    if (changedFields.photos !== undefined) {
      merged.values.photos = unionPhotos(
        (storedValues.photos as string[] | undefined) ?? [],
        changedFields.photos as string[],
      );
      const incomingPhotoClock = fieldClocks.photos;
      const storedPhotoClock = storedClocks.photos;
      const maxPhotoClock = this.maxClock(storedPhotoClock, incomingPhotoClock);
      if (maxPhotoClock) {
        merged.clocks.photos = maxPhotoClock;
        merged.appliedClocks.photos = maxPhotoClock;
      }
    }

    if (isDeleted) {
      // 畸形列防護：有 deletedAt 但 deleteClock 為空字串時視為硬 tombstone，
      // 否則任何 patch 都能免費復活
      if (!storedDeleteClock) {
        return this.persistDeleted(
          uid,
          id,
          merged.values,
          merged.clocks,
          '',
          merged.appliedClocks,
        );
      }

      // 復活判定須用 incoming 原始 fieldClocks 與 deleteClock 比，不可用 merged.appliedClocks——
      // 後者在 incoming 落敗時 fallback 成 stored clock，會把落敗寫入誤判為復活
      const beatsDelete = this.anyIncomingBeatsDelete(fieldClocks, fields, storedDeleteClock);
      if (!beatsDelete) {
        // 維持刪除：保留 tombstone (含已合併但不足以復活的較高欄位時鐘)、重寫 tombstone 鏡像
        return this.persistDeleted(
          uid,
          id,
          merged.values,
          merged.clocks,
          storedDeleteClock as string,
          merged.appliedClocks,
        );
      }
    }

    // 復活或一般合併：清 deletedAt/deleteClock、寫入合併後完整列
    const domain = await this.normalize(uid, orderFlatToInput(merged.values, id), {
      isNew: false,
    });
    const data: Prisma.OrderUncheckedCreateInput = {
      ...this.toPrismaData(domain, uid),
      fieldClocks: merged.clocks as Prisma.InputJsonValue,
      deletedAt: null,
      deleteClock: '',
    };
    const saved = await this.prisma.order.upsert({
      where: { id },
      create: data,
      update: data,
    });

    const dto = rowToDto(saved);
    const mirrored = await this.mirror.mirrorOrder(uid, dto, {
      fieldClocks: merged.clocks,
      writerId: 'server',
    });
    await this.markMirrorState(uid, id, mirrored);
    return { order: dto, appliedFieldClocks: merged.appliedClocks };
  }

  // 軟刪除：設 deletedAt + server HLC deleteClock、
  // 保留整列與 fieldClocks、鏡像顯式 tombstone (不硬刪)
  async remove(uid: string, id: string): Promise<void> {
    const existing = await this.prisma.order.findFirst({ where: { id, ownerUid: uid } });
    if (!existing) throw new NotFoundException(`找不到訂單 ${id}`);
    const deleteClock = this.hlc.encode(this.hlc.generate());
    await this.applyDelete(uid, id, existing, deleteClock);
  }

  // tombstone 90 天保留窗後硬清除 (由 MirrorSweepService 的 @Interval 一併呼叫)；
  // 保留界以注入的 now 計算
  async purgeExpiredTombstones(retentionDays = TOMBSTONE_RETENTION_DAYS): Promise<number> {
    const cutoff = new Date(this.now.now().getTime() - retentionDays * DAY_MS);
    const result = await this.prisma.order.deleteMany({
      where: { deletedAt: { not: null, lt: cutoff } },
    });
    return result.count ?? 0;
  }

  async setStatus(uid: string, id: string, input: StatusChangeInput): Promise<OrderDTO> {
    const status = this.validStatus(input.status);
    if (!status) throw new BadRequestException('無效的訂單狀態');
    await this.ensureExists(uid, id);
    const updated = await this.prisma.order.update({
      where: { id },
      data: { status },
    });
    const dto = rowToDto(updated);
    await this.mirror.mirrorOrder(uid, dto, {
      fieldClocks: ((updated.fieldClocks as ClockMap | null) ?? {}),
      writerId: 'server',
    });
    return dto;
  }

  // 批次更改狀態：updateMany 依 ownerUid 圈更新已選訂單後重新鏡像；
  // 不屬呼叫者的 id 不受影響也不報錯
  async batchSetStatus(uid: string, input: BatchStatusChangeInput): Promise<OrderDTO[]> {
    const status = this.validStatus(input.status);
    if (!status) throw new BadRequestException('無效的訂單狀態');
    if (status === 'merged') throw new BadRequestException('不可批次設為已合併狀態');

    const rawIds = Array.isArray(input.ids) ? input.ids : [];
    const ids = uniqueNonEmpty(rawIds.filter((v): v is string => typeof v === 'string'));
    if (ids.length === 0) return [];

    await this.prisma.order.updateMany({
      where: { id: { in: ids }, ownerUid: uid },
      data: { status },
    });

    const rows = await this.prisma.order.findMany({
      where: { id: { in: ids }, ownerUid: uid },
    });
    await Promise.all(
      rows.map((row) =>
        this.mirror.mirrorOrder(uid, rowToDto(row), {
          fieldClocks: ((row.fieldClocks as ClockMap | null) ?? {}),
          writerId: 'server',
        }),
      ),
    );
    return rows.map(rowToDto);
  }

  async setReceipt(uid: string, id: string, input: ReceiptChangeInput): Promise<OrderDTO> {
    if (!input.status || !RECEIPT_STATUSES.includes(input.status)) {
      throw new BadRequestException('無效的收款狀態');
    }
    await this.ensureExists(uid, id);
    const updated = await this.prisma.order.update({
      where: { id },
      data: { paymentReceiptStatus: input.status },
    });
    const dto = rowToDto(updated);
    await this.mirror.mirrorOrder(uid, dto, {
      fieldClocks: ((updated.fieldClocks as ClockMap | null) ?? {}),
      writerId: 'server',
    });
    return dto;
  }

  // 合併草稿：取兩筆訂單算出合併欄位 (含加權費率)，
  // 照片是否超量交由前端挑選步驟處理
  async mergeDraft(uid: string, input: MergeDraftInput): Promise<{
    draft: MergeDraft;
    photosOverLimit: boolean;
    combinedPhotoCount: number;
    maxPhotoCount: number;
  }> {
    if (!input.primaryId || !input.secondaryId) {
      throw new BadRequestException('需要主訂單與副訂單 id');
    }
    if (input.primaryId === input.secondaryId) {
      throw new BadRequestException('不可與自身合併');
    }

    const [primaryRow, secondaryRow] = await Promise.all([
      this.prisma.order.findFirst({ where: { id: input.primaryId, ownerUid: uid } }),
      this.prisma.order.findFirst({ where: { id: input.secondaryId, ownerUid: uid } }),
    ]);
    if (!primaryRow || !secondaryRow) throw new NotFoundException('找不到訂單');

    const primary = rowToDomain(primaryRow);
    const secondary = rowToDomain(secondaryRow);

    // 合併資格：同幣別、同客戶名稱、雙方狀態皆非 merged/cancelled
    const blocked = new Set(['merged', 'cancelled']);
    if (
      primary.currency !== secondary.currency ||
      primary.customer.name !== secondary.customer.name ||
      blocked.has(primary.status) ||
      blocked.has(secondary.status)
    ) {
      throw new BadRequestException('兩筆訂單不符合併資格');
    }

    const cardlessNames = await this.cardlessNameSet(uid);
    const isCardless = (name: string): boolean => cardlessNames.has(name);

    const draft = makeMergeDraft(primary, secondary, this.now.now(), isCardless);
    const combinedPhotoCount = draft.photos.length;

    return {
      draft,
      photosOverLimit: combinedPhotoCount > MAX_PHOTO_COUNT,
      combinedPhotoCount,
      maxPhotoCount: MAX_PHOTO_COUNT,
    };
  }

  // 主檔改名時 cascade 到訂單 (純量欄位 updateMany)，僅限該使用者的訂單
  async cascadeRenameScalar(
    uid: string,
    field: 'orderSource' | 'paymentMethod' | 'verificationStatus',
    oldName: string,
    newName: string,
  ): Promise<void> {
    if (oldName === newName) return;
    // 僅圈未刪除列：tombstone 列不得被 cascade 改名觸及 (避免在投影復活成活文件)
    const affected = await this.prisma.order.findMany({
      where: { [field]: oldName, ownerUid: uid, deletedAt: null },
      select: { id: true, fieldClocks: true },
    });
    if (affected.length === 0) return;
    // cascade 為 server 權威改名：逐列改值並以 server HLC 蓋章 fieldClock，
    // 否則舊 clock 的 client 寫入會回退它
    await this.prisma.$transaction(
      affected.map((row) => {
        const clocks = (row.fieldClocks as ClockMap | null) ?? {};
        return this.prisma.order.update({
          where: { id: row.id },
          data: {
            [field]: newName,
            fieldClocks: { ...clocks, [field]: this.hlc.encode(this.hlc.generate()) },
          },
        });
      }),
    );
    await this.remirrorOrders(uid, affected.map((r) => r.id));
  }

  // 類別改名 cascade：逐筆把 categories 陣列內 old→new 取代並去重
  async cascadeRenameCategory(uid: string, oldName: string, newName: string): Promise<void> {
    await this.cascadeRenameArray(uid, 'categories', oldName, newName);
  }

  // 開團改名 cascade：逐筆把 campaignNames 陣列內 old→new 取代並去重
  async cascadeRenameCampaign(uid: string, oldName: string, newName: string): Promise<void> {
    await this.cascadeRenameArray(uid, 'campaignNames', oldName, newName);
  }

  // lookup 刪除 cascade-strip：把被刪除的純量值從該使用者訂單清空，
  // 使刪除不致孤立參照 (清空後 normalize 補 fallback)
  async cascadeStripScalar(
    uid: string,
    field: 'orderSource' | 'paymentMethod' | 'verificationStatus',
    name: string,
  ): Promise<void> {
    if (!name) return;
    const rows = await this.prisma.order.findMany({
      where: { [field]: name, ownerUid: uid, deletedAt: null },
      select: { id: true, fieldClocks: true },
    });
    if (rows.length === 0) return;
    // cascade-strip 為 server 權威清空：逐列清值並以 server HLC 蓋章 fieldClock，
    // 不被舊 clock 的 client 寫入回退
    await this.prisma.$transaction(
      rows.map((row) => {
        const clocks = (row.fieldClocks as ClockMap | null) ?? {};
        return this.prisma.order.update({
          where: { id: row.id },
          data: {
            [field]: '',
            fieldClocks: { ...clocks, [field]: this.hlc.encode(this.hlc.generate()) },
          },
        });
      }),
    );
    await this.remirrorOrders(uid, rows.map((r) => r.id));
  }

  // 類別 / 開團刪除 cascade-strip：逐筆把被刪除的元素從 categories / campaignNames 陣列剝除
  // (元素級、只動含該元素的列；並行不相交元素存活)
  async cascadeStripCategory(uid: string, name: string): Promise<void> {
    await this.cascadeStripArray(uid, 'categories', name);
  }

  async cascadeStripCampaign(uid: string, name: string): Promise<void> {
    await this.cascadeStripArray(uid, 'campaignNames', name);
  }

  private async cascadeStripArray(
    uid: string,
    field: 'categories' | 'campaignNames',
    name: string,
  ): Promise<void> {
    if (!name) return;
    const rows = await this.prisma.order.findMany({
      where: { [field]: { has: name }, ownerUid: uid, deletedAt: null },
      select: { id: true, categories: true, campaignNames: true, fieldClocks: true },
    });
    if (rows.length === 0) return;
    await this.prisma.$transaction(
      rows.map((row) => {
        const current = field === 'categories' ? row.categories : row.campaignNames;
        const stripped = current.filter((v) => v !== name);
        // 以 server HLC 蓋章該陣列欄位 fieldClock，使 cascade-strip 成帶時鐘的權威寫入
        const clocks = (row.fieldClocks as ClockMap | null) ?? {};
        return this.prisma.order.update({
          where: { id: row.id },
          data: {
            [field]: stripped,
            fieldClocks: { ...clocks, [field]: this.hlc.encode(this.hlc.generate()) },
          },
        });
      }),
    );
    await this.remirrorOrders(uid, rows.map((r) => r.id));
  }

  private async cascadeRenameArray(
    uid: string,
    field: 'categories' | 'campaignNames',
    oldName: string,
    newName: string,
  ): Promise<void> {
    if (oldName === newName) return;
    // 僅圈未刪除列：tombstone 列不得被 cascade 改名觸及 (避免在投影復活成活文件)
    const rows = await this.prisma.order.findMany({
      where: { [field]: { has: oldName }, ownerUid: uid, deletedAt: null },
      select: { id: true, categories: true, campaignNames: true, fieldClocks: true },
    });
    await this.prisma.$transaction(
      rows.map((row) => {
        const current = field === 'categories' ? row.categories : row.campaignNames;
        const replaced = uniquePreserve(current.map((v) => (v === oldName ? newName : v)));
        // 以 server HLC 蓋章該陣列欄位 fieldClock，使 cascade 改名成帶時鐘的權威寫入
        const clocks = (row.fieldClocks as ClockMap | null) ?? {};
        return this.prisma.order.update({
          where: { id: row.id },
          data: {
            [field]: replaced,
            fieldClocks: { ...clocks, [field]: this.hlc.encode(this.hlc.generate()) },
          },
        });
      }),
    );
    await this.remirrorOrders(uid, rows.map((r) => r.id));
  }

  // MARK: - 私有

  // 套用刪除 tombstone：設 deletedAt + deleteClock、
  // 保留整列與 fieldClocks、鏡像顯式 tombstone
  private async applyDelete(
    uid: string,
    id: string,
    existing: Record<string, unknown>,
    deleteClock: string,
  ): Promise<{ order: OrderDTO; appliedFieldClocks: Record<string, string> }> {
    const saved = await this.prisma.order.update({
      where: { id },
      data: { deletedAt: this.now.now(), deleteClock },
    });
    const dto = rowToDto(saved as never);
    const fieldClocks = (existing.fieldClocks as ClockMap | null) ?? {};
    const mirrored = await this.mirror.mirrorOrderTombstone(uid, dto, deleteClock, {
      fieldClocks,
      writerId: 'server',
    });
    await this.markMirrorState(uid, id, mirrored);
    return { order: dto, appliedFieldClocks: {} };
  }

  // 維持刪除但仍持久化已合併 (未足以復活) 的較高欄位時鐘與值：
  // 保留 tombstone、重寫 tombstone 鏡像
  private async persistDeleted(
    uid: string,
    id: string,
    values: FieldMap,
    clocks: ClockMap,
    deleteClock: string,
    appliedClocks: ClockMap,
  ): Promise<{ order: OrderDTO; appliedFieldClocks: Record<string, string> }> {
    const domain = await this.normalize(uid, orderFlatToInput(values, id), { isNew: false });
    const data: Prisma.OrderUncheckedCreateInput = {
      ...this.toPrismaData(domain, uid),
      fieldClocks: clocks as Prisma.InputJsonValue,
      deletedAt: this.now.now(),
      deleteClock,
    };
    const saved = await this.prisma.order.upsert({ where: { id }, create: data, update: data });
    const dto = rowToDto(saved);
    const mirrored = await this.mirror.mirrorOrderTombstone(uid, dto, deleteClock, {
      fieldClocks: clocks,
      writerId: 'server',
    });
    await this.markMirrorState(uid, id, mirrored);
    return { order: dto, appliedFieldClocks: appliedClocks };
  }

  // 取兩個編碼 HLC 的較大者 (p→c→w)；
  // 任一為空時回另一個 (photos 欄位 clock 取兩端 max 用)
  private maxClock(a: string | undefined, b: string | undefined): string | undefined {
    if (!a) return b;
    if (!b) return a;
    return this.hlc.compare(this.hlc.decode(a), this.hlc.decode(b)) >= 0 ? a : b;
  }

  // 復活判定：任一 incoming 欄位時鐘嚴格大於 storedDeleteClock 即復活 (p→c→w，位元全等 delete 勝)；
  // storedDeleteClock 為空視為無 tombstone
  private anyIncomingBeatsDelete(
    appliedClocks: ClockMap,
    fields: string[],
    storedDeleteClock: string | null,
  ): boolean {
    if (!storedDeleteClock) return true;
    const dc = this.hlc.decode(storedDeleteClock);
    for (const field of fields) {
      const applied = appliedClocks[field];
      if (!applied) continue;
      if (this.hlc.compare(this.hlc.decode(applied), dc) > 0) return true;
    }
    return false;
  }

  // 鏡像結果回填：成功清 mirrorDirty；
  // 失敗蓋 mirrorDirty + mirrorPendingSinceClock 交 MirrorSweepService 修復
  private async markMirrorState(uid: string, id: string, mirrored: boolean): Promise<void> {
    if (mirrored) {
      await this.prisma.order.updateMany({
        where: { id, ownerUid: uid, mirrorDirty: true },
        data: { mirrorDirty: false, mirrorPendingSinceClock: null },
      });
      return;
    }
    await this.prisma.order.updateMany({
      where: { id, ownerUid: uid },
      data: { mirrorDirty: true, mirrorPendingSinceClock: this.hlc.encode(this.hlc.generate()) },
    });
  }

  // 重新鏡像一組訂單 (cascade 改名或合併後)。依 deletedAt 分流：tombstone 列走 mirrorOrderTombstone
  // 以維持顯式 _deleted:true 不被復活；信封一律帶 row.fieldClocks + writerId='server' 避免退化整欄 LWW
  private async remirrorOrders(uid: string, ids: string[]): Promise<void> {
    if (ids.length === 0) return;
    const rows = await this.prisma.order.findMany({ where: { id: { in: ids }, ownerUid: uid } });
    await Promise.all(
      rows.map((row) => {
        const fieldClocks = (row.fieldClocks as ClockMap | null) ?? {};
        const dto = rowToDto(row as never);
        if (row.deletedAt) {
          return this.mirror.mirrorOrderTombstone(uid, dto, (row.deleteClock as string) ?? '', {
            fieldClocks,
            writerId: 'server',
          });
        }
        return this.mirror.mirrorOrder(uid, dto, { fieldClocks, writerId: 'server' });
      }),
    );
  }

  private async ensureExists(uid: string, id: string): Promise<void> {
    const count = await this.prisma.order.count({ where: { id, ownerUid: uid } });
    if (count === 0) throw new NotFoundException(`找不到訂單 ${id}`);
  }

  private async resolvePaymentFlags(uid: string, name: string): Promise<PaymentFlags> {
    if (!name) return { isCardless: false, isBankTransfer: false, isCashOnDelivery: false };
    const pm = await this.prisma.paymentMethod.findUnique({
      where: { ownerUid_name: { ownerUid: uid, name } },
    });
    return {
      isCardless: pm?.isCardless ?? false,
      isBankTransfer: pm?.isBankTransfer ?? false,
      isCashOnDelivery: pm?.isCashOnDelivery ?? false,
    };
  }

  private async cardlessNameSet(uid: string): Promise<Set<string>> {
    const methods = await this.prisma.paymentMethod.findMany({
      where: { isCardless: true, ownerUid: uid },
      select: { name: true },
    });
    return new Set(methods.map((m) => m.name));
  }

  // 正規化前端草稿 (對齊 iOS applyEditDraft)：
  // clamp 金額/費率、依付款方式旗標清欄位、補 fallback
  private async normalize(
    uid: string,
    input: OrderInput,
    opts: { isNew: boolean },
  ): Promise<LedgerOrder> {
    const paymentMethod = (input.paymentMethod ?? '').trim();
    const flags = await this.resolvePaymentFlags(uid, paymentMethod);

    const cardlessDeduction = flags.isCardless ? clampMin0(input.cardlessDeductionAmount) : '0';
    const cardlessSupplement = flags.isCardless ? clampMin0(input.cardlessSupplementAmount) : '0';
    const verificationStatus =
      flags.isCardless || flags.isBankTransfer ? (input.verificationStatus ?? '').trim() : '';

    const name = (input.customer?.name ?? '').trim() || '未命名客戶';
    const initials = (input.customer?.initials ?? '').trim() || deriveInitials(name);
    const tier = CUSTOMER_TIERS.includes(input.customer?.tier as never)
      ? (input.customer!.tier as LedgerOrder['customer']['tier'])
      : 'new';

    const categories = uniqueNonEmpty(input.categories ?? []);
    const finalCategories = categories.length > 0 ? categories : ['未分類'];
    const campaignNames = uniqueNonEmpty(input.campaignNames ?? []);

    const status = this.validStatus(input.status) ?? 'quoting';
    const paymentReceiptStatus =
      input.paymentReceiptStatus && RECEIPT_STATUSES.includes(input.paymentReceiptStatus)
        ? input.paymentReceiptStatus
        : 'pending';

    const date = input.date ? new Date(input.date) : this.now.now();
    const isoDate = Number.isNaN(date.getTime()) ? this.now.now().toISOString() : date.toISOString();

    const items: LedgerOrderItem[] = (input.items ?? []).map((it) => ({
      id: (it.id ?? this.ids.uuid()) as string,
      name: (it.name ?? '').trim(),
      quantity: Math.max(0, Math.trunc(Number(it.quantity ?? 0)) || 0),
      unitPrice: clampMin0(it.unitPrice as string | undefined),
    }));

    const photos = (input.photos ?? []).slice(0, MAX_PHOTO_COUNT);

    return {
      // isNew → server 生成 id；
      // 否則保留 client input.id (merge-create/update/patch 走 upsert)；缺則生成一次
      id: opts.isNew ? this.ids.newOrderId() : (input.id as string) || this.ids.newOrderId(),
      customer: { name, initials, tier },
      status,
      currency: (input.currency ?? 'TWD').trim() || 'TWD',
      date: isoDate,
      items,
      itemCost: clampMin0(input.itemCost),
      domesticShipping: clampMin0(input.domesticShipping),
      internationalShipping: clampMin0(input.internationalShipping),
      foreignDomesticShipping: clampMin0(input.foreignDomesticShipping),
      cardFeeRate: clampRate(input.cardFeeRate),
      platformFeeRate: clampRate(input.platformFeeRate),
      paymentFeeRate: clampRate(input.paymentFeeRate),
      chargedAmount: clampMin0(input.chargedAmount),
      cardlessDeductionAmount: cardlessDeduction,
      cardlessSupplementAmount: cardlessSupplement,
      orderSource: (input.orderSource ?? '').trim() || '未指定',
      categories: finalCategories,
      paymentMethod,
      notes: input.notes ?? '',
      verificationStatus,
      campaignNames,
      paymentReceiptStatus,
      isCashOnDelivery: flags.isCashOnDelivery,
      photos,
      mergedSourceIDs: input.mergedSourceIDs ?? [],
    };
  }

  private validStatus(value: unknown): LedgerOrder['status'] | null {
    return ORDER_STATUSES.includes(value as never) ? (value as LedgerOrder['status']) : null;
  }

  private toPrismaData(o: LedgerOrder, uid: string): Prisma.OrderUncheckedCreateInput {
    return {
      id: o.id,
      ownerUid: uid,
      customerName: o.customer.name,
      customerInitials: o.customer.initials,
      customerTier: o.customer.tier,
      status: o.status,
      currency: o.currency,
      date: new Date(o.date),
      items: o.items as unknown as Prisma.InputJsonValue,
      itemCost: o.itemCost,
      domesticShipping: o.domesticShipping,
      internationalShipping: o.internationalShipping,
      foreignDomesticShipping: o.foreignDomesticShipping,
      cardFeeRate: o.cardFeeRate,
      platformFeeRate: o.platformFeeRate,
      paymentFeeRate: o.paymentFeeRate,
      chargedAmount: o.chargedAmount,
      cardlessDeductionAmount: o.cardlessDeductionAmount,
      cardlessSupplementAmount: o.cardlessSupplementAmount,
      orderSource: o.orderSource,
      categories: o.categories,
      paymentMethod: o.paymentMethod,
      notes: o.notes,
      verificationStatus: o.verificationStatus,
      campaignNames: o.campaignNames,
      paymentReceiptStatus: o.paymentReceiptStatus,
      isCashOnDelivery: o.isCashOnDelivery,
      photos: o.photos,
      mergedSourceIDs: o.mergedSourceIDs,
    };
  }
}

// tombstone 保留窗 90 天 (= 支援的最大「離線且持續編輯」窗)
const TOMBSTONE_RETENTION_DAYS = 90;
const DAY_MS = 24 * 60 * 60 * 1000;

// 照片以內容雜湊取聯集：相同內容只保留一張、兩端並行新增皆存活
// (切片到 MAX_PHOTO_COUNT 由 normalize 處理)
function unionPhotos(stored: string[], incoming: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const p of [...stored, ...incoming]) {
    const hash = photoContentHash(p);
    if (seen.has(hash)) continue;
    seen.add(hash);
    out.push(p);
  }
  return out;
}

// 照片內容雜湊：去 data URL 前綴後對解碼位元組取 sha256，
// 使相同影像得相同鍵
function photoContentHash(value: string): string {
  const comma = value.indexOf(',');
  const base64 = value.startsWith('data:') && comma >= 0 ? value.slice(comma + 1) : value;
  return createHash('sha256').update(Buffer.from(base64, 'base64')).digest('hex');
}

// 金額 clamp 至 >= 0；空值視為 0
function clampMin0(value: string | undefined): string {
  return Decimal.max(0, D(value)).toString();
}

// 費率 clamp 至 [0, 1]
function clampRate(value: string | undefined): string {
  return Decimal.max(0, Decimal.min(1, D(value))).toString();
}

// 去重並保序 (cascade 改名後可能產生重複元素)
function uniquePreserve(values: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const v of values) {
    if (seen.has(v)) continue;
    seen.add(v);
    out.push(v);
  }
  return out;
}

function uniqueNonEmpty(values: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of values) {
    const v = (raw ?? '').trim();
    if (!v || seen.has(v)) continue;
    seen.add(v);
    out.push(v);
  }
  return out;
}

// 由客戶名稱推導縮寫：多詞取前兩詞首字母；
// 單詞拉丁取前兩字母、CJK 取首字
function deriveInitials(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return '?';
  const parts = trimmed.split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  const first = trimmed[0];
  if (/[A-Za-z]/.test(first)) return trimmed.slice(0, 2).toUpperCase();
  return first;
}

// 領域訂單 → 可合併的 flat 欄位圖：攤平 customer，排除 id、mergedSourceIDs (唯讀) 與衍生欄位
// isCashOnDelivery、customerInitials (由 normalize 重算、不參與合併)
// export 供 conformance 測試核對欄位分類
export function orderDomainToFlat(o: LedgerOrder): FieldMap {
  return {
    customerName: o.customer.name,
    customerTier: o.customer.tier,
    status: o.status,
    currency: o.currency,
    date: o.date,
    items: o.items,
    itemCost: o.itemCost,
    domesticShipping: o.domesticShipping,
    internationalShipping: o.internationalShipping,
    foreignDomesticShipping: o.foreignDomesticShipping,
    cardFeeRate: o.cardFeeRate,
    platformFeeRate: o.platformFeeRate,
    paymentFeeRate: o.paymentFeeRate,
    chargedAmount: o.chargedAmount,
    cardlessDeductionAmount: o.cardlessDeductionAmount,
    cardlessSupplementAmount: o.cardlessSupplementAmount,
    orderSource: o.orderSource,
    categories: o.categories,
    paymentMethod: o.paymentMethod,
    notes: o.notes,
    verificationStatus: o.verificationStatus,
    campaignNames: o.campaignNames,
    paymentReceiptStatus: o.paymentReceiptStatus,
    photos: o.photos,
  };
}

// flat 欄位圖 → OrderInput (供 normalize)；缺欄位帶 undefined 由 normalize 補預設與 clamp
function orderFlatToInput(flat: FieldMap, id: string): OrderInput {
  const str = (v: unknown): string | undefined => (v === undefined ? undefined : String(v));
  return {
    id,
    customer: {
      name: str(flat.customerName),
      // customerInitials 為 B 類衍生：不從 flat 帶入，由 normalize 從勝出的 customerName 重算
      tier: flat.customerTier as LedgerOrder['customer']['tier'] | undefined,
    },
    status: flat.status as LedgerOrder['status'] | undefined,
    currency: str(flat.currency),
    date: str(flat.date),
    items: flat.items as OrderInput['items'],
    itemCost: str(flat.itemCost),
    domesticShipping: str(flat.domesticShipping),
    internationalShipping: str(flat.internationalShipping),
    foreignDomesticShipping: str(flat.foreignDomesticShipping),
    cardFeeRate: str(flat.cardFeeRate),
    platformFeeRate: str(flat.platformFeeRate),
    paymentFeeRate: str(flat.paymentFeeRate),
    chargedAmount: str(flat.chargedAmount),
    cardlessDeductionAmount: str(flat.cardlessDeductionAmount),
    cardlessSupplementAmount: str(flat.cardlessSupplementAmount),
    orderSource: str(flat.orderSource),
    categories: flat.categories as string[] | undefined,
    paymentMethod: str(flat.paymentMethod),
    notes: str(flat.notes),
    verificationStatus: str(flat.verificationStatus),
    campaignNames: flat.campaignNames as string[] | undefined,
    paymentReceiptStatus: flat.paymentReceiptStatus as
      | LedgerOrder['paymentReceiptStatus']
      | undefined,
    photos: flat.photos as string[] | undefined,
  };
}
