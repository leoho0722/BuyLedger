//
//  SampleTag.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例標籤 (示範 wrapper + 自訂序列化 + identity)
struct SampleTag: Hashable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 包裝的原始值
    let rawValue: String

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)
    var id: String { rawValue }
}
