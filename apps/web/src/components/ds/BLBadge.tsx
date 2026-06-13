import { cn } from '@/lib/cn';
import { TONE_CLASSES, type Tone } from '@/lib/domain/constants';

const SOLID_BG: Record<Tone, string> = {
  neutral: 'bg-bl-secondary-label',
  accent: 'bg-bl-accent',
  success: 'bg-bl-green',
  warning: 'bg-bl-orange',
  destructive: 'bg-bl-red',
  informative: 'bg-bl-indigo',
};

// 計數徽章：實色底、白字 (側欄/分頁通知計數)。
export function BLCountBadge({ count, tone = 'destructive' }: { count: number; tone?: Tone }) {
  return (
    <span
      className={cn(
        'inline-flex min-w-[18px] items-center justify-center rounded-bl-pill px-[7px] py-px text-xs font-bold text-white bl-tabular',
        SOLID_BG[tone],
      )}
    >
      {count}
    </span>
  );
}

// 標籤徽章：14% 淡色底、tone 前景字 (如「無卡」「銀行匯款」)。
export function BLLabelBadge({ label, tone = 'neutral' }: { label: string; tone?: Tone }) {
  const c = TONE_CLASSES[tone];
  return (
    <span className={cn('inline-flex items-center rounded px-1.5 py-0.5 text-[11px] font-bold', c.bg, c.text)}>
      {label}
    </span>
  );
}
