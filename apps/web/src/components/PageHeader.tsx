import type { ReactNode } from 'react';

// 頁面大標題列
export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: ReactNode;
}) {
  return (
    <div className="mb-5 flex items-end justify-between gap-3">
      <div className="min-w-0">
        <h1 className="text-[28px] font-bold tracking-tight text-bl-label">{title}</h1>
        {subtitle && <p className="mt-0.5 text-[15px] text-bl-secondary-label">{subtitle}</p>}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  );
}
