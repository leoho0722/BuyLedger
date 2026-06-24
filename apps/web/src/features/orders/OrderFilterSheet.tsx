'use client';

import { useEffect, useState } from 'react';
import { BLSegmentedControl } from '@/components/ds/BLSegmentedControl';
import { BLSelectRow } from '@/components/ds/BLSelectRow';
import { BLButton } from '@/components/ds/BLButton';
import { OptionPicker } from '@/components/ds/OptionPicker';
import { Sheet } from '@/components/ds/Sheet';
import type { Campaign, PaymentMethodDTO } from '@/lib/types';
import {
  DATE_PERIOD_TITLE,
  type DatePeriod,
  type OrderFilters,
} from '@/lib/domain/orders';

// 訂單篩選 sheet：日期區間 + 類別 + 付款方式 + 開團 + 開團狀態，套用時一次提交
export function OrderFilterSheet({
  open,
  onClose,
  filters,
  onApply,
  categories,
  paymentMethods,
  campaigns,
}: {
  open: boolean;
  onClose: () => void;
  filters: OrderFilters;
  onApply: (next: OrderFilters) => void;
  categories: string[];
  paymentMethods: PaymentMethodDTO[];
  campaigns: Campaign[];
}) {
  const [draft, setDraft] = useState<OrderFilters>(filters);
  const [picker, setPicker] = useState<null | 'category' | 'payment' | 'campaign'>(null);

  useEffect(() => {
    if (open) setDraft(filters);
  }, [open, filters]);

  const periods: DatePeriod[] = ['all', 'thisWeek', 'thisMonth', 'lastMonth'];

  return (
    <Sheet
      open={open}
      onClose={onClose}
      title="篩選"
      leading={
        <button type="button" onClick={onClose} className="text-[17px] text-bl-accent">
          取消
        </button>
      }
      trailing={
        <button
          type="button"
          onClick={() => {
            onApply(draft);
            onClose();
          }}
          className="text-[17px] font-semibold text-bl-accent"
        >
          套用
        </button>
      }
    >
      <div className="space-y-4">
        <div className="space-y-1">
          <span className="text-xs font-semibold text-bl-secondary-label">日期區間</span>
          <BLSegmentedControl
            value={draft.datePeriod}
            onChange={(v) => setDraft((d) => ({ ...d, datePeriod: v }))}
            options={periods.map((p) => ({ value: p, label: DATE_PERIOD_TITLE[p] }))}
          />
        </div>

        <BLSelectRow
          label="商品類別"
          value={draft.category ?? '全部'}
          onClick={() => setPicker('category')}
        />
        <BLSelectRow
          label="付款方式"
          value={draft.paymentMethod ?? '全部'}
          onClick={() => setPicker('payment')}
        />
        <BLSelectRow
          label="開團"
          value={draft.campaign ?? '全部'}
          onClick={() => setPicker('campaign')}
        />

        <div className="space-y-1">
          <span className="text-xs font-semibold text-bl-secondary-label">開團狀態</span>
          <BLSegmentedControl
            value={draft.campaignStatus}
            onChange={(v) => setDraft((d) => ({ ...d, campaignStatus: v }))}
            options={[
              { value: 'all', label: '全部' },
              { value: 'ongoing', label: '開團中' },
              { value: 'closed', label: '已收單' },
            ]}
          />
        </div>

        <BLButton
          variant="plain"
          fullWidth
          onClick={() =>
            setDraft((d) => ({
              ...d,
              datePeriod: 'all',
              category: null,
              paymentMethod: null,
              campaign: null,
              campaignStatus: 'all',
            }))
          }
        >
          清除全部
        </BLButton>
      </div>

      <OptionPicker
        open={picker === 'category'}
        onClose={() => setPicker(null)}
        title="商品類別"
        options={categories.map((c) => ({ value: c, label: c }))}
        selected={draft.category ?? ''}
        clearLabel="全部類別"
        onClear={() => setDraft((d) => ({ ...d, category: null }))}
        onSelect={(v) => setDraft((d) => ({ ...d, category: v }))}
      />
      <OptionPicker
        open={picker === 'payment'}
        onClose={() => setPicker(null)}
        title="付款方式"
        options={paymentMethods.map((p) => ({ value: p.name, label: p.name }))}
        selected={draft.paymentMethod ?? ''}
        clearLabel="全部付款方式"
        onClear={() => setDraft((d) => ({ ...d, paymentMethod: null }))}
        onSelect={(v) => setDraft((d) => ({ ...d, paymentMethod: v }))}
      />
      <OptionPicker
        open={picker === 'campaign'}
        onClose={() => setPicker(null)}
        title="選擇開團"
        options={campaigns.map((c) => ({ value: c.name, label: c.name }))}
        selected={draft.campaign ?? ''}
        clearLabel="全部開團"
        onClear={() => setDraft((d) => ({ ...d, campaign: null }))}
        onSelect={(v) => setDraft((d) => ({ ...d, campaign: v }))}
      />
    </Sheet>
  );
}
