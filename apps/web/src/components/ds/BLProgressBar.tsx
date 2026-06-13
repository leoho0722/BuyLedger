import { cn } from '@/lib/cn';

// 進度條：標題 + 數值文字 + 6pt 軌道/填色 (預設 accent)。
export function BLProgressBar({
  title,
  value,
  trailingText,
  tintClassName = 'bg-bl-accent',
}: {
  title?: string;
  value: number;
  trailingText?: string;
  tintClassName?: string;
}) {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  return (
    <div className="space-y-1">
      {(title || trailingText) && (
        <div className="flex items-center justify-between text-xs">
          <span className="font-semibold text-bl-label">{title}</span>
          <span className="text-bl-secondary-label bl-tabular">{trailingText}</span>
        </div>
      )}
      <div className="h-1.5 w-full overflow-hidden rounded-bl-pill bg-bl-fill-quaternary">
        <div className={cn('h-full rounded-bl-pill transition-[width]', tintClassName)} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}
