'use client';

import type { ReactNode } from 'react';
import { cn } from '@/lib/cn';

// 一般輸入欄位 (文字/數字)，標籤在上。
export function BLField({
  label,
  value,
  onChange,
  type = 'text',
  placeholder,
  inputMode,
  suffix,
  disabled,
  multiline,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  placeholder?: string;
  inputMode?: 'text' | 'decimal' | 'numeric';
  suffix?: ReactNode;
  disabled?: boolean;
  multiline?: boolean;
}) {
  return (
    <label className="block space-y-1">
      <span className="text-xs font-semibold text-bl-secondary-label">{label}</span>
      <div
        className={cn(
          'flex items-center gap-2 rounded-bl-sm border border-bl-separator bg-bl-surface px-3 py-2.5',
          disabled && 'opacity-50',
        )}
      >
        {multiline ? (
          <textarea
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder={placeholder}
            disabled={disabled}
            rows={3}
            className="min-w-0 flex-1 resize-none bg-transparent text-[15px] text-bl-label outline-none placeholder:text-bl-tertiary-label"
          />
        ) : (
          <input
            type={type}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder={placeholder}
            inputMode={inputMode}
            disabled={disabled}
            className="min-w-0 flex-1 bg-transparent text-[15px] text-bl-label outline-none placeholder:text-bl-tertiary-label bl-tabular"
          />
        )}
        {suffix && <span className="shrink-0 text-sm text-bl-secondary-label">{suffix}</span>}
      </div>
    </label>
  );
}

// 金額欄位：標籤 accent、數值大字、accent 邊框。
export function BLAmountField({
  label,
  value,
  onChange,
  currencyLabel,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  currencyLabel?: string;
}) {
  return (
    <label className="block space-y-1">
      <span className="text-xs font-semibold text-bl-accent">{label}</span>
      <div className="flex items-center gap-2 rounded-bl-sm border-[1.5px] border-bl-accent bg-bl-surface px-3 py-2">
        <input
          inputMode="decimal"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="min-w-0 flex-1 bg-transparent text-[22px] font-bold text-bl-label outline-none bl-tabular"
        />
        {currencyLabel && <span className="shrink-0 text-sm text-bl-secondary-label">{currencyLabel}</span>}
      </div>
    </label>
  );
}
