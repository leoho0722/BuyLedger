// 走勢線：圓角線條 + 線色 16% 區域填色
export function BLSparkline({
  values,
  width = 240,
  height = 40,
  stroke = 'var(--bl-green)',
}: {
  values: number[];
  width?: number;
  height?: number;
  stroke?: string;
}) {
  if (values.length < 2) return <div style={{ height }} />;

  const inset = 2;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = max - min || 1;
  const stepX = width / (values.length - 1);
  const points = values.map((v, i) => {
    const x = i * stepX;
    const y = inset + (1 - (v - min) / span) * (height - inset * 2);
    return [x, y] as const;
  });

  const line = points.map(([x, y]) => `${x},${y}`).join(' ');
  const area = `M ${points[0][0]},${height} L ${line.split(' ').join(' L ')} L ${points[points.length - 1][0]},${height} Z`;

  return (
    <svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">
      <path d={area} fill={stroke} fillOpacity={0.16} />
      <polyline
        points={line}
        fill="none"
        stroke={stroke}
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
