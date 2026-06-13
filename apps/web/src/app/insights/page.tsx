'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { BarChart3, TrendingDown, TrendingUp } from 'lucide-react';
import { PageHeader } from '@/components/PageHeader';
import { BLCard } from '@/components/ds/BLCard';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { BLSegmentedControl } from '@/components/ds/BLSegmentedControl';
import { BLBarChart } from '@/components/ds/BLBarChart';
import { BLDonutChart } from '@/components/ds/BLDonutChart';
import { BLHeatmap } from '@/components/ds/BLHeatmap';
import { EmptyState } from '@/components/ds/EmptyState';
import { useCampaigns, useOrders } from '@/lib/queries';
import { insightsStats, type InsightsRange, type RankRow } from '@/lib/domain/aggregations';
import { formatPercent, formatTWD } from '@/lib/format';

// 走勢區段標題依區間動態顯示「{區間}淨獲利」(對齊 iOS)。
const TREND_TITLE: Record<InsightsRange, string> = {
  thirtyDays: '30 天淨獲利',
  sixMonths: '6 個月淨獲利',
  twelveMonths: '12 個月淨獲利',
};

// 排名水平 bar：依絕對值佔最大值的比例決定寬度，正值 accent、負值 red。
function RankList({ rows, onSelect }: { rows: RankRow[]; onSelect: (name: string) => void }) {
  const max = Math.max(1, ...rows.map((r) => Math.abs(r.profitNumber)));
  return (
    <div className="space-y-2.5">
      {rows.map((row) => {
        const width = `${(Math.abs(row.profitNumber) / max) * 100}%`;
        const negative = row.profitNumber < 0;
        return (
          <button
            key={row.name}
            type="button"
            onClick={() => onSelect(row.name)}
            className="flex w-full items-center gap-3 text-left"
          >
            <span className="w-20 shrink-0 truncate text-[15px] text-bl-label">{row.name}</span>
            <span className="h-2 flex-1 overflow-hidden rounded-bl-pill bg-bl-fill-quaternary">
              <span
                className={negative ? 'block h-full bg-bl-red' : 'block h-full bg-bl-accent'}
                style={{ width }}
              />
            </span>
            <span className="w-24 shrink-0 text-right text-[15px] text-bl-secondary-label bl-tabular">
              {formatTWD(row.profit)}
            </span>
          </button>
        );
      })}
    </div>
  );
}

export default function InsightsPage() {
  const router = useRouter();
  const { data: orders, isLoading } = useOrders();
  const { data: campaigns } = useCampaigns();
  const now = new Date();
  const [range, setRange] = useState<InsightsRange>('twelveMonths');

  const stats = insightsStats(orders ?? [], campaigns ?? [], range, now);

  // 成本結構總和：用於甜甜圈中央值。
  const costTotal = stats.costStructure.reduce((acc, s) => acc + s.value, 0);

  return (
    <div>
      <PageHeader title="分析" />

      {isLoading ? (
        <p className="py-12 text-center text-bl-secondary-label">載入中…</p>
      ) : (orders ?? []).length === 0 ? (
        <EmptyState icon={BarChart3} title="尚未有足夠可用於分析的資料" />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2 lg:items-start">
          <div className="lg:col-span-2">
            <BLSegmentedControl
              value={range}
              onChange={setRange}
              options={[
                { value: 'thirtyDays', label: '30 天' },
                { value: 'sixMonths', label: '6 個月' },
                { value: 'twelveMonths', label: '12 個月' },
              ]}
            />
          </div>

          {/* 獲利走勢 */}
          <BLCard className="lg:col-span-2">
            <SectionHeader
              title={TREND_TITLE[range]}
              action={
                stats.trendDelta != null ? (
                  <span
                    className={
                      stats.trendDelta >= 0
                        ? 'flex items-center gap-1 text-[15px] font-semibold text-bl-green'
                        : 'flex items-center gap-1 text-[15px] font-semibold text-bl-red'
                    }
                  >
                    {stats.trendDelta >= 0 ? (
                      <TrendingUp className="h-4 w-4" />
                    ) : (
                      <TrendingDown className="h-4 w-4" />
                    )}
                    <span className="bl-tabular">{formatPercent(Math.abs(stats.trendDelta))}</span>
                  </span>
                ) : undefined
              }
            />
            <div className="mt-3">
              <BLBarChart data={stats.trendBars} />
            </div>
          </BLCard>

          {/* 類別與成本 */}
          <BLCard>
            <SectionHeader title="類別排行" />
            <div className="mt-3">
              {stats.categoryBreakdown.length > 0 ? (
                <RankList
                  rows={stats.categoryBreakdown}
                  onSelect={(name) =>
                    router.push('/orders?category=' + encodeURIComponent(name))
                  }
                />
              ) : (
                <p className="px-1 text-[15px] text-bl-tertiary-label">—</p>
              )}
            </div>

            <div className="my-4 border-t border-bl-separator" />

            <SectionHeader title="成本結構" />
            <div className="mt-3 flex items-center gap-5">
              {stats.costStructure.length > 0 ? (
                <>
                  <BLDonutChart
                    segments={stats.costStructure}
                    centerTitle="總成本"
                    centerValue={formatTWD(costTotal)}
                  />
                  <ul className="flex-1 space-y-2">
                    {stats.costStructure.map((s) => (
                      <li key={s.label} className="flex items-center gap-2">
                        <span
                          className="h-2.5 w-2.5 shrink-0 rounded-full"
                          style={{ backgroundColor: s.color }}
                        />
                        <span className="flex-1 text-[15px] text-bl-label">{s.label}</span>
                        <span className="text-[15px] text-bl-secondary-label bl-tabular">
                          {formatTWD(s.value)}
                        </span>
                      </li>
                    ))}
                  </ul>
                </>
              ) : (
                <p className="px-1 text-[15px] text-bl-tertiary-label">—</p>
              )}
            </div>
          </BLCard>

          {/* 開團獲利 */}
          <BLCard>
            <SectionHeader title="每團毛利排行" />
            <div className="mt-3">
              {stats.campaignRanking.length > 0 ? (
                <RankList rows={stats.campaignRanking} onSelect={() => router.push('/campaigns')} />
              ) : (
                <p className="px-1 text-[15px] text-bl-tertiary-label">—</p>
              )}
            </div>
          </BLCard>

          {/* 訂單熱度 */}
          <BLCard className="lg:col-span-2">
            <SectionHeader title="下單熱力" />
            <div className="mt-3 overflow-x-auto bl-no-scrollbar">
              <BLHeatmap grid={stats.heatmap} />
            </div>
          </BLCard>
        </div>
      )}
    </div>
  );
}
