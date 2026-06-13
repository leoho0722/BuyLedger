import type {
  OrderStatus,
  CampaignStatus,
  PaymentReceiptStatus,
  CustomerTier,
} from '../types';

// 設計系統語意強度 (對齊 iOS BLTone)。
export type Tone = 'neutral' | 'accent' | 'success' | 'warning' | 'destructive' | 'informative';

// tone → 文字/背景/指示點 utility classes。非中性背景為前景色 14%。
export const TONE_CLASSES: Record<Tone, { text: string; bg: string; dot: string }> = {
  neutral: { text: 'text-bl-secondary-label', bg: 'bg-bl-fill-tertiary', dot: 'bg-bl-secondary-label' },
  accent: { text: 'text-bl-accent', bg: 'bg-bl-accent/14', dot: 'bg-bl-accent' },
  success: { text: 'text-bl-green', bg: 'bg-bl-green/14', dot: 'bg-bl-green' },
  warning: { text: 'text-bl-orange', bg: 'bg-bl-orange/14', dot: 'bg-bl-orange' },
  destructive: { text: 'text-bl-red', bg: 'bg-bl-red/14', dot: 'bg-bl-red' },
  informative: { text: 'text-bl-indigo', bg: 'bg-bl-indigo/14', dot: 'bg-bl-indigo' },
};

// 訂單狀態固定順序 (對齊生成型別)。
export const ORDER_STATUS_ORDER: OrderStatus[] = [
  'quoting',
  'confirmed',
  'purchased',
  'shipping',
  'partiallyArrived',
  'arrived',
  'delivered',
  'cancelled',
  'merged',
];

export const ORDER_STATUS_TITLE: Record<OrderStatus, string> = {
  quoting: '報價中',
  confirmed: '已確認',
  purchased: '已下單',
  shipping: '集運中',
  partiallyArrived: '部分到貨',
  arrived: '已到貨',
  delivered: '已交付',
  cancelled: '已取消',
  merged: '已合併',
};

export const ORDER_STATUS_TONE: Record<OrderStatus, Tone> = {
  quoting: 'informative',
  confirmed: 'accent',
  purchased: 'warning',
  shipping: 'informative',
  partiallyArrived: 'warning',
  arrived: 'accent',
  delivered: 'success',
  cancelled: 'destructive',
  merged: 'neutral',
};

// 已實現狀態 (收益統計唯一事實來源)：含 delivered，不含 quoting/cancelled/merged。
export const REALIZED_STATUSES: Set<OrderStatus> = new Set([
  'confirmed',
  'purchased',
  'shipping',
  'partiallyArrived',
  'arrived',
  'delivered',
]);

// 進行中訂單 (側欄紅點/儀表板計數)：排除 delivered。
export const ACTIVE_STATUSES: Set<OrderStatus> = new Set([
  'confirmed',
  'purchased',
  'shipping',
  'partiallyArrived',
  'arrived',
]);

// 類別/收益歸屬：已實現 allowlist 擴充 merged (合併狀態也計入類別拆解)。
export const CATEGORY_REALIZED_STATUSES: Set<OrderStatus> = new Set([
  ...REALIZED_STATUSES,
  'merged',
]);

// 智慧群組 (側欄快篩)：除 cancelled 外的所有狀態。
export const SMART_GROUP_STATUSES: OrderStatus[] = ORDER_STATUS_ORDER.filter(
  (s) => s !== 'cancelled',
);

export const CAMPAIGN_STATUS_TITLE: Record<CampaignStatus, string> = {
  ongoing: '開團中',
  closed: '已收單',
};

export const CAMPAIGN_STATUS_TONE: Record<CampaignStatus, Tone> = {
  ongoing: 'accent',
  closed: 'neutral',
};

export const RECEIPT_STATUS_TITLE: Record<PaymentReceiptStatus, string> = {
  pending: '待收款',
  received: '已收款',
};

export const CUSTOMER_TIER_TITLE: Record<CustomerTier, string> = {
  new: '新客',
  regular: '常客',
  vip: 'VIP',
};

// 圖表分類色序 (對齊 iOS categoryTints)。
export const CATEGORY_TINTS = [
  'var(--bl-accent)',
  'var(--bl-purple)',
  'var(--bl-orange)',
  'var(--bl-teal)',
  'var(--bl-pink)',
];

// 預設值。
export const DEFAULT_MONTHLY_PROFIT_GOAL = '80000';
export const MAX_PHOTO_COUNT = 5;
export const FX_QUICK_AMOUNTS = [10_000, 50_000, 100_000, 500_000];
