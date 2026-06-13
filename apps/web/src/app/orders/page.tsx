'use client';

import { Plus, Inbox, ListFilter, Sparkles } from 'lucide-react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useMemo, useState } from 'react';
import { BLCard } from '@/components/ds/BLCard';
import { BLSearchField } from '@/components/ds/BLSearchField';
import { EmptyState } from '@/components/ds/EmptyState';
import { OrderRow } from '@/components/OrderRow';
import { PageHeader } from '@/components/PageHeader';
import { Sheet } from '@/components/ds/Sheet';
import { BLButton } from '@/components/ds/BLButton';
import { cn } from '@/lib/cn';
import { ORDER_STATUS_ORDER, ORDER_STATUS_TITLE } from '@/lib/domain/constants';
import {
  DEFAULT_FILTERS,
  filterOrders,
  groupOrdersByDay,
  type OrderFilters,
  type StatusFilter,
} from '@/lib/domain/orders';
import { formatSectionDate } from '@/lib/format';
import {
  useCampaigns,
  useCategories,
  useOrders,
  usePaymentMethods,
  useSettings,
} from '@/lib/queries';
import type { CampaignStatus } from '@/lib/types';
import { AiSummarySheet } from '@/features/orders/AiSummarySheet';
import { OrderFilterSheet } from '@/features/orders/OrderFilterSheet';

export default function OrdersPage() {
  return (
    <Suspense fallback={<p className="py-12 text-center text-bl-secondary-label">載入中…</p>}>
      <OrdersInner />
    </Suspense>
  );
}

