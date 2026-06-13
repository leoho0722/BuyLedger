import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { IdService, NowService } from '../common/now.service';
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
  MergeDraftInput,
  OrderInput,
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
  ) {}

  async list(): Promise<OrderDTO[]> {
    const rows = await this.prisma.order.findMany({ orderBy: { date: 'desc' } });
    return rows.map(rowToDto);
  }

  async get(id: string): Promise<OrderDTO> {
    const row = await this.prisma.order.findUnique({ where: { id } });
    if (!row) throw new NotFoundException(`找不到訂單 ${id}`);
    return rowToDto(row);
  }

  async create(input: OrderInput): Promise<OrderDTO> {
    const domain = await this.normalize(input, { isNew: true });
    const data = this.toPrismaData(domain);

    // 合併產生的訂單：單一交易內插入新訂單並將來源訂單設為 merged (原子性)。
    if (domain.mergedSourceIDs.length > 0) {
      const [created] = await this.prisma.$transaction([
        this.prisma.order.create({ data }),
        this.prisma.order.updateMany({
          where: { id: { in: domain.mergedSourceIDs } },
          data: { status: 'merged' },
        }),
      ]);
      return rowToDto(created);
    }

    const created = await this.prisma.order.create({ data });
    return rowToDto(created);
  }

  async update(id: string, input: OrderInput): Promise<OrderDTO> {
    await this.ensureExists(id);
    const domain = await this.normalize({ ...input, id }, { isNew: false });
    const data = this.toPrismaData(domain);
    const updated = await this.prisma.order.update({ where: { id }, data });
    return rowToDto(updated);
  }

  async remove(id: string): Promise<void> {
    await this.ensureExists(id);
    await this.prisma.order.delete({ where: { id } });
  }

  async setStatus(id: string, input: StatusChangeInput): Promise<OrderDTO> {
    const status = this.validStatus(input.status);
    if (!status) throw new BadRequestException('無效的訂單狀態');
    await this.ensureExists(id);
    const updated = await this.prisma.order.update({
      where: { id },
      data: { status },
    });
    return rowToDto(updated);
  }

  async setReceipt(id: string, input: ReceiptChangeInput): Promise<OrderDTO> {
    if (!input.status || !RECEIPT_STATUSES.includes(input.status)) {
      throw new BadRequestException('無效的收款狀態');
    }
    await this.ensureExists(id);
    const updated = await this.prisma.order.update({
      where: { id },
      data: { paymentReceiptStatus: input.status },
    });
    return rowToDto(updated);
  }

  // 合併草稿：取兩筆訂單算出合併欄位 (含加權費率)，照片是否超量交由前端挑選步驟處理。
  async mergeDraft(input: MergeDraftInput): Promise<{
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
      this.prisma.order.findUnique({ where: { id: input.primaryId } }),
      this.prisma.order.findUnique({ where: { id: input.secondaryId } }),
    ]);
    if (!primaryRow || !secondaryRow) throw new NotFoundException('找不到訂單');

    const primary = rowToDomain(primaryRow);
    const secondary = rowToDomain(secondaryRow);

    // 合併資格：同幣別、同客戶名稱、雙方狀態皆非 merged/cancelled。
    const blocked = new Set(['merged', 'cancelled']);
    if (
      primary.currency !== secondary.currency ||
      primary.customer.name !== secondary.customer.name ||
      blocked.has(primary.status) ||
      blocked.has(secondary.status)
    ) {
      throw new BadRequestException('兩筆訂單不符合併資格');
    }

    const cardlessNames = await this.cardlessNameSet();
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

  // 主檔改名時 cascade 到訂單 (純量欄位 updateMany)。
  async cascadeRenameScalar(
    field: 'orderSource' | 'paymentMethod' | 'verificationStatus',
    oldName: string,
    newName: string,
  ): Promise<void> {
    if (oldName === newName) return;
    await this.prisma.order.updateMany({
      where: { [field]: oldName },
      data: { [field]: newName },
    });
  }

  // 類別改名 cascade：逐筆把 categories 陣列內 old→new 取代並去重。
  async cascadeRenameCategory(oldName: string, newName: string): Promise<void> {
    await this.cascadeRenameArray('categories', oldName, newName);
  }

  // 開團改名 cascade：逐筆把 campaignNames 陣列內 old→new 取代並去重。
  async cascadeRenameCampaign(oldName: string, newName: string): Promise<void> {
    await this.cascadeRenameArray('campaignNames', oldName, newName);
  }

  private async cascadeRenameArray(
    field: 'categories' | 'campaignNames',
    oldName: string,
    newName: string,
  ): Promise<void> {
    if (oldName === newName) return;
    const rows = await this.prisma.order.findMany({
      where: { [field]: { has: oldName } },
      select: { id: true, categories: true, campaignNames: true },
    });
    await this.prisma.$transaction(
      rows.map((row) => {
        const current = field === 'categories' ? row.categories : row.campaignNames;
        const replaced = uniquePreserve(current.map((v) => (v === oldName ? newName : v)));
        return this.prisma.order.update({
          where: { id: row.id },
          data: { [field]: replaced },
        });
      }),
    );
  }

  // MARK: - 私有

  private async ensureExists(id: string): Promise<void> {
    const count = await this.prisma.order.count({ where: { id } });
    if (count === 0) throw new NotFoundException(`找不到訂單 ${id}`);
  }

  private async resolvePaymentFlags(name: string): Promise<PaymentFlags> {
    if (!name) return { isCardless: false, isBankTransfer: false, isCashOnDelivery: false };
    const pm = await this.prisma.paymentMethod.findUnique({ where: { name } });
    return {
      isCardless: pm?.isCardless ?? false,
      isBankTransfer: pm?.isBankTransfer ?? false,
      isCashOnDelivery: pm?.isCashOnDelivery ?? false,
    };
  }

  private async cardlessNameSet(): Promise<Set<string>> {
    const methods = await this.prisma.paymentMethod.findMany({
      where: { isCardless: true },
      select: { name: true },
    });
    return new Set(methods.map((m) => m.name));
  }

  // 正規化前端草稿 (對齊 iOS applyEditDraft)：clamp 金額/費率、依付款方式旗標清欄位、補 fallback。
  private async normalize(
    input: OrderInput,
    opts: { isNew: boolean },
  ): Promise<LedgerOrder> {
    const paymentMethod = (input.paymentMethod ?? '').trim();
    const flags = await this.resolvePaymentFlags(paymentMethod);

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
      id: opts.isNew ? this.ids.newOrderId() : (input.id as string),
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

  private toPrismaData(o: LedgerOrder): Prisma.OrderUncheckedCreateInput {
    return {
      id: o.id,
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

// 金額 clamp 至 >= 0；空值視為 0。
function clampMin0(value: string | undefined): string {
  return Decimal.max(0, D(value)).toString();
}

// 費率 clamp 至 [0, 1]。
function clampRate(value: string | undefined): string {
  return Decimal.max(0, Decimal.min(1, D(value))).toString();
}

// 去重並保序 (cascade 改名後可能產生重複元素)。
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

// 由客戶名稱推導縮寫：多詞取前兩詞首字母；單詞拉丁取前兩字母、CJK 取首字。
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
