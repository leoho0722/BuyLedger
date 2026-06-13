import { Decimal } from 'decimal.js';

// 金額/比率運算統一走 decimal.js，避免浮點誤差。精度設高，半進位對齊一般財務慣例。
Decimal.set({ precision: 40, rounding: Decimal.ROUND_HALF_UP });

export { Decimal };

export type DecimalInput = string | number | Decimal | null | undefined;

/// 寬鬆建構：null/undefined 視為 0 (對齊 iOS「非無卡欄位以 0 帶入」等慣例)。
export function D(value: DecimalInput): Decimal {
  if (value === null || value === undefined || value === '') {
    return new Decimal(0);
  }
  return new Decimal(value);
}
