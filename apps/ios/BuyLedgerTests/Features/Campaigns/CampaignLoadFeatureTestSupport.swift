//
//  CampaignLoadFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture

@testable import BuyLedger

/// 提供開團載入測試共用的狀態建立操作
enum CampaignLoadFeatureTestSupport {}

// MARK: - Internal Method

extension CampaignLoadFeatureTestSupport {

    /// 以給定的開團建立載入狀態，開團清單為獨立的共用引用
    ///
    /// - Parameter campaigns: 初始開團
    /// - Returns: 尚未開始載入的狀態
    static func makeState(campaigns: [Campaign] = []) -> CampaignLoadFeature.State {
        let shared = Shared<[Campaign]>(value: [])
        shared.withLock {
            $0 = campaigns
        }
        return CampaignLoadFeature.State(campaigns: shared)
    }
}
