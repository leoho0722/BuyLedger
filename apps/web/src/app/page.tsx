'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowDown, ArrowUp, ShoppingBag } from 'lucide-react';
import { BLButton } from '@/components/ds/BLButton';
import { BLCard } from '@/components/ds/BLCard';
import { BLProgressBar } from '@/components/ds/BLProgressBar';
import { BLSparkline } from '@/components/ds/BLSparkline';
import { SectionHeader } from '@/components/ds/SectionHeader';
import { OrderRow } from '@/components/OrderRow';
import { PageHeader } from '@/components/PageHeader';
import { campaignSummary, dashboardStats } from '@/lib/domain/aggregations';
import { formatPercent, formatProgressPercent, formatSignedTWD, formatTWD } from '@/lib/format';
import { useCampaigns, useOrders, useSettings } from '@/lib/queries';

// 漸層底 (accent → indigo)，Hero 卡與 onboarding 圖示共用。
const HERO_GRADIENT = 'linear-gradient(135deg,var(--bl-accent),var(--bl-indigo))';

export default function DashboardPage() {
  const router = useRouter();
  const orders = useOrders();
  const campaigns = useCampaigns();
  const settings = useSettings();

  const now = new Date();
  const orderList = orders.data ?? [];
  const campaignList = campaigns.data ?? [];

  // 1) 載入中。
  if (orders.isLoading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center text-[15px] text-bl-secondary-label">
        載入中…
      </div>
    );
  }

  // 2) 無訂單：onboarding。
  if (orderList.length === 0) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <BLCard className="flex max-w-sm flex-col items-center gap-4 text-center">
          <div
            className="flex h-16 w-16 items-center justify-center rounded-full"
            style={{ background: HERO_GRADIENT }}
          >
            <ShoppingBag className="h-8 w-8 text-white" strokeWidth={1.75} />
          </div>
          <div className="space-y-1">
            <p className="text-[20px] font-bold text-bl-label">歡迎使用 BuyLedger</p>
            <p className="text-[15px] text-bl-secondary-label">建立第一筆訂單，開始記帳</p>
          </div>
          <BLButton fullWidth>
            <Link href="/orders/new">建立第一筆訂單</Link>
          </BLButton>
        </BLCard>
      </div>
    );
  }

  // 3) 有訂單：完整儀表板。
  const stats = dashboardStats(orderList, now, settings.data?.monthlyProfitGoal ?? '80000');
  const goal = Number(settings.data?.monthlyProfitGoal ?? '80000');
  const ongoingCampaigns = campaignList.filter((c) => c.status === 'ongoing');

  return (
    <div className="space-y-4">
      <PageHeader title="總覽" />

      {/* Hero：本月淨獲利 */}
      <div className="rounded-bl-lg p-5 text-white" style={{ background: HERO_GRADIENT }}>
        <p className="text-sm text-white/80">本月淨獲利</p>
        <p className="text-[36px] font-bold bl-tabular">{formatSignedTWD(stats.current.profit)}</p>
        {stats.profitDelta != null && (
          <div className="mt-1 flex items-center gap-1 text-sm text-white/90">
            {stats.profitDelta >= 0 ? (
              <ArrowUp className="h-4 w-4" strokeWidth={2.25} />
            ) : (
              <ArrowDown className="h-4 w-4" strokeWidth={2.25} />
            )}
            <span className="bl-tabular">{formatPercent(Math.abs(stats.profitDelta))}</span>
            <span className="text-white/70">較上月</span>
          </div>
        )}
        <div className="mt-3">
          <BLSparkline values={stats.sparkline} stroke="rgba(255,255,255,0.9)" />
        </div>
        {goal > 0 && (
          <div className="mt-3 [&_span]:text-white">
            <BLProgressBar
              title="本月目標"
              value={stats.goalProgress}
              trailingText={formatProgressPercent(stats.goalProgress)}
              tintClassName="bg-white"
            />
          </div>
        )}
      </div>

      {/* KPI 磁貼 */}
      <div className="grid grid-cols-2 gap-3">
        <KpiTile label="營業額" value={formatTWD(stats.current.revenue)} />
        <KpiTile label="成本" value={formatTWD(stats.current.cost)} />
        <KpiTile label="毛利率" value={formatPercent(stats.current.margin)} />
        <KpiTile label="進行中訂單" value={`${stats.activeCount} 筆`} />
      </div>

      {/* 進行中開團 */}
      {ongoingCampaigns.length > 0 && (
        <div className="space-y-2">
          <SectionHeader title="進行中開團" />
          <BLCard className="space-y-4">
            {ongoingCampaigns.map((c) => {
              const summary = campaignSummary(orderList, c.name);
              return (
                <Link key={c.id} href={`/campaigns/${c.id}`} className="block space-y-2">
                  <p className="text-[15px] font-semibold text-bl-label">{c.name}</p>
                  <BLProgressBar
                    title="到貨進度"
                    value={summary.deliveryRatio}
                    trailingText={formatProgressPercent(summary.deliveryRatio)}
                  />
                  <BLProgressBar
                    title="收款進度"
                    value={summary.receivedRatio}
                    trailingText={formatProgressPercent(summary.receivedRatio)}
                    tintClassName="bg-bl-green"
                  />
                </Link>
              );
            })}
          </BLCard>
        </div>
      )}

      {/* 近期訂單 */}
      <div className="space-y-2">
        <SectionHeader
          title="近期訂單"
          action={
            <Link href="/orders" className="text-[15px] text-bl-accent">
              查看全部
            </Link>
          }
        />
        <BLCard padded={false}>
          {stats.recentOrders.map((o, i) => (
            <div
              key={o.id}
              className={i < stats.recentOrders.length - 1 ? 'border-b border-bl-separator' : undefined}
            >
              <OrderRow order={o} onClick={() => router.push(`/orders/${o.id}`)} />
            </div>
          ))}
        </BLCard>
      </div>
    </div>
  );
}

// KPI 磁貼：小 label + 大值。
function KpiTile({ label, value }: { label: string; value: string }) {
  return (
    <BLCard>
      <p className="text-[13px] text-bl-secondary-label">{label}</p>
      <p className="mt-1 text-[22px] font-bold text-bl-label bl-tabular">{value}</p>
    </BLCard>
  );
}
