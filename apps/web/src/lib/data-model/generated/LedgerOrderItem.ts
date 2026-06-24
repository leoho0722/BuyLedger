//
//  LedgerOrderItem.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

type DecimalString = string;
type UUIDString = string;

/**
 * 訂單中的單一商品項目
 *
 * id 為穩定識別值，與 name / quantity / unitPrice 等內容欄位解耦，使內容變動時識別保持不變 (支援清單／表單內的逐項編輯)
 */
export interface LedgerOrderItem {
  /**
   * 商品項目的穩定識別值，與內容無關
   */
  readonly id: UUIDString;
  /**
   * 商品名稱
   */
  readonly name: string;
  /**
   * 商品數量
   */
  readonly quantity: number;
  /**
   * 商品在原始幣別中的單價
   */
  readonly unitPrice: DecimalString;
}
