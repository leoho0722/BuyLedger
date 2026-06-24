//
//  SampleOrder.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例訂單 (示範型別映射、nullable 與 default 規則)
///
/// 涵蓋基礎型別、容器、跨檔引用，以及顯式 init 為 nullable 欄位補 nil 的路徑
struct SampleOrder: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 穩定識別值
    let id: String

    /// 標題；可變
    var title: String

    /// 數量；預設 0
    var quantity: Int

    /// 目前狀態；預設 active
    let status: SampleStatus

    /// 標籤清單；預設空陣列
    let tags: [SampleTag]

    /// 匯率 (非 nullable、無 default — 必填參數)
    let rate: Decimal

    /// 建立時間
    let createdAt: Date

    /// 結束時間；nullable 且無 default，顯式 init 應補 = nil
    let closeDate: Date?

    /// 二進位附載；nullable
    let payload: Data?

    /// 項目識別值；計算 default $newUUID
    let itemId: UUID

    /// 各標籤對應的費率
    let rates: [SampleTag: Decimal]

    // MARK: - Init

    /// 建立 SampleOrder
    init(
        id: String,
        title: String,
        quantity: Int = 0,
        status: SampleStatus = .active,
        tags: [SampleTag] = [],
        rate: Decimal,
        createdAt: Date,
        closeDate: Date? = nil,
        payload: Data? = nil,
        itemId: UUID = UUID(),
        rates: [SampleTag: Decimal]
    ) {
        self.id = id
        self.title = title
        self.quantity = quantity
        self.status = status
        self.tags = tags
        self.rate = rate
        self.createdAt = createdAt
        self.closeDate = closeDate
        self.payload = payload
        self.itemId = itemId
        self.rates = rates
    }
}
