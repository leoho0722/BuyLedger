'use client';

import { ChevronDown } from 'lucide-react';
import { cn } from '@/lib/cn';

// 表單選擇列：標籤在上，點擊開啟挑選器。
export function BLSelectRow({
  label,
  value,
  placeholder = '請選擇',
  onClick,
  active,
}: {
  label: string;
  value?: string;
  placeholder?: string;
  onClick: () => void;
  active?: boolean;
}) {
  return (
    <div className="space-y-1">
      <span className="text-xs font-semibold text-bl-secondary-label">{label}</span>
      <button
        type="button"
        onClick={onClick}
        className={cn(
          'flex w-full items-center justify-between gap-2 rounded-bl-sm border bg-bl-surface px-3 py-2.5 text-left',
          active ? 'border-bl-accent' : 'border-bl-separator',
        )}
      >
        <span className={cn('truncate text-[15px]', value ? 'text-bl-label' : 'text-bl-tertiary-label')}>
          {value || placeholder}
        </span>
        <ChevronDown className="h-4 w-4 shrink-0 text-bl-tertiary-label" />
      </button>
    </div>
  );
}
