'use client';

import { useRouter } from 'next/navigation';
import { Users } from 'lucide-react';
import { PageHeader } from '@/components/PageHeader';
import { BLCard } from '@/components/ds/BLCard';
import { BLAvatar } from '@/components/ds/BLAvatar';
import { BLLabelBadge } from '@/components/ds/BLBadge';
import { EmptyState } from '@/components/ds/EmptyState';
import { useOrders } from '@/lib/queries';
import { customerRollup, type CustomerRow } from '@/lib/domain/aggregations';
import { CUSTOMER_TIER_TITLE } from '@/lib/domain/constants';
import type { Tone } from '@/lib/domain/constants';
import type { CustomerTier } from '@/lib/types';
import { formatTWD, formatShortDate } from '@/lib/format';

// 階層 → 徽章語意色：VIP 警示色、常客主色、其餘中性
function tierTone(tier: CustomerTier): Tone {
  if (tier === 'vip') return 'warning';
  if (tier === 'regular') return 'accent';
  return 'neutral';
}

// 客戶名單頁：依累計消費降冪排序的客戶彙總
export default function CustomersPage() {
  const router = useRouter();
  const { data: orders, isLoading } = useOrders();
  const rows = customerRollup(orders ?? []);

  // 點客戶跳訂單列表並帶入搜尋條件
  const openOrders = (name: string) => {
    router.push(`/orders?search=${encodeURIComponent(name)}`);
  };

  return (
    <div>
      <PageHeader title="客戶名單" />

      {isLoading ? (
        <p className="py-12 text-center text-bl-secondary-label">載入中…</p>
      ) : rows.length === 0 ? (
        <BLCard>
          <EmptyState icon={Users} title="尚無客戶" />
        </BLCard>
      ) : (
        <div className="space-y-4">
          {/* 前 3 名高亮卡片 */}
          <div className="grid grid-cols-3 gap-3">
            {rows.slice(0, 3).map((row) => (
              <HighlightCard key={row.name} row={row} onClick={() => openOrders(row.name)} />
            ))}
          </div>

          {/* 完整清單 */}
          <BLCard padded={false}>
            {rows.map((row, index) => (
              <button
                key={row.name}
                type="button"
                onClick={() => openOrders(row.name)}
                className={
                  'flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-bl-fill-quaternary' +
                  (index < rows.length - 1 ? ' border-b border-bl-separator' : '')
                }
              >
                <BLAvatar name={row.name} initials={row.initials} size={40} />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[15px] font-semibold text-bl-label">{row.name}</p>
                  <p className="mt-0.5 text-[13px] text-bl-secondary-label">
                    {CUSTOMER_TIER_TITLE[row.tier]}・{row.orderCount} 筆
                  </p>
                </div>
                <div className="shrink-0 text-right">
                  <p className="text-[15px] font-semibold text-bl-label bl-tabular">
                    {formatTWD(row.totalSpent)}
                  </p>
                  <p className="mt-0.5 text-[13px] text-bl-tertiary-label bl-tabular">
                    {formatShortDate(row.lastDate)}
                  </p>
                </div>
              </button>
            ))}
          </BLCard>
        </div>
      )}
    </div>
  );
}

// 高亮卡片：頭像 + 名稱 + 階層徽章 + 累計消費，整張可點
function HighlightCard({ row, onClick }: { row: CustomerRow; onClick: () => void }) {
  return (
    <BLCard onClick={onClick} className="flex flex-col items-center gap-2 text-center">
      <BLAvatar name={row.name} initials={row.initials} size={48} />
      <p className="w-full truncate text-[15px] font-semibold text-bl-label">{row.name}</p>
      <BLLabelBadge tone={tierTone(row.tier)} label={CUSTOMER_TIER_TITLE[row.tier]} />
      <p className="text-[15px] font-semibold text-bl-label bl-tabular">{formatTWD(row.totalSpent)}</p>
    </BLCard>
  );
}
