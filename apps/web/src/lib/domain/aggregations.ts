import type { Campaign, CustomerTier, OrderDTO } from '../types';
import { D, Decimal } from '../decimal';
import { ACTIVE_STATUSES, CATEGORY_TINTS, REALIZED_STATUSES } from './constants';
import { contributesToCategoryBreakdown, isLeaf } from './orders';

// MARK: - 開團結算

export interface DistributionRow {
  name: string;
  totalQuantity: number;
  totalAmount: string;
  isFullyReceived: boolean;
  orders: OrderDTO[];
}

export interface CampaignSummary {
  orderCount: number;
  totalItemQuantity: number;
  receivables: string;
  receivedAmount: string;
  outstandingAmount: string;
  receivedRatio: number;
  totalCost: string;
  totalRevenue: string;
  profit: string;
  margin: number;
  arrivedCount: number;
  activeCount: number;
  deliveryRatio: number;
  distribution: DistributionRow[];
}

// 開團結算：全由葉端成員訂單推導 (對齊 iOS CampaignSummary)。
export function campaignSummary(orders: OrderDTO[], campaignName: string): CampaignSummary {
  const members = orders.filter((o) => isLeaf(o) && o.campaignNames.includes(campaignName));

  let receivables = new Decimal(0);
  let receivedAmount = new Decimal(0);
  let totalCost = new Decimal(0);
  let totalRevenue = new Decimal(0);
  let profit = new Decimal(0);
  let totalItemQuantity = 0;
  let arrivedCount = 0;
  let activeCount = 0;

  for (const o of members) {
    receivables = receivables.plus(o.chargedAmount);
    if (o.paymentReceiptStatus === 'received') receivedAmount = receivedAmount.plus(o.chargedAmount);
    totalCost = totalCost.plus(o.summary.totalCost);
    totalRevenue = totalRevenue.plus(o.summary.revenue);
    profit = profit.plus(o.summary.profit);
    totalItemQuantity += o.items.reduce((acc, it) => acc + it.quantity, 0);
    if (o.status === 'arrived' || o.status === 'delivered') arrivedCount += 1;
    if (o.status !== 'cancelled' && o.status !== 'merged') activeCount += 1;
  }

  const outstanding = receivables.minus(receivedAmount);
  const receivedRatio = receivables.isZero() ? 0 : receivedAmount.div(receivables).toNumber();
  const margin = totalRevenue.isZero() ? 0 : profit.div(totalRevenue).toNumber();
  const deliveryRatio = activeCount === 0 ? 0 : arrivedCount / activeCount;

  return {
    orderCount: members.length,
    totalItemQuantity,
    receivables: receivables.toString(),
    receivedAmount: receivedAmount.toString(),
    outstandingAmount: outstanding.toString(),
    receivedRatio,
    totalCost: totalCost.toString(),
    totalRevenue: totalRevenue.toString(),
    profit: profit.toString(),
    margin,
    arrivedCount,
    activeCount,
    deliveryRatio,
    distribution: buildDistribution(members),
  };
}

// 客戶分貨：依 trim 後客戶名稱分組，全員已收款才算 fullyReceived。
function buildDistribution(members: OrderDTO[]): DistributionRow[] {
  const map = new Map<string, OrderDTO[]>();
  for (const o of members) {
    const key = o.customer.name.trim();
    const list = map.get(key) ?? [];
    list.push(o);
    map.set(key, list);
  }
  const rows: DistributionRow[] = [];
  for (const [name, list] of map) {
    let amount = new Decimal(0);
    let quantity = 0;
    for (const o of list) {
      amount = amount.plus(o.chargedAmount);
      quantity += o.items.reduce((acc, it) => acc + it.quantity, 0);
    }
    rows.push({
      name,
      totalQuantity: quantity,
      totalAmount: amount.toString(),
      isFullyReceived: list.every((o) => o.paymentReceiptStatus === 'received'),
      orders: list,
    });
  }
  return rows.sort((a, b) => D(b.totalAmount).comparedTo(D(a.totalAmount)));
}

// MARK: - 儀表板

export interface MonthTotals {
  revenue: string;
  cost: string;
  profit: string;
  margin: number;
}

export interface DashboardStats {
  hasOrders: boolean;
  current: MonthTotals;
  previous: MonthTotals;
  revenueDelta: number | null;
  costDelta: number | null;
  profitDelta: number | null;
  marginDelta: number | null;
  activeCount: number;
  sparkline: number[];
  goalProgress: number;
  recentOrders: OrderDTO[];
}

