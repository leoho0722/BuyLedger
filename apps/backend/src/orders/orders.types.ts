import type { LedgerOrder, LedgerOrderItem } from '../data-model';

// 前端送入的訂單草稿 (decimal 欄位皆字串)
// isCashOnDelivery 由後端依付款方式主檔推導、不信任前端
export interface OrderInput {
  id?: string;
  customer?: {
    name?: string;
    initials?: string;
    tier?: LedgerOrder['customer']['tier'];
  };
  status?: LedgerOrder['status'];
  currency?: string;
  date?: string;
  items?: Array<Partial<LedgerOrderItem>>;
  itemCost?: string;
  domesticShipping?: string;
  internationalShipping?: string;
  foreignDomesticShipping?: string;
  cardFeeRate?: string;
  platformFeeRate?: string;
  paymentFeeRate?: string;
  chargedAmount?: string;
  cardlessDeductionAmount?: string;
  cardlessSupplementAmount?: string;
  orderSource?: string;
  categories?: string[];
  paymentMethod?: string;
  notes?: string;
  verificationStatus?: string;
  campaignNames?: string[];
  paymentReceiptStatus?: LedgerOrder['paymentReceiptStatus'];
  photos?: string[];
  mergedSourceIDs?: string[];
}

export interface StatusChangeInput {
  status?: LedgerOrder['status'];
}

// 批次更改狀態：一組訂單 id 套用同一目標狀態
// 用 TS interface 規避 ValidationPipe whitelist 剝除，service 內手動正規化
export interface BatchStatusChangeInput {
  ids?: string[];
  status?: LedgerOrder['status'];
}

export interface ReceiptChangeInput {
  status?: LedgerOrder['paymentReceiptStatus'];
}

export interface MergeDraftInput {
  primaryId?: string;
  secondaryId?: string;
}

// 欄位級合併寫入：client 送變更欄位 + 每欄位 HLC (decimal 欄位仍字串)，可選帶刪除 tombstone
// 同 BatchStatusChangeInput 用 interface 規避 whitelist
export interface OrderPatchInput {
  changedFields?: Record<string, unknown>;
  fieldClocks?: Record<string, string>;
  // 帶時鐘的刪除 tombstone：與 changedFields 的復活競態以 p→c→w 比較器決勝
  delete?: { clock: string };
}
