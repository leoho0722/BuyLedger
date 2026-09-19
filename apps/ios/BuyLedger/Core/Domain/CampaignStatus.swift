//
//  CampaignStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/05/30.
//

import Foundation

// MARK: - Computed Properties

extension CampaignStatus {

    /// 顯示在介面中的狀態名稱
    var title: String {
        switch self {
        case .ongoing:
            "開團中"
        case .closed:
            "已收單"
        }
    }
}
