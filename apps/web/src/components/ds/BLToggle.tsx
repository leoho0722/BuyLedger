'use client';

import { cn } from '@/lib/cn';

// iOS 風格開關
export function BLToggle({
  checked,
  onChange,
  label,
  description,
}: {
  checked: boolean;
  onChange: (value: boolean) => void;
  label?: string;
  description?: string;
}) {
  const button = (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={cn(
        'relative h-[31px] w-[51px] shrink-0 rounded-full transition-colors',
        checked ? 'bg-bl-green' : 'bg-bl-fill-tertiary',
      )}
    >
      <span
        className={cn(
          'absolute top-0.5 h-[27px] w-[27px] rounded-full bg-white shadow transition-all',
          checked ? 'left-[22px]' : 'left-0.5',
        )}
      />
    </button>
  );

  if (!label) return button;

  return (
    <div className="flex items-center justify-between gap-3">
      <div className="min-w-0">
        <p className="text-[15px] text-bl-label">{label}</p>
        {description && <p className="text-xs text-bl-secondary-label">{description}</p>}
      </div>
      {button}
    </div>
  );
}
