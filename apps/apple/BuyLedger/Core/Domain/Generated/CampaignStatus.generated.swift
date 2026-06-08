//
//  CampaignStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import Foundation

/// 開團在收單流程中的狀態。
///
/// 僅兩態：收單中與收單結束。「結團」是另外記錄結團日期 (settledDate) 的完成動作，不是狀態，因此不在此列。
enum CampaignStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 開團中，仍在收單。
    case ongoing

    /// 已收單，停止收單、進入後續處理。
    case closed

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)。
    var id: String { rawValue }
}
