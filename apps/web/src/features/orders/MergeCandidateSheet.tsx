'use client';

import { useState } from 'react';
import { BLSearchField } from '@/components/ds/BLSearchField';
import { EmptyState } from '@/components/ds/EmptyState';
import { Sheet } from '@/components/ds/Sheet';
import { Inbox } from 'lucide-react';
import { OrderRow } from '@/components/OrderRow';
import { eligibleForMerge, groupOrdersByDay } from '@/lib/domain/orders';
import { formatSectionDate } from '@/lib/format';
import type { OrderDTO } from '@/lib/types';

// 合併候選 sheet：列出同客戶同幣別、可合併的訂單，依日期分段；選定後回呼。
export function MergeCandidateSheet({
  open,
  onClose,
  primary,
  orders,
  onPicked,
}: {
  open: boolean;
  onClose: () => void;
  primary: OrderDTO;
  orders: OrderDTO[];
  onPicked: (candidate: OrderDTO) => void;
}) {
  const [search, setSearch] = useState('');
  const now = new Date();

  const q = search.trim().toLowerCase();
  const candidates = orders
    .filter((o) => eligibleForMerge(primary, o))
    .filter((o) =>
      q
        ? [o.customer.name, ...o.items.map((it) => it.name)].join(' ').toLowerCase().includes(q)
        : true,
    );
  const sections = groupOrdersByDay(candidates);

  return (
    <Sheet open={open} onClose={onClose} title="選擇要合併的訂單" size="lg">
      <div className="space-y-3">
        <BLSearchField value={search} onChange={setSearch} placeholder="搜尋客戶、單號或商品" />
        {candidates.length === 0 ? (
          <EmptyState icon={Inbox} title="沒有可合併的訂單" description="僅能合併同客戶、同幣別且未取消/合併的訂單" />
        ) : (
          <div className="space-y-4">
            {sections.map((section) => (
              <div key={section.key} className="space-y-1">
                <p className="px-1 text-xs font-semibold text-bl-secondary-label">
                  {formatSectionDate(section.date, now)}
                </p>
                <div className="overflow-hidden rounded-bl-md border border-bl-separator bg-bl-surface">
                  {section.orders.map((o) => (
                    <div key={o.id} className="border-b border-bl-separator last:border-b-0">
                      <OrderRow order={o} variant="charged" onClick={() => onPicked(o)} />
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Sheet>
  );
}
