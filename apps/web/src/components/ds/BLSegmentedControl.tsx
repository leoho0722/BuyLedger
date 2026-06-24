'use client';

import { cn } from '@/lib/cn';

export interface SegmentOption<T extends string> {
  value: T;
  label: string;
}

// 分段控制：track fillTertiary、選取段 surface
export function BLSegmentedControl<T extends string>({
  options,
  value,
  onChange,
  className,
}: {
  options: SegmentOption<T>[];
  value: T;
  onChange: (value: T) => void;
  className?: string;
}) {
  return (
    <div className={cn('flex w-full rounded-bl-sm bg-bl-fill-tertiary p-0.5', className)}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          onClick={() => onChange(o.value)}
          aria-pressed={value === o.value}
          className={cn(
            'min-h-[30px] flex-1 rounded-[8px] px-3 text-[15px] font-semibold transition',
            value === o.value ? 'bg-bl-surface text-bl-label shadow-sm' : 'text-bl-secondary-label',
          )}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
