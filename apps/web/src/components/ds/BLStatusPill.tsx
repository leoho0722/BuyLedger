import { cn } from '@/lib/cn';
import { TONE_CLASSES, type Tone } from '@/lib/domain/constants';

// 狀態膠囊：tone 決定前景/背景，選配 5pt 指示點
export function BLStatusPill({
  label,
  tone = 'neutral',
  showIndicator = true,
  className,
}: {
  label: string;
  tone?: Tone;
  showIndicator?: boolean;
  className?: string;
}) {
  const c = TONE_CLASSES[tone];
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-bl-pill px-[9px] py-[3px] text-xs font-semibold whitespace-nowrap',
        c.bg,
        c.text,
        className,
      )}
    >
      {showIndicator && <span className={cn('h-[5px] w-[5px] rounded-full', c.dot)} />}
      {label}
    </span>
  );
}
