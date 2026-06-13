// 甜甜圈圖：innerRadius 比例 0.68、各段以 stroke-dasharray 疊放，中央顯示標題/數值。
export function BLDonutChart({
  segments,
  centerTitle,
  centerValue,
  size = 150,
}: {
  segments: { label: string; value: number; color: string }[];
  centerTitle?: string;
  centerValue?: string;
  size?: number;
}) {
  const total = segments.reduce((acc, s) => acc + s.value, 0);
  const stroke = size * 0.16;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  let offset = 0;

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--bl-fill-tertiary)"
          strokeWidth={stroke}
        />
        {total > 0 &&
          segments.map((s, i) => {
            const fraction = s.value / total;
            const dash = fraction * circumference;
            const seg = (
              <circle
                key={i}
                cx={size / 2}
                cy={size / 2}
                r={radius}
                fill="none"
                stroke={s.color}
                strokeWidth={stroke}
                strokeDasharray={`${Math.max(0, dash - 2)} ${circumference - dash + 2}`}
                strokeDashoffset={-offset}
                strokeLinecap="butt"
              />
            );
            offset += dash;
            return seg;
          })}
      </svg>
      {(centerTitle || centerValue) && (
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {centerTitle && <span className="text-[11px] text-bl-secondary-label">{centerTitle}</span>}
          {centerValue && (
            <span className="text-[17px] font-semibold text-bl-label bl-tabular">{centerValue}</span>
          )}
        </div>
      )}
    </div>
  );
}
