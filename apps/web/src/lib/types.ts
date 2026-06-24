// 生成型別彙整 + 後端 DTO 形狀 (與 apps/backend 對齊)
export type { Campaign } from './data-model/generated/Campaign';
export type { CampaignStatus } from './data-model/generated/CampaignStatus';
export type { CurrencyCode } from './data-model/generated/CurrencyCode';
export type { CustomerTier } from './data-model/generated/CustomerTier';
export type { FxRateSnapshot } from './data-model/generated/FxRateSnapshot';
export type { LedgerCustomer } from './data-model/generated/LedgerCustomer';
export type { LedgerOrder } from './data-model/generated/LedgerOrder';
export type { LedgerOrderItem } from './data-model/generated/LedgerOrderItem';
export type { Money } from './data-model/generated/Money';
export type { OrderStatus } from './data-model/generated/OrderStatus';
export type { PaymentMethodInfo } from './data-model/generated/PaymentMethodInfo';
export type { PaymentReceiptStatus } from './data-model/generated/PaymentReceiptStatus';

import type { LedgerOrder } from './data-model/generated/LedgerOrder';
import type { LedgerCustomer } from './data-model/generated/LedgerCustomer';
import type { OrderStatus } from './data-model/generated/OrderStatus';
import type { PaymentReceiptStatus } from './data-model/generated/PaymentReceiptStatus';

// 後端算好的財務摘要 (字串金額)
export interface OrderSummaryDTO {
  revenue: string;
  cardFee: string;
  platformFee: string;
  paymentFee: string;
  fees: string;
  totalCost: string;
  codShippingCost: string;
  profit: string;
  margin: string;
}

// 訂單 DTO = 生成型別 + 摘要
export type OrderDTO = LedgerOrder & { summary: OrderSummaryDTO };

export interface PaymentMethodDTO {
  name: string;
  isCardless: boolean;
  isBankTransfer: boolean;
  isCashOnDelivery: boolean;
}

export interface FxSnapshotDTO {
  date: string;
  base: string;
  rates: Record<string, string>;
}

export interface SettingsDTO {
  appearance: 'system' | 'light' | 'dark';
  notifications: boolean;
  useAiSummary: boolean;
  aiSummaryModel: string;
  defaultCurrency: string;
  monthlyProfitGoal: string;
  aiModelCandidates: string[];
}

// 合併草稿 (對齊後端 MergeDraft)
export interface MergeDraftDTO {
  customer: LedgerCustomer;
  orderSource: string;
  status: OrderStatus;
  currency: string;
  date: string;
  categories: string[];
  campaignNames: string[];
  paymentMethod: string;
  verificationStatus: string;
  isCashOnDelivery: boolean;
  paymentReceiptStatus: PaymentReceiptStatus;
  chargedAmount: string;
  cardlessDeductionAmount: string;
  cardlessSupplementAmount: string;
  itemCost: string;
  foreignDomesticShipping: string;
  internationalShipping: string;
  domesticShipping: string;
  cardFeeRate: string;
  platformFeeRate: string;
  paymentFeeRate: string;
  items: LedgerOrder['items'];
  notes: string;
  photos: string[];
  mergeSourceIDs: string[];
}

export interface MergeDraftResponse {
  draft: MergeDraftDTO;
  photosOverLimit: boolean;
  combinedPhotoCount: number;
  maxPhotoCount: number;
}
