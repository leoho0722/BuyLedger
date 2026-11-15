//
//  CampaignStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 開團是否仍在收單
enum CampaignStatus: String, CaseIterable, Codable, Sendable {

    /// 仍在收單
    case ongoing

    /// 已停止收單
    case closed
}

// MARK: - Computed Properties

extension CampaignStatus {

    /// 顯示在介面中的狀態名稱
    var title: LocalizedStringResource {
        switch self {
        case .ongoing:
            "common.general.label.active"

        case .closed:
            "common.general.label.closed"
        }
    }
}

// MARK: - Identifiable

extension CampaignStatus: Identifiable {

    /// 穩定識別值，即實際保存的原始字串
    var id: String {
        rawValue
    }
}
