//
//  CampaignListFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture

@testable import BuyLedger

/// 提供開團列表測試共用的狀態建立操作
enum CampaignListFeatureTestSupport {}

// MARK: - Internal Method

extension CampaignListFeatureTestSupport {

    /// 以給定的開團與訂單建立列表狀態，兩者都以唯讀共享引用提供
    ///
    /// - Parameters:
    ///   - campaigns: 初始開團清單
    ///   - orders: 初始訂單投影
    /// - Returns: 尚未載入的列表狀態
    static func makeState(
        campaigns: [Campaign] = [],
        orders: [LedgerOrder] = []
    ) -> CampaignListFeature.State {
        CampaignListFeature.State(
            campaigns: SharedReader(value: campaigns),
            orders: SharedReader(value: orders)
        )
    }
}
