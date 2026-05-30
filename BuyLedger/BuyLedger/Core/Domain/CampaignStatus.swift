//
//  CampaignStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 開團 (Campaign) 在收單流程中的狀態。
///
/// 僅兩態：收單中與收單結束。「結團」是另外記錄 ``Campaign/settledDate`` 的完成動作，不是狀態，因此不在此列。
enum CampaignStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 開團中，仍在收單。
    case ongoing

    /// 已收單，停止收單、進入後續處理。
    case closed

    // MARK: - Identifiable Properties

    /// 狀態的穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在介面中的狀態名稱。
    var title: String {
        switch self {
        case .ongoing:
            "開團中"
        case .closed:
            "已收單"
        }
    }
}
