import type { LucideIcon } from 'lucide-react';

// 空狀態：圖示 + 標題 + 說明 (對齊產品政策：寧可空狀態也不顯示假資料)。
export function EmptyState({
  icon: Icon,
  title,
  description,
}: {
  icon: LucideIcon;
  title: string;
  description?: string;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-6 py-14 text-center">
      <Icon className="h-10 w-10 text-bl-tertiary-label" strokeWidth={1.5} />
      <p className="text-[17px] font-semibold text-bl-label">{title}</p>
      {description && <p className="max-w-xs text-[15px] text-bl-secondary-label">{description}</p>}
    </div>
  );
}
