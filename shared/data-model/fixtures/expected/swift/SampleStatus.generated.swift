//
//  SampleStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import Foundation

/// 範例狀態 (示範 enum + identity + case-iterable)。
enum SampleStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 進行中。
    case active

    /// 已封存。
    case archived

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)。
    var id: String { rawValue }
}
