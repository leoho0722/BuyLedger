//
//  Money.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import type { CurrencyCode } from "./CurrencyCode";
type DecimalString = string;

/**
 * 帶有幣別的金額值。
 */
export interface Money {
  /**
   * 金額數值。
   */
  readonly amount: DecimalString;
  /**
   * 金額所屬幣別。
   */
  readonly currency: CurrencyCode;
}
