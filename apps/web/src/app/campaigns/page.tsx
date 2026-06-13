'use client';

import { Package, Plus } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useMemo, useState } from 'react';
import { BLCard } from '@/components/ds/BLCard';
import { BLProgressBar } from '@/components/ds/BLProgressBar';
import { BLSegmentedControl } from '@/components/ds/BLSegmentedControl';
import { BLStatusPill } from '@/components/ds/BLStatusPill';
import { EmptyState } from '@/components/ds/EmptyState';
import { PageHeader } from '@/components/PageHeader';
import { CAMPAIGN_STATUS_TITLE, CAMPAIGN_STATUS_TONE } from '@/lib/domain/constants';
import { campaignSummary } from '@/lib/domain/aggregations';
import { formatProgressPercent, formatSectionDate, formatShortDate, formatTWD } from '@/lib/format';
import { useCampaigns, useOrders } from '@/lib/queries';
import type { Campaign, CampaignStatus } from '@/lib/types';

type StatusFilter = 'all' | CampaignStatus;
type Granularity = 'day' | 'month' | 'year';

export default function CampaignsPage() {
  const router = useRouter();
  const { data: campaigns = [], isLoading } = useCampaigns();
  const { data: orders = [] } = useOrders();
  const now = new Date();

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [granularity, setGranularity] = useState<Granularity>('month');

  const sections = useMemo(() => {
    const filtered = campaigns
      .filter((c) => statusFilter === 'all' || c.status === statusFilter)
      .sort((a, b) => new Date(b.openDate).getTime() - new Date(a.openDate).getTime());
    const map = new Map<string, { label: string; items: Campaign[] }>();
    for (const c of filtered) {
      const key = groupKey(c.openDate, granularity);
      if (!map.has(key)) map.set(key, { label: groupLabel(c.openDate, granularity, now), items: [] });
      map.get(key)!.items.push(c);
    }
    return [...map.values()];
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [campaigns, statusFilter, granularity]);

  return (
    <div className="space-y-4">
      <PageHeader
        title="開團"
        action={
          <button
            type="button"
            onClick={() => router.push('/campaigns/new')}
            className="rounded-bl-sm bg-bl-accent p-2 text-white"
            aria-label="新增開團"
          >
            <Plus className="h-5 w-5" />
          </button>
        }
      />

      <BLSegmentedControl
        value={statusFilter}
        onChange={setStatusFilter}
        options={[
          { value: 'all', label: '全部' },
          { value: 'ongoing', label: '開團中' },
          { value: 'closed', label: '已收單' },
        ]}
      />
      <BLSegmentedControl
        value={granularity}
        onChange={setGranularity}
        options={[
          { value: 'day', label: '日' },
          { value: 'month', label: '月' },
          { value: 'year', label: '年' },
        ]}
      />

      {isLoading ? (
        <p className="py-12 text-center text-bl-secondary-label">載入中…</p>
      ) : sections.length === 0 ? (
        <EmptyState icon={Package} title="尚無開團" description="建立第一個團購批次" />
      ) : (
        sections.map((section) => (
          <div key={section.label} className="space-y-1">
            <p className="px-1 text-xs font-semibold text-bl-secondary-label">{section.label}</p>
            <div className="space-y-3">
              {section.items.map((c) => {
                const summary = campaignSummary(orders, c.name);
                return (
                  <BLCard key={c.id} className="space-y-2" onClick={() => router.push(`/campaigns/${c.id}`)}>
                    <div className="flex items-center justify-between gap-2">
                      <span className="truncate text-[17px] font-semibold text-bl-label">{c.name}</span>
                      <div className="flex shrink-0 items-center gap-1.5">
                        {c.settledDate && <BLStatusPill label="已結團" tone="neutral" showIndicator={false} />}
                        <BLStatusPill
                          label={CAMPAIGN_STATUS_TITLE[c.status]}
                          tone={CAMPAIGN_STATUS_TONE[c.status]}
                        />
                      </div>
                    </div>
                    <p className="text-xs text-bl-secondary-label bl-tabular">
                      {granularity !== 'day' ? `${formatShortDate(c.openDate)} · ` : ''}
                      {summary.orderCount} 筆 · 收款 {formatTWD(summary.receivedAmount)}/{formatTWD(summary.receivables)}
                    </p>
                    <BLProgressBar
                      title="到貨進度"
                      value={summary.deliveryRatio}
                      trailingText={formatProgressPercent(summary.deliveryRatio)}
                    />
                  </BLCard>
                );
              })}
            </div>
          </div>
        ))
      )}
    </div>
  );
}

function groupKey(iso: string, gran: Granularity): string {
  const d = new Date(iso);
  if (gran === 'day') return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
  if (gran === 'month') return `${d.getFullYear()}-${d.getMonth()}`;
  return `${d.getFullYear()}`;
}

function groupLabel(iso: string, gran: Granularity, now: Date): string {
  const d = new Date(iso);
  if (gran === 'day') return formatSectionDate(iso, now);
  if (gran === 'month') return `${d.getFullYear()}年${d.getMonth() + 1}月`;
  return `${d.getFullYear()}年`;
}
