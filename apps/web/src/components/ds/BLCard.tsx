import type { ReactNode } from 'react';
import { cn } from '@/lib/cn';

// 內容卡片：surface 底、16 圓角、0.5px 分隔線邊框、淺色細陰影 (深色改靠邊框)
export function BLCard({
  children,
  className,
  padded = true,
  floating = false,
  onClick,
}: {
  children: ReactNode;
  className?: string;
  padded?: boolean;
  floating?: boolean;
  onClick?: () => void;
}) {
  return (
    <div
      onClick={onClick}
      className={cn(
        'rounded-bl-lg border-[0.5px] border-bl-separator bg-bl-surface',
        floating ? 'bl-card-shadow-floating' : 'bl-card-shadow',
        padded && 'p-4',
        onClick && 'cursor-pointer transition hover:border-bl-accent/30 hover:bl-card-shadow-floating',
        className,
      )}
    >
      {children}
    </div>
  );
}
