// 客戶頭像：圓形、名稱雜湊決定漸層色、白色縮寫。
export function BLAvatar({
  name,
  initials,
  size = 36,
}: {
  name: string;
  initials: string;
  size?: number;
}) {
  const hue = hueForName(name);
  // HSB→HSL 近似 iOS 兩段漸層。
  const background = `linear-gradient(135deg, hsl(${hue}, 55%, 65%), hsl(${(hue + 40) % 360}, 36%, 50%))`;
  return (
    <div
      className="flex shrink-0 items-center justify-center rounded-full font-semibold text-white"
      style={{ width: size, height: size, background, fontSize: size * 0.38 }}
    >
      {initials}
    </div>
  );
}

function hueForName(name: string): number {
  let sum = 0;
  for (const ch of name) sum += ch.codePointAt(0) ?? 0;
  return sum % 360;
}
