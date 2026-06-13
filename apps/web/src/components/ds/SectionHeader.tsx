import type { ReactNode } from 'react';

// 區段標題：粗體標題 + 選配右側動作。
export function SectionHeader({ title, action }: { title: string; action?: ReactNode }) {
  return (
    <div className="flex items-center justify-between px-1">
      <h2 className="text-[17px] font-semibold text-bl-label">{title}</h2>
      {action}
    </div>
  );
}
