//
//  CampaignStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//
//  資料形狀 (cases、Identifiable) 由 Generated/CampaignStatus.generated.swift 產生；
//  本檔僅保留手寫業務邏輯。改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Display Properties

extension CampaignStatus {

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
