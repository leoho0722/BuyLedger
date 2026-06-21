import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
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
    const rows = await this.prisma.order.findMany({
      where: { ownerUid: uid },
      orderBy: { date: 'desc' },
    });
    return rows.map(rowToDto);
  }

  async get(uid: string, id: string): Promise<OrderDTO> {
    const row = await this.prisma.order.findFirst({ where: { id, ownerUid: uid } });
    if (!row) throw new NotFoundException(`找不到訂單 ${id}`);
    return rowToDto(row);
  }

  async create(uid: string, input: OrderInput): Promise<OrderDTO> {
    const domain = await this.normalize(uid, input, { isNew: true });
    const data = this.toPrismaData(domain, uid);

    // 合併產生的訂單：單一交易內插入新訂單並將來源訂單設為 merged (原子性)。
    // 來源訂單一律限縮在呼叫者自己的資料。
    if (domain.mergedSourceIDs.length > 0) {
      const [created] = await this.prisma.$transaction([
        this.prisma.order.create({ data }),
        this.prisma.order.updateMany({
          where: { id: { in: domain.mergedSourceIDs }, ownerUid: uid },
          data: { status: 'merged' },
        }),
      ]);
      const dto = rowToDto(created);
      await this.mirror.mirrorOrder(uid, dto);
      // 來源訂單狀態改為 merged，一併重新鏡像。
      await this.remirrorOrders(uid, domain.mergedSourceIDs);
      return dto;
    }

    const created = await this.prisma.order.create({ data });
    const dto = rowToDto(created);
    await this.mirror.mirrorOrder(uid, dto);
    return dto;
  }

  async update(uid: string, id: string, input: OrderInput): Promise<OrderDTO> {
    await this.ensureExists(uid, id);
    const domain = await this.normalize(uid, { ...input, id }, { isNew: false });
    const data = this.toPrismaData(domain, uid);
    const updated = await this.prisma.order.update({ where: { id }, data });
    const dto = rowToDto(updated);
    await this.mirror.mirrorOrder(uid, dto);
    return dto;
  }

  // 欄位級合併寫入 (對齊 sync-conflict-resolution「Field-level merge with strict-greater
  // clock acceptance」)：以每欄位 HLC 逐欄合併 incoming partial patch——不同欄位各自存活、
  // 同欄位由時鐘決勝；重送相同 patch 為 no-op。回傳合併後 DTO 與每個被 patch 欄位的權威
  // 時鐘 (appliedFieldClocks)，供 client 對帳清 dirty。對完整合併列重跑 normalize 以重算
  // isCashOnDelivery 等衍生欄位並 clamp。
  async patch(
    uid: string,
    id: string,
    input: OrderPatchInput,
  ): Promise<{ order: OrderDTO; appliedFieldClocks: Record<string, string> }> {
    const changedFields = input.changedFields ?? {};
    const fieldClocks = input.fieldClocks ?? {};
    const fields = Object.keys(changedFields);

    // 偏移守門 + 推進伺服器 HLC (合併前必跑)：缺欄位時鐘即 400、未來時鐘超容忍即 400。
    for (const field of fields) {
      const enc = fieldClocks[field];
      if (!enc) throw new BadRequestException(`欄位 ${field} 缺少時鐘`);
      const clock = this.hlc.decode(enc);
      this.hlc.assertWithinTolerance(clock);
      this.hlc.receive(clock);
    }

    const existing = await this.prisma.order.findFirst({ where: { id, ownerUid: uid } });

    if (fields.length === 0) {
      if (!existing) throw new BadRequestException('空白 patch 無法建立訂單');
      return { order: rowToDto(existing), appliedFieldClocks: {} };
    }

    const storedValues: FieldMap = existing ? orderDomainToFlat(rowToDomain(existing)) : {};
    const storedClocks: ClockMap = (existing?.fieldClocks as ClockMap | null) ?? {};
    const merged = mergeFieldWrites(storedValues, storedClocks, { changedFields, fieldClocks });

    // 跨使用者碰撞守門 (client UUID 理論上不撞；防覆蓋他人資料、且不洩漏存在性)。
    if (!existing) {
      const collision = await this.prisma.order.findUnique({
        where: { id },
        select: { ownerUid: true },
      });
      if (collision && collision.ownerUid !== uid) {
        throw new NotFoundException(`找不到訂單 ${id}`);
      }
    }

    const domain = await this.normalize(uid, orderFlatToInput(merged.values, id), {
      isNew: false,
    });
    const data: Prisma.OrderUncheckedCreateInput = {
      ...this.toPrismaData(domain, uid),
      fieldClocks: merged.clocks as Prisma.InputJsonValue,
    };
    const saved = await this.prisma.order.upsert({
      where: { id },
      create: data,
      update: data,
    });

    const dto = rowToDto(saved);
    await this.mirror.mirrorOrder(uid, dto, { fieldClocks: merged.clocks });
    return { order: dto, appliedFieldClocks: merged.appliedClocks };
  }

  async remove(uid: string, id: string): Promise<void> {
    await this.ensureExists(uid, id);
    await this.prisma.order.delete({ where: { id } });
    await this.mirror.remove(uid, 'orders', id);
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
    await this.mirror.mirrorOrder(uid, dto);
    return dto;
  }

  // 批次更改狀態：以單一 updateMany 依 ownerUid 圈更新已選訂單，更新後重新鏡像受影響訂單。
  // 不屬呼叫者的 id 一律不受影響也不報錯；merged 為終態僅由合併流程寫入，端點層拒絕。
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

    // 查回實際受影響 (屬該使用者) 的訂單，逐筆 remirror 並回傳更新後 DTO。
    const rows = await this.prisma.order.findMany({
      where: { id: { in: ids }, ownerUid: uid },
    });
    await Promise.all(rows.map((row) => this.mirror.mirrorOrder(uid, rowToDto(row))));
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
    await this.mirror.mirrorOrder(uid, dto);
    return dto;
  }

  // 合併草稿：取兩筆訂單算出合併欄位 (含加權費率)，照片是否超量交由前端挑選步驟處理。
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

  // 主檔改名時 cascade 到訂單 (純量欄位 updateMany)，僅限該使用者的訂單。
  async cascadeRenameScalar(
    uid: string,
    field: 'orderSource' | 'paymentMethod' | 'verificationStatus',
    oldName: string,
    newName: string,
  ): Promise<void> {
    if (oldName === newName) return;
    await this.prisma.order.updateMany({
      where: { [field]: oldName, ownerUid: uid },
      data: { [field]: newName },
    });
    const affected = await this.prisma.order.findMany({
      where: { [field]: newName, ownerUid: uid },
      select: { id: true },
    });
    await this.remirrorOrders(uid, affected.map((r) => r.id));
  }

  // 類別改名 cascade：逐筆把 categories 陣列內 old→new 取代並去重。
  async cascadeRenameCategory(uid: string, oldName: string, newName: string): Promise<void> {
    await this.cascadeRenameArray(uid, 'categories', oldName, newName);
  }

  // 開團改名 cascade：逐筆把 campaignNames 陣列內 old→new 取代並去重。
  async cascadeRenameCampaign(uid: string, oldName: string, newName: string): Promise<void> {
    await this.cascadeRenameArray(uid, 'campaignNames', oldName, newName);
  }

  private async cascadeRenameArray(
    uid: string,
    field: 'categories' | 'campaignNames',
    oldName: string,
    newName: string,
  ): Promise<void> {
    if (oldName === newName) return;
    const rows = await this.prisma.order.findMany({
      where: { [field]: { has: oldName }, ownerUid: uid },
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
    await this.remirrorOrders(uid, rows.map((r) => r.id));
  }

  // MARK: - 私有

  // 重新鏡像一組訂單 (cascade 改名或合併後欄位變動)。
  private async remirrorOrders(uid: string, ids: string[]): Promise<void> {
    if (ids.length === 0) return;
    const rows = await this.prisma.order.findMany({ where: { id: { in: ids }, ownerUid: uid } });
    await Promise.all(rows.map((row) => this.mirror.mirrorOrder(uid, rowToDto(row))));
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

  // 正規化前端草稿 (對齊 iOS applyEditDraft)：clamp 金額/費率、依付款方式旗標清欄位、補 fallback。
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

// 領域訂單 → 可合併的 flat 欄位圖：攤平 customer；排除 id、mergedSourceIDs (建立後唯讀) 與
// 衍生的 isCashOnDelivery (交由 normalize 依付款方式重算、不參與合併)。
function orderDomainToFlat(o: LedgerOrder): FieldMap {
  return {
    customerName: o.customer.name,
    customerInitials: o.customer.initials,
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

// flat 欄位圖 → OrderInput (供 normalize)；缺欄位帶 undefined 由 normalize 補預設與 clamp。
function orderFlatToInput(flat: FieldMap, id: string): OrderInput {
  const str = (v: unknown): string | undefined => (v === undefined ? undefined : String(v));
  return {
    id,
    customer: {
      name: str(flat.customerName),
      initials: str(flat.customerInitials),
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
