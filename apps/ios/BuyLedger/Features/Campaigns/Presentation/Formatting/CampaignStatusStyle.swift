//
//  CampaignStatusStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

/// 開團狀態對應的視覺語意
enum CampaignStatusStyle {}

// MARK: - Internal Method

extension CampaignStatusStyle {

    /// 取得開團狀態對應的 ``BLTone``
    ///
    /// - Parameter status: 開團狀態
    /// - Returns: 狀態膠囊使用的語意色調
    static func tone(for status: CampaignStatus) -> BLTone {
        switch status {
        case .ongoing:
            .accent

        case .closed:
            .neutral
        }
    }
}
