import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Campaign as CampaignRow } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FirestoreMirrorService } from '../firebase/firestore-mirror.service';
import { IdService, NowService } from '../common/now.service';
import { OrdersService } from '../orders/orders.service';
import { CAMPAIGN_STATUSES } from '../domain/constants';
import type { Campaign } from '../data-model';

export interface CampaignInput {
  name?: string;
  openDate?: string;
  closeDate?: string | null;
  notes?: string;
}

export interface CampaignStatusInput {
  status?: Campaign['status'];
}

@Injectable()
export class CampaignsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly now: NowService,
    private readonly ids: IdService,
    private readonly orders: OrdersService,
    private readonly mirror: FirestoreMirrorService,
  ) {}

  async list(uid: string): Promise<Campaign[]> {
    await this.autoClose(uid);
    const rows = await this.prisma.campaign.findMany({
      where: { ownerUid: uid },
      orderBy: { openDate: 'desc' },
    });
    return rows.map(toDto);
  }

  async get(uid: string, id: string): Promise<Campaign> {
    await this.autoClose(uid);
    const row = await this.prisma.campaign.findFirst({ where: { id, ownerUid: uid } });
    if (!row) throw new NotFoundException(`找不到開團 ${id}`);
    return toDto(row);
  }

  async create(uid: string, input: CampaignInput): Promise<Campaign> {
    const name = (input.name ?? '').trim();
    if (!name) throw new BadRequestException('開團名稱不可為空');
    const row = await this.prisma.campaign.create({
      data: {
        id: this.ids.uuid(),
        ownerUid: uid,
        name,
        openDate: input.openDate ? new Date(input.openDate) : this.now.now(),
        closeDate: input.closeDate ? new Date(input.closeDate) : null,
        status: 'ongoing',
        settledDate: null,
        notes: input.notes ?? '',
      },
    });
    const dto = toDto(row);
    await this.mirror.upsert(uid, 'campaigns', dto.id, dto);
    return dto;
  }

  async update(uid: string, id: string, input: CampaignInput): Promise<Campaign> {
    const existing = await this.prisma.campaign.findFirst({ where: { id, ownerUid: uid } });
    if (!existing) throw new NotFoundException(`找不到開團 ${id}`);

    const name = input.name !== undefined ? (input.name ?? '').trim() : existing.name;
    if (!name) throw new BadRequestException('開團名稱不可為空');

    // 改名 cascade 到訂單 campaignNames (限該使用者)；cascade 內會一併重新鏡像受影響訂單
    if (name !== existing.name) {
      await this.orders.cascadeRenameCampaign(uid, existing.name, name);
    }

    const row = await this.prisma.campaign.update({
      where: { id },
      data: {
        name,
        openDate: input.openDate ? new Date(input.openDate) : existing.openDate,
        closeDate:
          input.closeDate === undefined
            ? existing.closeDate
            : input.closeDate
              ? new Date(input.closeDate)
              : null,
        notes: input.notes ?? existing.notes,
      },
    });
    const dto = toDto(row);
    await this.mirror.upsert(uid, 'campaigns', dto.id, dto);
    return dto;
  }

  async remove(uid: string, id: string): Promise<void> {
    const count = await this.prisma.campaign.count({ where: { id, ownerUid: uid } });
    if (count === 0) throw new NotFoundException(`找不到開團 ${id}`);
    await this.prisma.campaign.delete({ where: { id } });
    await this.mirror.remove(uid, 'campaigns', id);
  }

  // 結團：紀錄結團日期、不改 status、不鎖訂單。已結團則維持原日期
  async settle(uid: string, id: string): Promise<Campaign> {
    const existing = await this.prisma.campaign.findFirst({ where: { id, ownerUid: uid } });
    if (!existing) throw new NotFoundException(`找不到開團 ${id}`);
    if (existing.settledDate) return toDto(existing);
    const row = await this.prisma.campaign.update({
      where: { id },
      data: { settledDate: this.now.now() },
    });
    const dto = toDto(row);
    await this.mirror.upsert(uid, 'campaigns', dto.id, dto);
    return dto;
  }

  async setStatus(uid: string, id: string, input: CampaignStatusInput): Promise<Campaign> {
    if (!input.status || !CAMPAIGN_STATUSES.includes(input.status)) {
      throw new BadRequestException('無效的開團狀態');
    }
    const count = await this.prisma.campaign.count({ where: { id, ownerUid: uid } });
    if (count === 0) throw new NotFoundException(`找不到開團 ${id}`);
    const row = await this.prisma.campaign.update({
      where: { id },
      data: { status: input.status },
    });
    const dto = toDto(row);
    await this.mirror.upsert(uid, 'campaigns', dto.id, dto);
    return dto;
  }

  // 結單日已過期的開團中團，自動轉為已收單 (用注入的現在時間)，僅限該使用者；
  // 自動收單的團一併重新鏡像，使 Firestore 投影同步狀態
  private async autoClose(uid: string): Promise<void> {
    const toClose = await this.prisma.campaign.findMany({
      where: { ownerUid: uid, status: 'ongoing', closeDate: { not: null, lt: this.now.now() } },
    });
    if (toClose.length === 0) return;
    await this.prisma.campaign.updateMany({
      where: { id: { in: toClose.map((c) => c.id) } },
      data: { status: 'closed' },
    });
    await Promise.all(
      toClose.map((c) => {
        const dto = toDto({ ...c, status: 'closed' });
        return this.mirror.upsert(uid, 'campaigns', dto.id, dto);
      }),
    );
  }
}

function toDto(row: CampaignRow): Campaign {
  return {
    id: row.id,
    name: row.name,
    openDate: row.openDate.toISOString(),
    closeDate: row.closeDate ? row.closeDate.toISOString() : null,
    status: row.status as Campaign['status'],
    settledDate: row.settledDate ? row.settledDate.toISOString() : null,
    notes: row.notes,
  };
}
