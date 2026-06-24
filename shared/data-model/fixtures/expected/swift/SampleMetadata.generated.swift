//
//  SampleMetadata.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例 metadata (不列任何 trait，驗證 Swift 全域 Sendable 注入)
struct SampleMetadata: Sendable {

    // MARK: - Data Properties

    /// 鍵
    let key: String

    /// 值
    let value: String
}
