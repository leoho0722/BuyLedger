//
//  SampleReceipt.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

/**
 * 範例收據 (示範自訂序列化的實體，以及字串與布林欄位預設值)
 */
export interface SampleReceipt {
  /**
   * 穩定識別值
   */
  readonly id: string;
  /**
   * 備註；預設空字串
   */
  readonly memo: string;
  /**
   * 是否已作廢；預設 false
   */
  readonly isVoided: boolean;
}
