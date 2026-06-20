'use client';

import { Check } from 'lucide-react';
import { cn } from '@/lib/cn';
import { ORDER_STATUS_TITLE, ORDER_STATUS_TONE } from '@/lib/domain/constants';
import { orderCategoryTag, orderItemSummary } from '@/lib/domain/orders';
import { formatShortDate, formatSignedTWD, formatTWD } from '@/lib/format';
import type { OrderDTO } from '@/lib/types';
import { BLAvatar } from './ds/BLAvatar';
import { BLStatusPill } from './ds/BLStatusPill';
import { BLTagPill } from './ds/BLTagPill';

// 訂單列：左欄頭像 + 客戶/日期/明細/類別；右欄狀態+收益+獲利 (預設) 或收款金額 (charged 變體)。
export function OrderRow({
  order,
  variant = 'default',
  onClick,
  selecting = false,
  selected = false,
}: {
  order: OrderDTO;
  variant?: 'default' | 'charged';
  onClick?: () => void;
  // 多選模式：顯示勾選圈，列點擊改為切換選取。
  selecting?: boolean;
  selected?: boolean;
}) {
  const categoryTag = orderCategoryTag(order);
  const profit = Number(order.summary.profit);

  const inner = (
    <>
      {selecting && (
        <span
          className={cn(
            'mt-2.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border transition',
            selected ? 'border-bl-accent bg-bl-accent text-white' : 'border-bl-separator',
          )}
        >
          {selected && <Check className="h-3.5 w-3.5" />}
        </span>
      )}
      <BLAvatar name={order.customer.name} initials={order.customer.initials} size={40} />

      <div className="min-w-0 flex-1 space-y-1.5">
        <div className="flex items-center gap-1.5">
          <span className="truncate text-[15px] font-semibold text-bl-label">{order.customer.name}</span>
          <span className="text-bl-tertiary-label">·</span>
          <span className="shrink-0 text-xs text-bl-secondary-label bl-tabular">
            {formatShortDate(order.date)}
          </span>
        </div>
        <p className="truncate text-[13px] text-bl-secondary-label">{orderItemSummary(order)}</p>
        {categoryTag && <BLTagPill label={categoryTag} />}
      </div>

      <div className="flex shrink-0 flex-col items-end gap-1">
        {variant === 'charged' ? (
          <>
            <span className="text-[15px] font-semibold text-bl-label bl-tabular">
              {formatTWD(order.chargedAmount)}
            </span>
            <span className="text-[11px] text-bl-secondary-label">收款金額</span>
          </>
        ) : (
          <>
            <BLStatusPill label={ORDER_STATUS_TITLE[order.status]} tone={ORDER_STATUS_TONE[order.status]} />
            <span className="text-[15px] font-semibold text-bl-label bl-tabular">
              {formatTWD(order.summary.revenue)}
            </span>
            <span className={cn('text-xs font-semibold bl-tabular', profit >= 0 ? 'text-bl-green' : 'text-bl-red')}>
              {formatSignedTWD(profit)}
            </span>
          </>
        )}
      </div>
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-start gap-3 px-3.5 py-3 text-left transition hover:bg-bl-fill-quaternary active:bg-bl-fill-quaternary"
      >
        {inner}
      </button>
    );
  }
  return <div className="flex w-full items-start gap-3 px-3.5 py-3">{inner}</div>;
}
