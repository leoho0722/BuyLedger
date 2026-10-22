//
//  CampaignFeature+Path.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture

// MARK: - Nested Types

extension CampaignFeature {

    /// 開團導覽堆疊可推入的畫面
    @Reducer
    enum Path {

        /// 開團詳情
        ///
        /// - Parameter feature: 提供詳情內容並轉送操作請求的 Feature
        case detail(CampaignDetailFeature)
    }
}

// MARK: - Internal Method

extension StackState where Element == CampaignFeature.Path.State {

    /// 移除指向指定開團的詳情與其後的元素，其他元素的識別值維持不變
    ///
    /// - Parameter campaignID: 要移除詳情的開團識別值
    mutating func popDetail(campaignID: Campaign.ID) {
        let shownID = ids.first {
            self[id: $0]?.detail?.campaignID == campaignID
        }
        guard let shownID else {
            return
        }
        pop(from: shownID)
    }
}

// MARK: - Equatable

extension CampaignFeature.Path.State: Equatable {

}