export function dashboardStats(orders: OrderDTO[], now: Date, monthlyGoal: string): DashboardStats {
  const current = monthTotals(orders, now.getFullYear(), now.getMonth());
  const prevDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const previous = monthTotals(orders, prevDate.getFullYear(), prevDate.getMonth());

  const activeCount = orders.filter((o) => ACTIVE_STATUSES.has(o.status)).length;

  const sparkline: number[] = [];
  for (let i = 11; i >= 0; i -= 1) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    sparkline.push(Number(monthTotals(orders, d.getFullYear(), d.getMonth()).profit));
  }

  const goal = D(monthlyGoal);
  const goalProgress = goal.lte(0)
    ? 0
    : clamp01(D(current.profit).div(goal).toNumber());

  return {
    hasOrders: orders.length > 0,
    current,
    previous,
    revenueDelta: ratioDelta(current.revenue, previous.revenue),
    costDelta: ratioDelta(current.cost, previous.cost),
    profitDelta: ratioDelta(current.profit, previous.profit),
    marginDelta: D(previous.revenue).isZero() ? null : current.margin - previous.margin,
    activeCount,
    sparkline,
    goalProgress,
    recentOrders: orders.slice(0, 4),
  };
}

function monthTotals(orders: OrderDTO[], year: number, month: number): MonthTotals {
  const start = new Date(year, month, 1).getTime();
  const end = new Date(year, month + 1, 1).getTime();
  let revenue = new Decimal(0);
  let cost = new Decimal(0);
  let profit = new Decimal(0);
  for (const o of orders) {
    if (!REALIZED_STATUSES.has(o.status)) continue;
    const t = new Date(o.date).getTime();
    if (t < start || t >= end) continue;
    revenue = revenue.plus(o.summary.revenue);
    cost = cost.plus(o.summary.totalCost);
    profit = profit.plus(o.summary.profit);
  }
  return {
    revenue: revenue.toString(),
    cost: cost.toString(),
    profit: profit.toString(),
    margin: revenue.isZero() ? 0 : profit.div(revenue).toNumber(),
  };
}

// MARK: - 分析

export type InsightsRange = 'thirtyDays' | 'sixMonths' | 'twelveMonths';

export interface RankRow {
  name: string;
  profit: string;
  profitNumber: number;
}

export interface TrendBar {
  label: string;
  value: number;
}

export interface CostSegment {
  label: string;
  value: number;
  color: string;
}

export interface InsightsStats {
  hasData: boolean;
  categoryBreakdown: RankRow[];
  costStructure: CostSegment[];
  campaignRanking: RankRow[];
  trendBars: TrendBar[];
  trendDelta: number | null;
  heatmap: number[][];
}

export function insightsStats(
  orders: OrderDTO[],
  campaigns: Campaign[],
  range: InsightsRange,
  now: Date,
): InsightsStats {
  const realized = orders.filter((o) => REALIZED_STATUSES.has(o.status));

  // 類別收益拆解：葉端 + (已實現或 merged)，多類別全額計入每個類別。
  const categoryMap = new Map<string, Decimal>();
  for (const o of orders) {
    if (!contributesToCategoryBreakdown(o)) continue;
    for (const raw of o.categories) {
      const name = raw.trim();
      if (!name) continue;
      categoryMap.set(name, (categoryMap.get(name) ?? new Decimal(0)).plus(o.summary.profit));
    }
  }
  const categoryBreakdown = [...categoryMap.entries()]
    .map(([name, profit]) => ({ name, profit: profit.toString(), profitNumber: profit.toNumber() }))
    .sort((a, b) => b.profitNumber - a.profitNumber);

  // 成本結構甜甜圈：原始 itemCost / 國內 / 國際 / 手續費。
  let itemCost = new Decimal(0);
  let domestic = new Decimal(0);
  let international = new Decimal(0);
  let fees = new Decimal(0);
  for (const o of realized) {
    itemCost = itemCost.plus(o.itemCost);
    domestic = domestic.plus(o.domesticShipping);
    international = international.plus(o.internationalShipping);
    fees = fees.plus(o.summary.fees);
  }
  const costStructure: CostSegment[] = [
    { label: '商品成本', value: itemCost.toNumber(), color: CATEGORY_TINTS[0] },
    { label: '國內運費', value: domestic.toNumber(), color: CATEGORY_TINTS[3] },
    { label: '國際運費', value: international.toNumber(), color: CATEGORY_TINTS[2] },
    { label: '手續費', value: fees.toNumber(), color: CATEGORY_TINTS[1] },
  ].filter((s) => s.value > 0);

  // 開團獲利排名：orderCount > 0，依獲利降冪。
  const campaignRanking: RankRow[] = campaigns
    .map((c) => {
      const summary = campaignSummary(orders, c.name);
      return { name: c.name, profit: summary.profit, profitNumber: Number(summary.profit), orderCount: summary.orderCount };
    })
    .filter((r) => r.orderCount > 0)
    .map(({ name, profit, profitNumber }) => ({ name, profit, profitNumber }))
    .sort((a, b) => b.profitNumber - a.profitNumber);

  const { bars, delta } = trend(realized, range, now);

  return {
    hasData: orders.length > 0,
    categoryBreakdown,
    costStructure,
    campaignRanking,
    trendBars: bars,
    trendDelta: delta,
    heatmap: buildHeatmap(orders, now),
  };
}

