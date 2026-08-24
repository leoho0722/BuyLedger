//
//  SampleQuote.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

type DecimalString = string;

/**
 * 範例報價 (示範僅 value-equality、不含其他 trait 的 entity trait 組合)
 */
export interface SampleQuote {
  /**
   * 報價標籤
   */
  readonly label: string;
  /**
   * 報價金額
   */
  readonly amount: DecimalString;
}
