//
//  CampaignStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 開團是否仍在收單
enum CampaignStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 仍在收單
    case ongoing

    /// 已停止收單
    case closed

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)
    var id: String { rawValue }
}
