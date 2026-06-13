import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Campaign as CampaignRow } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
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
  ) {}

  async list(): Promise<Campaign[]> {
    await this.autoClose();
    const rows = await this.prisma.campaign.findMany({
      orderBy: { openDate: 'desc' },
    });
    return rows.map(toDto);
  }

  async get(id: string): Promise<Campaign> {
    await this.autoClose();
    const row = await this.prisma.campaign.findUnique({ where: { id } });
    if (!row) throw new NotFoundException(`找不到開團 ${id}`);
    return toDto(row);
  }

  async create(input: CampaignInput): Promise<Campaign> {
    const name = (input.name ?? '').trim();
    if (!name) throw new BadRequestException('開團名稱不可為空');
    const row = await this.prisma.campaign.create({
      data: {
        id: this.ids.uuid(),
        name,
        openDate: input.openDate ? new Date(input.openDate) : this.now.now(),
        closeDate: input.closeDate ? new Date(input.closeDate) : null,
        status: 'ongoing',
        settledDate: null,
        notes: input.notes ?? '',
      },
    });
    return toDto(row);
  }

  async update(id: string, input: CampaignInput): Promise<Campaign> {
    const existing = await this.prisma.campaign.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException(`找不到開團 ${id}`);

    const name = input.name !== undefined ? (input.name ?? '').trim() : existing.name;
    if (!name) throw new BadRequestException('開團名稱不可為空');

    // 改名 cascade 到訂單 campaignNames。
    if (name !== existing.name) {
      await this.orders.cascadeRenameCampaign(existing.name, name);
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
    return toDto(row);
  }

  async remove(id: string): Promise<void> {
    const count = await this.prisma.campaign.count({ where: { id } });
    if (count === 0) throw new NotFoundException(`找不到開團 ${id}`);
    await this.prisma.campaign.delete({ where: { id } });
  }

  // 結團：紀錄結團日期、不改 status、不鎖訂單。已結團則維持原日期。
  async settle(id: string): Promise<Campaign> {
    const existing = await this.prisma.campaign.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException(`找不到開團 ${id}`);
    if (existing.settledDate) return toDto(existing);
    const row = await this.prisma.campaign.update({
      where: { id },
      data: { settledDate: this.now.now() },
    });
    return toDto(row);
  }

  async setStatus(id: string, input: CampaignStatusInput): Promise<Campaign> {
    if (!input.status || !CAMPAIGN_STATUSES.includes(input.status)) {
      throw new BadRequestException('無效的開團狀態');
    }
    const count = await this.prisma.campaign.count({ where: { id } });
    if (count === 0) throw new NotFoundException(`找不到開團 ${id}`);
    const row = await this.prisma.campaign.update({
      where: { id },
      data: { status: input.status },
    });
    return toDto(row);
  }

  // 結單日已過期的開團中團，自動轉為已收單 (用注入的現在時間)。
  private async autoClose(): Promise<void> {
    await this.prisma.campaign.updateMany({
      where: { status: 'ongoing', closeDate: { not: null, lt: this.now.now() } },
      data: { status: 'closed' },
    });
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
