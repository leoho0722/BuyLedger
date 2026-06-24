// 顯示格式化工具 (locale 一律 zh-TW，對齊 iOS)。金額預設 0 小數

const LOCALE = 'zh-TW';

export function formatCurrency(value: string | number, code = 'TWD'): string {
  const n = typeof value === 'number' ? value : Number(value);
  return new Intl.NumberFormat(LOCALE, {
    style: 'currency',
    currency: code,
    maximumFractionDigits: 0,
    minimumFractionDigits: 0,
  }).format(Number.isFinite(n) ? n : 0);
}

export function formatTWD(value: string | number): string {
  return formatCurrency(value, 'TWD');
}

// 帶正負號的 TWD (正值補 +)，用於獲利
export function formatSignedTWD(value: string | number): string {
  const n = typeof value === 'number' ? value : Number(value);
  const formatted = formatTWD(Math.abs(n));
  if (n > 0) return `+${formatted}`;
  if (n < 0) return `-${formatted}`;
  return formatted;
}

// 比例值 (0–1) → 百分比字串
export function formatPercent(ratio: string | number, fractionDigits = 1): string {
  const n = typeof ratio === 'number' ? ratio : Number(ratio);
  return new Intl.NumberFormat(LOCALE, {
    style: 'percent',
    maximumFractionDigits: fractionDigits,
    minimumFractionDigits: fractionDigits,
  }).format(Number.isFinite(n) ? n : 0);
}

export function formatProgressPercent(ratio: number): string {
  return formatPercent(ratio, 0);
}

export function formatRate(value: string | number, fractionDigits = 4): string {
  const n = typeof value === 'number' ? value : Number(value);
  return new Intl.NumberFormat(LOCALE, {
    maximumFractionDigits: fractionDigits,
  }).format(Number.isFinite(n) ? n : 0);
}

export function formatNumber(value: string | number, fractionDigits = 0): string {
  const n = typeof value === 'number' ? value : Number(value);
  return new Intl.NumberFormat(LOCALE, {
    maximumFractionDigits: fractionDigits,
  }).format(Number.isFinite(n) ? n : 0);
}

// M月d日 (列表短日期)
export function formatShortDate(iso: string): string {
  return new Intl.DateTimeFormat(LOCALE, { month: 'numeric', day: 'numeric' }).format(new Date(iso));
}

// M月d日 週X
export function formatDayWeekday(iso: string): string {
  const d = new Date(iso);
  const day = new Intl.DateTimeFormat(LOCALE, { month: 'numeric', day: 'numeric' }).format(d);
  const weekday = new Intl.DateTimeFormat(LOCALE, { weekday: 'short' }).format(d);
  return `${day} ${weekday}`;
}

// 區段標題 (相對今天/昨天，同年顯示 M月d日 週X，跨年顯示 yyyy年M月d日)
export function formatSectionDate(iso: string, now: Date): string {
  const d = new Date(iso);
  const startOf = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const dayDiff = Math.round((startOf(now) - startOf(d)) / 86_400_000);
  if (dayDiff === 0) return '今天';
  if (dayDiff === 1) return '昨天';
  if (d.getFullYear() === now.getFullYear()) {
    const day = new Intl.DateTimeFormat(LOCALE, { month: 'long', day: 'numeric' }).format(d);
    const weekday = new Intl.DateTimeFormat(LOCALE, { weekday: 'short' }).format(d);
    return `${day} ${weekday}`;
  }
  return new Intl.DateTimeFormat(LOCALE, { year: 'numeric', month: 'long', day: 'numeric' }).format(d);
}

export function formatFullTimestamp(iso: string): string {
  return new Intl.DateTimeFormat(LOCALE, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).format(new Date(iso));
}

// 月份區段標題 (yyyy年M月)
export function formatMonthLabel(year: number, month1: number): string {
  return `${year}年${month1}月`;
}
