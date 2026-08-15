//
//  SampleReceipt.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例收據 (示範自訂序列化的實體，以及字串與布林欄位預設值)
struct SampleReceipt: Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 穩定識別值
    let id: String

    /// 備註；預設空字串
    let memo: String

    /// 是否已作廢；預設 false
    let isVoided: Bool

    // MARK: - Init

    /// 建立 SampleReceipt
    init(
        id: String,
        memo: String = "",
        isVoided: Bool = false
    ) {
        self.id = id
        self.memo = memo
        self.isVoided = isVoided
    }
}