function OrdersInner() {
  const router = useRouter();
  const params = useSearchParams();
  const { data: orders = [], isLoading } = useOrders();
  const { data: campaigns = [] } = useCampaigns();
  const { data: categories = [] } = useCategories();
  const { data: paymentMethods = [] } = usePaymentMethods();
  const { data: settings } = useSettings();
  const now = new Date();

  const [filters, setFilters] = useState<OrderFilters>(DEFAULT_FILTERS);
  const [filterOpen, setFilterOpen] = useState(false);
  const [aiOpen, setAiOpen] = useState(false);
  const [aiBlocked, setAiBlocked] = useState(false);

  // 深層連結：?category= / ?search= (來自分析/客戶頁)。
  useEffect(() => {
    const category = params.get('category');
    const search = params.get('search');
    if (category || search) {
      setFilters((f) => ({ ...f, category: category ?? f.category, search: search ?? f.search }));
    }
  }, [params]);

  const campaignStatusByName = useMemo(() => {
    const map: Record<string, CampaignStatus> = {};
    for (const c of campaigns) map[c.name] = c.status;
    return map;
  }, [campaigns]);

  const filtered = useMemo(
    () => filterOrders(orders, filters, { now, campaignStatusByName }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [orders, filters, campaignStatusByName],
  );
  const sections = groupOrdersByDay(filtered);

  const statusCounts = useMemo(() => {
    const map = new Map<string, number>();
    for (const o of orders) map.set(o.status, (map.get(o.status) ?? 0) + 1);
    return map;
  }, [orders]);

  const filterActive =
    filters.datePeriod !== 'all' ||
    filters.category !== null ||
    filters.paymentMethod !== null ||
    filters.campaign !== null ||
    filters.campaignStatus !== 'all';

  const openAi = () => {
    if (settings?.useAiSummary) setAiOpen(true);
    else setAiBlocked(true);
  };

  return (
    <div className="space-y-4">
      <PageHeader
        title="訂單"
        action={
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={openAi}
              disabled={filtered.length === 0}
              className="inline-flex items-center gap-1.5 rounded-bl-md bg-bl-fill-tertiary px-3 py-2 text-[15px] font-semibold text-bl-accent transition hover:bg-bl-fill-secondary disabled:pointer-events-none disabled:opacity-40"
            >
              <Sparkles className="h-4 w-4" />
              <span className="hidden sm:inline">AI 總結</span>
            </button>
            <button
              type="button"
              onClick={() => router.push('/orders/new')}
              className="inline-flex items-center gap-1.5 rounded-bl-md bg-bl-accent px-3 py-2 text-[15px] font-semibold text-white transition hover:opacity-90"
            >
              <Plus className="h-4 w-4" />
              <span className="hidden sm:inline">新增訂單</span>
            </button>
          </div>
        }
      />

      {/* Web 工具列：搜尋 + 篩選同列 */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="sm:flex-1">
          <BLSearchField
            value={filters.search}
            onChange={(v) => setFilters((f) => ({ ...f, search: v }))}
            placeholder="搜尋客戶、單號或商品"
          />
        </div>
        <button
          type="button"
          onClick={() => setFilterOpen(true)}
          className={cn(
            'flex w-full items-center justify-center gap-2 rounded-bl-md px-4 py-2.5 text-[15px] transition sm:w-auto sm:shrink-0',
            filterActive
              ? 'bg-bl-accent/14 text-bl-accent hover:bg-bl-accent/20'
              : 'bg-bl-fill-tertiary text-bl-secondary-label hover:bg-bl-fill-secondary',
          )}
        >
          <ListFilter className="h-4 w-4" />
          <span>篩選</span>
          {filterActive && <span className="h-2 w-2 rounded-full bg-bl-accent" />}
        </button>
      </div>

      {/* 狀態快篩 chips */}
      <div className="flex gap-2 overflow-x-auto bl-no-scrollbar pb-1">
        <StatusChip
          label="全部"
          count={orders.length}
          active={filters.status === 'all'}
          onClick={() => setFilters((f) => ({ ...f, status: 'all' }))}
        />
        {ORDER_STATUS_ORDER.map((s) => (
          <StatusChip
            key={s}
            label={ORDER_STATUS_TITLE[s]}
            count={statusCounts.get(s) ?? 0}
            active={filters.status === s}
            onClick={() => setFilters((f) => ({ ...f, status: s as StatusFilter }))}
          />
        ))}
      </div>

      {isLoading ? (
        <p className="py-12 text-center text-bl-secondary-label">載入中…</p>
      ) : filtered.length === 0 ? (
        <EmptyState icon={Inbox} title="沒有符合條件的訂單" description="調整篩選或新增一筆訂單" />
      ) : (
        <div className="space-y-6">
          {sections.map((section) => (
            <div key={section.key} className="space-y-2">
              <p className="px-1 text-xs font-semibold text-bl-secondary-label">
                {formatSectionDate(section.date, now)}
              </p>
              <div className="space-y-3">
                {section.orders.map((o) => (
                  <BLCard key={o.id} padded={false} className="overflow-hidden">
                    <OrderRow order={o} onClick={() => router.push(`/orders/${o.id}`)} />
                  </BLCard>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      <OrderFilterSheet
        open={filterOpen}
        onClose={() => setFilterOpen(false)}
        filters={filters}
        onApply={setFilters}
        categories={categories}
        paymentMethods={paymentMethods}
        campaigns={campaigns}
      />
      <AiSummarySheet
        open={aiOpen}
        onClose={() => setAiOpen(false)}
        orderIds={filtered.map((o) => o.id)}
        selectedCategory={filters.category}
      />
      <Sheet open={aiBlocked} onClose={() => setAiBlocked(false)} title="AI 商品明細總結">
        <div className="space-y-4 py-2 text-center">
          <p className="text-[15px] text-bl-secondary-label">尚未啟用 AI 商品明細總結，請先於設定開啟。</p>
          <Link href="/more/settings">
            <BLButton variant="secondary" onClick={() => setAiBlocked(false)}>
              前往設定
            </BLButton>
          </Link>
        </div>
      </Sheet>
    </div>
  );
}

function StatusChip({
  label,
  count,
  active,
  onClick,
}: {
  label: string;
  count: number;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex shrink-0 items-center gap-1.5 rounded-bl-pill px-3 py-1.5 text-sm transition',
        active ? 'bg-bl-accent text-white' : 'bg-bl-fill-tertiary text-bl-secondary-label',
      )}
    >
      {label}
      <span className={cn('bl-tabular text-xs', active ? 'text-white/80' : 'text-bl-tertiary-label')}>
        {count}
      </span>
    </button>
  );
}
