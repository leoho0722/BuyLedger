import type {
  OrderStatus,
  CampaignStatus,
  PaymentReceiptStatus,
  CustomerTier,
} from '../data-model';

// 列舉合法值 (寫入驗證用)，順序對齊生成型別。
export const ORDER_STATUSES: OrderStatus[] = [
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

export const CAMPAIGN_STATUSES: CampaignStatus[] = ['ongoing', 'closed'];

export const RECEIPT_STATUSES: PaymentReceiptStatus[] = ['pending', 'received'];

export const CUSTOMER_TIERS: CustomerTier[] = ['new', 'regular', 'vip'];

// 訂單照片張數上限。
export const MAX_PHOTO_COUNT = 5;

// 幣別清單快取 TTL：7 天 (秒)。
export const CURRENCY_CACHE_TTL_SECONDS = 604_800;

// 預設幣別與預載 fallback 清單 (僅 metadata 尚未載入時用)。
export const DEFAULT_CURRENCY = 'TWD';
export const DEFAULT_CURRENCY_CODES = ['TWD', 'KRW', 'JPY', 'USD', 'CNY'];

// AI 總結預設模型與候選清單。
export const DEFAULT_AI_MODEL = 'gemma4:31b-cloud';
export const AI_MODEL_CANDIDATES = ['gemma4:31b-cloud', 'gpt-oss:120b-cloud'];

// 預設每月獲利目標 (TWD)。
export const DEFAULT_MONTHLY_PROFIT_GOAL = '80000';
