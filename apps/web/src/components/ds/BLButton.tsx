import type { ButtonHTMLAttributes, ReactNode } from 'react';
import { cn } from '@/lib/cn';

type Variant = 'primary' | 'secondary' | 'plain' | 'destructive';

const VARIANT_CLASSES: Record<Variant, string> = {
  primary: 'bg-bl-accent text-white px-[18px]',
  secondary: 'bg-bl-fill-tertiary text-bl-accent px-[18px]',
  plain: 'bg-transparent text-bl-accent px-0',
  destructive: 'bg-bl-red/14 text-bl-red px-[18px]',
};

// 按鈕：四種變體，最小高度 44，按下縮放/淡出。
export function BLButton({
  children,
  variant = 'primary',
  fullWidth = false,
  className,
  ...props
}: {
  children: ReactNode;
  variant?: Variant;
  fullWidth?: boolean;
} & ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      className={cn(
        'inline-flex min-h-[44px] items-center justify-center gap-2 rounded-bl-md text-[17px] font-semibold transition active:scale-[0.98] active:opacity-75 disabled:pointer-events-none disabled:opacity-40',
        VARIANT_CLASSES[variant],
        fullWidth && 'w-full',
        className,
      )}
      {...props}
    >
      {children}
    </button>
  );
}
