import { Decimal } from 'decimal.js';

// 與後端一致：金額/比率彙總一律走 decimal.js。
Decimal.set({ precision: 40, rounding: Decimal.ROUND_HALF_UP });

export { Decimal };

export type DecimalInput = string | number | Decimal | null | undefined;

export function D(value: DecimalInput): Decimal {
  if (value === null || value === undefined || value === '') return new Decimal(0);
  return new Decimal(value);
}

// 字串金額加總。
export function sumDecimals(values: DecimalInput[]): Decimal {
  return values.reduce<Decimal>((acc, v) => acc.plus(D(v)), new Decimal(0));
}
