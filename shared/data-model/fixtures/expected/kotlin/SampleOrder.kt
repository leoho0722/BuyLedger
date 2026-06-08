//
//  SampleOrder.kt
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

package com.buyledger.datamodel

/**
 * 範例訂單 (示範型別映射、nullable 與 default 規則)。
 *
 * 涵蓋基礎型別、容器、跨檔引用，以及顯式 init 為 nullable 欄位補 nil 的路徑。
 */
data class SampleOrder(
    /**
     * 穩定識別值。
     */
    val id: String,
    /**
     * 標題；可變。
     */
    var title: String,
    /**
     * 數量；預設 0。
     */
    var quantity: Int = 0,
    /**
     * 目前狀態；預設 active。
     */
    val status: SampleStatus = SampleStatus.ACTIVE,
    /**
     * 標籤清單；預設空陣列。
     */
    val tags: List<SampleTag> = emptyList(),
    /**
     * 匯率 (非 nullable、無 default — 必填參數)。
     */
    val rate: java.math.BigDecimal,
    /**
     * 建立時間。
     */
    val createdAt: java.time.Instant,
    /**
     * 結束時間；nullable 且無 default，顯式 init 應補 = nil。
     */
    val closeDate: java.time.Instant? = null,
    /**
     * 二進位附載；nullable。
     */
    val payload: ByteArray? = null,
    /**
     * 項目識別值；計算 default $newUUID。
     */
    val itemId: java.util.UUID = java.util.UUID.randomUUID(),
    /**
     * 各標籤對應的費率。
     */
    val rates: Map<SampleTag, java.math.BigDecimal>
)
