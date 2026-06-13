// 長條圖：accent 漸層、頂端圓角、隱藏 Y 軸、X 標籤；支援零基線上下 (獲利可負)。
export function BLBarChart({
  data,
  height = 180,
}: {
  data: { label: string; value: number }[];
  height?: number;
}) {
  if (data.length === 0) return null;

  const barSlot = 30;
  const barWidth = 16;
  const labelH = 18;
  const plotH = height - labelH;
  const width = data.length * barSlot;

  const maxPos = Math.max(0, ...data.map((d) => d.value));
  const maxNeg = Math.max(0, ...data.map((d) => -d.value));
  const span = maxPos + maxNeg || 1;
  const zeroY = (maxPos / span) * plotH;

  return (
    <div className="overflow-x-auto bl-no-scrollbar">
      <svg width={width} height={height} style={{ display: 'block', minWidth: '100%' }}>
        <defs>
          <linearGradient id="bl-bar-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--bl-accent)" />
            <stop offset="100%" stopColor="var(--bl-accent)" stopOpacity="0.55" />
          </linearGradient>
        </defs>
        {data.map((d, i) => {
          const x = i * barSlot + (barSlot - barWidth) / 2;
          const h = (Math.abs(d.value) / span) * plotH;
          const y = d.value >= 0 ? zeroY - h : zeroY;
          return (
            <g key={i}>
              <rect
                x={x}
                y={Math.max(0, y)}
                width={barWidth}
                height={Math.max(2, h)}
                rx={4}
                fill={d.value < 0 ? 'var(--bl-red)' : 'url(#bl-bar-grad)'}
              />
              <text
                x={i * barSlot + barSlot / 2}
                y={height - 5}
                textAnchor="middle"
                className="fill-bl-tertiary-label"
                style={{ fontSize: 10 }}
              >
                {d.label}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}
