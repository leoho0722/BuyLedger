'use client';

import { X } from 'lucide-react';
import { useEffect, type ReactNode } from 'react';
import { cn } from '@/lib/cn';

// 通用 sheet/modal：手機由下浮出、桌機置中；含標題列與可捲動內容
export function Sheet({
  open,
  onClose,
  title,
  children,
  footer,
  leading,
  trailing,
  size = 'md',
}: {
  open: boolean;
  onClose: () => void;
  title?: ReactNode;
  children: ReactNode;
  footer?: ReactNode;
  leading?: ReactNode;
  trailing?: ReactNode;
  size?: 'md' | 'lg';
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px]" onClick={onClose} />
      <div
        className={cn(
          'relative z-10 flex max-h-[92vh] w-full flex-col rounded-t-bl-xl bg-bl-secondary-background shadow-2xl sm:rounded-bl-xl',
          size === 'lg' ? 'sm:max-w-2xl' : 'sm:max-w-lg',
        )}
      >
        <div className="mx-auto mt-2 h-1 w-9 rounded-full bg-bl-opaque-separator sm:hidden" />
        {(title || leading || trailing) && (
          <div className="flex items-center justify-between gap-2 border-b border-bl-separator px-4 py-3">
            <div className="min-w-[44px]">{leading}</div>
            <div className="truncate text-center text-[17px] font-semibold text-bl-label">{title}</div>
            <div className="flex min-w-[44px] justify-end">
              {trailing ?? (
                <button type="button" onClick={onClose} aria-label="關閉">
                  <X className="h-5 w-5 text-bl-secondary-label" />
                </button>
              )}
            </div>
          </div>
        )}
        <div className="flex-1 overflow-y-auto overscroll-contain p-4">{children}</div>
        {footer && <div className="border-t border-bl-separator p-4">{footer}</div>}
      </div>
    </div>
  );
}
