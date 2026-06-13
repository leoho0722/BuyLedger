// 訂單數熱力圖：8 週 × 7 天 (週一為始)，accent 依數量調整不透明度。
export function BLHeatmap({ grid }: { grid: number[][] }) {
  const max = Math.max(1, ...grid.flat());
  const dayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  return (
    <div className="flex gap-2">
      <div className="flex flex-col justify-between py-px text-[10px] text-bl-tertiary-label">
        {dayLabels.map((d) => (
          <span key={d} className="h-3.5 leading-3.5">
            {d}
          </span>
        ))}
      </div>
      <div className="flex gap-1">
        {grid.map((week, wi) => (
          <div key={wi} className="flex flex-col gap-1">
            {week.map((count, di) => (
              <div
                key={di}
                title={`${count} 筆`}
                className="h-3.5 w-3.5 rounded-[3px]"
                style={{
                  backgroundColor:
                    count === 0 ? 'var(--bl-fill-quaternary)' : 'var(--bl-accent)',
                  opacity: count === 0 ? 1 : 0.25 + 0.75 * (count / max),
                }}
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
