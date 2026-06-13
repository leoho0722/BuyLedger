'use client';

import { ChevronRight, type LucideIcon } from 'lucide-react';
import type { ReactNode } from 'react';
import { cn } from '@/lib/cn';

// 設定/清單列：選配前置圖示、標題、尾端值或自訂內容、可點。
export function BLListRow({
  icon: Icon,
  title,
  value,
  trailing,
  onClick,
  destructive,
  showChevron,
}: {
  icon?: LucideIcon;
  title: ReactNode;
  value?: ReactNode;
  trailing?: ReactNode;
  onClick?: () => void;
  destructive?: boolean;
  showChevron?: boolean;
}) {
  const content = (
    <>
      {Icon && (
        <Icon
          className={cn('h-[18px] w-[18px] shrink-0', destructive ? 'text-bl-red' : 'text-bl-accent')}
          strokeWidth={2}
        />
      )}
      <span className={cn('flex-1 truncate text-[15px]', destructive ? 'text-bl-red' : 'text-bl-label')}>
        {title}
      </span>
      {value != null && (
        <span className="shrink-0 text-[15px] text-bl-secondary-label bl-tabular">{value}</span>
      )}
      {trailing}
      {showChevron && <ChevronRight className="h-4 w-4 shrink-0 text-bl-tertiary-label" />}
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-center gap-3 px-3.5 py-3 text-left transition active:bg-bl-fill-quaternary"
      >
        {content}
      </button>
    );
  }
  return <div className="flex w-full items-center gap-3 px-3.5 py-3">{content}</div>;
}
