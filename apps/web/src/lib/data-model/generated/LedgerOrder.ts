//
//  LedgerOrder.ts
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import type { CurrencyCode } from "./CurrencyCode";
import type { LedgerCustomer } from "./LedgerCustomer";
import type { LedgerOrderItem } from "./LedgerOrderItem";
import type { OrderStatus } from "./OrderStatus";
import type { PaymentReceiptStatus } from "./PaymentReceiptStatus";
type Base64String = string;
type DecimalString = string;
type ISODateString = string;

/**
 * 用於列表、詳情與彙總的訂單資料
 */
export interface LedgerOrder {
  /**
   * 訂單編號
   */
  readonly id: string;
  /**
   * 訂單客戶
   */
  readonly customer: LedgerCustomer;
  /**
   * 訂單目前狀態
   */
  readonly status: OrderStatus;
  /**
   * 商品原始幣別
   */
  readonly currency: CurrencyCode;
  /**
   * 訂單建立或更新日期
   */
  readonly date: ISODateString;
  /**
   * 訂單商品項目
   */
  readonly items: LedgerOrderItem[];
  /**
   * 商品折合新台幣後的成本
   */
  readonly itemCost: DecimalString;
  /**
   * 國內運費成本
   */
  readonly domesticShipping: DecimalString;
  /**
   * 國際運費成本
   */
  readonly internationalShipping: DecimalString;
  /**
   * 商品來源國當地的「國內運費」成本 (折合 TWD)。例如賣家把商品從來源國國內出貨到集運倉的運送費
   */
  readonly foreignDomesticShipping: DecimalString;
  /**
   * 刷卡手續費比例
   */
  readonly cardFeeRate: DecimalString;
  /**
   * 平台手續費比例
   */
  readonly platformFeeRate: DecimalString;
  /**
   * 金流手續費比例 (0–1，例如 0.005 = 0.5%)；用於信用卡之外的第三方金流抽成
   */
  readonly paymentFeeRate: DecimalString;
  /**
   * 實際向客戶收款的新台幣金額
   */
  readonly chargedAmount: DecimalString;
  /**
   * 無卡折抵金額 (TWD)
   *
   * 用於「無卡」類付款方式紀錄客戶以儲值金、購物金等方式折抵的金額；折抵會從收益中扣除。非無卡訂單一律以 0 帶入
   */
  readonly cardlessDeductionAmount: DecimalString;
  /**
   * 無卡補款金額 (TWD)
   *
   * 用於「無卡」類付款方式紀錄客戶以轉帳等方式補繳的金額；補款會加到收益中。非無卡訂單一律以 0 帶入
   */
  readonly cardlessSupplementAmount: DecimalString;
  /**
   * 訂單來源
   */
  readonly orderSource: string;
  /**
   * 商品類別 (至少一個)
   *
   * 多個類別僅會由「合併訂單」產生 (聯集兩筆來源訂單的類別)；一般訂單編輯維持單選、儲存為單元素陣列
   */
  readonly categories: string[];
  /**
   * 付款方式
   */
  readonly paymentMethod: string;
  /**
   * 訂單備註；選填，無備註時為空字串
   */
  readonly notes: string;
  /**
   * 對帳狀態
   *
   * 僅在付款方式屬於無卡或銀行匯款 (款項不會即時入帳、需事後人工對帳) 時有意義；其他付款方式一律以空字串帶入。其值對應一份可自訂的對帳狀態清單
   */
  readonly verificationStatus: string;
  /**
   * 歸屬的開團名稱清單
   *
   * 沿用 orderSource 的字串名稱引用模式；空陣列代表未歸屬任何開團 (散單)。多個開團僅會由「合併訂單」產生。開團改名時統一 cascade 更新所有相符訂單 (陣列內逐元素取代)
   */
  readonly campaignNames: string[];
  /**
   * 收款狀態 (待收款／已收款)
   *
   * 作為開團分貨清單與結團結算判定「已收款」的唯一來源；對所有付款方式皆有意義，預設為待收款 (pending)
   */
  readonly paymentReceiptStatus: PaymentReceiptStatus;
  /**
   * 此訂單是否以「貨到付款」類付款方式成立
   *
   * 於儲存時依選到的付款方式之貨到付款旗標快照寫入 (與無卡欄位同樣為 data-driven，收益計算只依本型別欄位、不需另外查付款方式主檔)。為 true 時，因收款金額已含預估的三種運費，收益計算會額外扣除 domesticShipping + internationalShipping + foreignDomesticShipping；非貨到付款一律為 false
   */
  readonly isCashOnDelivery: boolean;
  /**
   * 訂單照片 (已正規化的 JPEG 位元組)
   *
   * 每張照片於匯入時經降採樣與重編碼後存入；張數有上限，由編輯流程守門。無照片時為空陣列
   */
  readonly photos: Base64String[];
  /**
   * 合併來源訂單編號
   *
   * 由「合併訂單」產生的新訂單記錄兩筆來源訂單的 id，作為統計歸屬 (採合併前收益) 與鏈式合併判定的依據；非合併產生的訂單一律為空陣列 (即「葉端訂單」)
   */
  readonly mergedSourceIDs: string[];
}
