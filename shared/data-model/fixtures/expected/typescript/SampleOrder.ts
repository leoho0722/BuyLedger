//
//  SampleOrder.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import type { SampleStatus } from "./SampleStatus";
import type { SampleTag } from "./SampleTag";
type Base64String = string;
type DecimalString = string;
type ISODateString = string;
type UUIDString = string;

/**
 * 範例訂單 (示範型別映射、nullable 與 default 規則)
 *
 * 涵蓋基礎型別、容器、跨檔引用，以及顯式 init 為 nullable 欄位補 nil 的路徑
 */
export interface SampleOrder {
  /**
   * 穩定識別值
   */
  readonly id: string;
  /**
   * 標題；可變
   */
  readonly title: string;
  /**
   * 數量；預設 0
   */
  readonly quantity: number;
  /**
   * 目前狀態；預設 active
   */
  readonly status: SampleStatus;
  /**
   * 標籤清單；預設空陣列
   */
  readonly tags: SampleTag[];
  /**
   * 匯率 (非 nullable、無 default — 必填參數)
   */
  readonly rate: DecimalString;
  /**
   * 建立時間
   */
  readonly createdAt: ISODateString;
  /**
   * 結束時間；nullable 且無 default，顯式 init 應補 = nil
   */
  readonly closeDate?: ISODateString | null;
  /**
   * 二進位附載；nullable
   */
  readonly payload?: Base64String | null;
  /**
   * 項目識別值；計算 default $newUUID
   */
  readonly itemId: UUIDString;
  /**
   * 各標籤對應的費率
   */
  readonly rates: Record<SampleTag, DecimalString>;
}