function trend(
  realized: OrderDTO[],
  range: InsightsRange,
  now: Date,
): { bars: TrendBar[]; delta: number | null } {
  const bars: TrendBar[] = [];
  let currentSum = new Decimal(0);
  let previousSum = new Decimal(0);

  if (range === 'thirtyDays') {
    for (let i = 29; i >= 0; i -= 1) {
      const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const next = new Date(day);
      next.setDate(next.getDate() + 1);
      const value = sumProfitInRange(realized, day.getTime(), next.getTime());
      bars.push({ label: `${day.getMonth() + 1}/${day.getDate()}`, value: value.toNumber() });
      currentSum = currentSum.plus(value);
    }
    for (let i = 59; i >= 30; i -= 1) {
      const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const next = new Date(day);
      next.setDate(next.getDate() + 1);
      previousSum = previousSum.plus(sumProfitInRange(realized, day.getTime(), next.getTime()));
    }
  } else {
    const months = range === 'sixMonths' ? 6 : 12;
    for (let i = months - 1; i >= 0; i -= 1) {
      const start = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 1);
      const value = sumProfitInRange(realized, start.getTime(), end.getTime());
      bars.push({ label: `${start.getMonth() + 1}月`, value: value.toNumber() });
      currentSum = currentSum.plus(value);
    }
    for (let i = months * 2 - 1; i >= months; i -= 1) {
      const start = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 1);
      previousSum = previousSum.plus(sumProfitInRange(realized, start.getTime(), end.getTime()));
    }
  }

  const delta = previousSum.isZero() ? null : currentSum.minus(previousSum).div(previousSum).toNumber();
  return { bars, delta };
}

function sumProfitInRange(orders: OrderDTO[], start: number, end: number): Decimal {
  let sum = new Decimal(0);
  for (const o of orders) {
    const t = new Date(o.date).getTime();
    if (t >= start && t < end) sum = sum.plus(o.summary.profit);
  }
  return sum;
}

// 8 週 × 7 天 (週一為始) 訂單數熱力圖。
function buildHeatmap(orders: OrderDTO[], now: Date): number[][] {
  const weeks = 8;
  const grid: number[][] = Array.from({ length: weeks }, () => Array.from({ length: 7 }, () => 0));
  const start = startOfWeekLocal(new Date(now.getFullYear(), now.getMonth(), now.getDate()));
  start.setDate(start.getDate() - (weeks - 1) * 7);
  const startTime = start.getTime();
  for (const o of orders) {
    const t = new Date(o.date).getTime();
    const dayIndex = Math.floor((t - startTime) / 86_400_000);
    if (dayIndex < 0 || dayIndex >= weeks * 7) continue;
    const week = Math.floor(dayIndex / 7);
    const day = dayIndex % 7;
    grid[week][day] += 1;
  }
  return grid;
}

function startOfWeekLocal(date: Date): Date {
  const d = new Date(date);
  const weekday = (d.getDay() + 6) % 7;
  d.setDate(d.getDate() - weekday);
  return d;
}

// MARK: - 客戶

export interface CustomerRow {
  name: string;
  initials: string;
  tier: CustomerTier;
  orderCount: number;
  totalSpent: string;
  totalSpentNumber: number;
  lastDate: string;
}

export function customerRollup(orders: OrderDTO[]): CustomerRow[] {
  const map = new Map<string, OrderDTO[]>();
  for (const o of orders) {
    const list = map.get(o.customer.name) ?? [];
    list.push(o);
    map.set(o.customer.name, list);
  }
  const rows: CustomerRow[] = [];
  for (const [name, list] of map) {
    let spent = new Decimal(0);
    let lastDate = list[0].date;
    for (const o of list) {
      spent = spent.plus(o.summary.revenue);
      if (new Date(o.date).getTime() > new Date(lastDate).getTime()) lastDate = o.date;
    }
    rows.push({
      name,
      initials: list[0].customer.initials,
      tier: list[0].customer.tier,
      orderCount: list.length,
      totalSpent: spent.toString(),
      totalSpentNumber: spent.toNumber(),
      lastDate,
    });
  }
  return rows.sort((a, b) => b.totalSpentNumber - a.totalSpentNumber);
}

// MARK: - 共用

function ratioDelta(current: string, previous: string): number | null {
  const prev = D(previous);
  if (prev.isZero()) return null;
  return D(current).minus(prev).div(prev).toNumber();
}

function clamp01(value: number): number {
  if (Number.isNaN(value)) return 0;
  return Math.max(0, Math.min(1, value));
}
