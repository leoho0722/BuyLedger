'use client';

import { Search, XCircle } from 'lucide-react';
import { cn } from '@/lib/cn';

export function BLSearchField({
  value,
  onChange,
  placeholder = '搜尋',
  className,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
}) {
  return (
    <div className={cn('flex items-center gap-2 rounded-bl-sm bg-bl-fill-tertiary px-3 py-2.5', className)}>
      <Search className="h-4 w-4 shrink-0 text-bl-secondary-label" />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="min-w-0 flex-1 bg-transparent text-[15px] text-bl-label outline-none placeholder:text-bl-tertiary-label"
      />
      {value && (
        <button type="button" onClick={() => onChange('')} aria-label="清除">
          <XCircle className="h-4 w-4 text-bl-tertiary-label" />
        </button>
      )}
    </div>
  );
}
