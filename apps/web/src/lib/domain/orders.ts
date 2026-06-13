import type { CampaignStatus, OrderDTO, OrderStatus } from '../types';
import { REALIZED_STATUSES } from './constants';

export type DatePeriod = 'all' | 'thisWeek' | 'thisMonth' | 'lastMonth';
export type StatusFilter = OrderStatus | 'all';
export type CampaignStatusFilter = 'all' | CampaignStatus;

export const DATE_PERIOD_TITLE: Record<DatePeriod, string> = {
  all: '全部',
  thisWeek: '本週',
  thisMonth: '本月',
  lastMonth: '上月',
};

// 葉端訂單 (非合併產生)；合併歸屬統計只看葉端。
export function isLeaf(o: OrderDTO): boolean {
  return o.mergedSourceIDs.length === 0;
}

export function isMergeResult(o: OrderDTO): boolean {
  return o.mergedSourceIDs.length > 0;
}

// 是否計入類別/收益拆解：葉端且 (已實現 或 merged)。
export function contributesToCategoryBreakdown(o: OrderDTO): boolean {
  return isLeaf(o) && (REALIZED_STATUSES.has(o.status) || o.status === 'merged');
}

// 是否可作為合併候選 (狀態非 merged/cancelled)。
export function isMergeable(o: OrderDTO): boolean {
  return o.status !== 'merged' && o.status !== 'cancelled';
}

// 合併候選資格：非自身、可合併、同幣別、同客戶名稱。
export function eligibleForMerge(primary: OrderDTO, candidate: OrderDTO): boolean {
  return (
    candidate.id !== primary.id &&
    isMergeable(candidate) &&
    candidate.currency === primary.currency &&
    candidate.customer.name === primary.customer.name
  );
}

// 商品明細摘要 (列表第二行)：逐項列名稱與數量。
export function orderItemSummary(o: OrderDTO): string {
  if (o.items.length === 0) return '無商品明細';
  return o.items.map((it) => `${it.name.trim() || '未命名商品'} ×${it.quantity}`).join('、');
}

// 類別第三行：去空白去重後以「、」串接 (全空則不顯示，回傳空字串)。
export function orderCategoryTag(o: OrderDTO): string {
  const names = o.categories.map((c) => c.trim()).filter(Boolean);
  return names.join('、');
}

export interface OrderFilters {
  search: string;
  status: StatusFilter;
  datePeriod: DatePeriod;
  category: string | null;
  paymentMethod: string | null;
  campaign: string | null;
  campaignStatus: CampaignStatusFilter;
}

export const DEFAULT_FILTERS: OrderFilters = {
  search: '',
  status: 'all',
  datePeriod: 'all',
  category: null,
  paymentMethod: null,
  campaign: null,
  campaignStatus: 'all',
};

interface FilterContext {
  now: Date;
  campaignStatusByName: Record<string, CampaignStatus>;
}

// 篩選訂單 (所有條件取交集，對齊 iOS filteredOrders)。輸入已依日期降冪排序。
export function filterOrders(
  orders: OrderDTO[],
  filters: OrderFilters,
  ctx: FilterContext,
): OrderDTO[] {
  const query = filters.search.trim().toLowerCase();
  const interval = periodInterval(filters.datePeriod, ctx.now);

  return orders.filter((o) => {
    if (filters.status !== 'all' && o.status !== filters.status) return false;

    if (query) {
      const hay = [
        o.customer.name,
        o.orderSource,
        o.notes,
        ...o.items.map((it) => it.name),
        ...o.categories,
      ]
        .join(' ')
        .toLowerCase();
      if (!hay.includes(query)) return false;
    }

    if (interval) {
      const t = new Date(o.date).getTime();
      if (t < interval.start || t >= interval.end) return false;
    }

    if (filters.category && !o.categories.includes(filters.category)) return false;
    if (filters.paymentMethod && o.paymentMethod !== filters.paymentMethod) return false;
    if (filters.campaign && !o.campaignNames.includes(filters.campaign)) return false;

    if (filters.campaignStatus !== 'all') {
      const matched = o.campaignNames.some(
        (name) => ctx.campaignStatusByName[name] === filters.campaignStatus,
      );
      if (!matched) return false;
    }

    return true;
  });
}

// 日期區間 (半開區間 [start, end))；all 回傳 null。
export function periodInterval(period: DatePeriod, now: Date): { start: number; end: number } | null {
  if (period === 'all') return null;
  if (period === 'thisWeek') {
    const start = startOfWeek(now);
    const end = new Date(start);
    end.setDate(end.getDate() + 7);
    return { start: start.getTime(), end: end.getTime() };
  }
  if (period === 'thisMonth') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    return { start: start.getTime(), end: end.getTime() };
  }
  // lastMonth
  const start = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const end = new Date(now.getFullYear(), now.getMonth(), 1);
  return { start: start.getTime(), end: end.getTime() };
}

// 週一為一週之始 (對齊 iOS firstWeekday = 2)。
export function startOfWeek(date: Date): Date {
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const weekday = (d.getDay() + 6) % 7; // 0 = Monday
  d.setDate(d.getDate() - weekday);
  return d;
}

// 依「日」分組訂單 (列表分段)。
export interface OrderDateSection {
  key: string;
  date: string;
  orders: OrderDTO[];
}

export function groupOrdersByDay(orders: OrderDTO[]): OrderDateSection[] {
  const map = new Map<string, OrderDateSection>();
  for (const o of orders) {
    const d = new Date(o.date);
    const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
    let section = map.get(key);
    if (!section) {
      section = { key, date: o.date, orders: [] };
      map.set(key, section);
    }
    section.orders.push(o);
  }
  return [...map.values()];
}
