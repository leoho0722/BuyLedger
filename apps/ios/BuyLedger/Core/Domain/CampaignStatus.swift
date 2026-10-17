//
//  CampaignStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

// MARK: - Computed Properties

extension CampaignStatus {

    /// 顯示在介面中的狀態名稱
    var title: String {
        switch self {
        case .ongoing:
            "common.general.label.active"
        case .closed:
            "common.general.label.closed"
        }
    }
}
