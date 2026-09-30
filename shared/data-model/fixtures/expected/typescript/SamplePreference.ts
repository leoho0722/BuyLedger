//
//  SamplePreference.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

/**
 * 範例偏好設定 (示範 value-equality、hashable 與 serializable 併用的 entity trait 組合)
 */
export interface SamplePreference {
  /**
   * 偏好標籤
   */
  readonly label: string;
  /**
   * 是否啟用
   */
  readonly isEnabled: boolean;
}
