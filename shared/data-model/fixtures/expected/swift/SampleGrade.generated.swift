//
//  SampleGrade.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例等級 (示範僅 serializable、不含 case-iterable 與 identity 的 enum trait 組合)
enum SampleGrade: String, Codable, Sendable {

    // MARK: - Cases

    /// 基本等級
    case basic

    /// 進階等級
    case premium
}
