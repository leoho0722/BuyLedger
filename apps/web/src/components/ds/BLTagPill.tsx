import { Tag } from 'lucide-react';
import { cn } from '@/lib/cn';

// 標籤膠囊：中性灰膠囊，前置 tag 圖示置於膠囊外、垂直置中
export function BLTagPill({ label, className }: { label: string; className?: string }) {
  return (
    <span className={cn('inline-flex items-center gap-1.5', className)}>
      <Tag className="h-3 w-3 shrink-0 text-bl-secondary-label" strokeWidth={2} />
      <span className="rounded-bl-pill bg-bl-fill-tertiary px-[9px] py-[3px] text-xs text-bl-secondary-label whitespace-nowrap">
        {label}
      </span>
    </span>
  );
}
