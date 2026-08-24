//
//  SampleProfile.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

/**
 * 範例側寫 (示範 value-equality 與 serializable 併用、不含 identity 的 entity trait 組合)
 */
export interface SampleProfile {
  /**
   * 顯示名稱
   */
  readonly name: string;
  /**
   * 備註
   */
  readonly note: string;
}
