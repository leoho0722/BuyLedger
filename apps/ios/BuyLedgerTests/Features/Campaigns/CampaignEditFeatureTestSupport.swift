//
//  CampaignEditFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/19.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供開團編輯測試共用的原開團與狀態建立操作
enum CampaignEditFeatureTestSupport {}

// MARK: - Computed Properties

extension CampaignEditFeatureTestSupport {

    /// 固定內容的原開團，供編輯與請求內容斷言使用
    static var original: Campaign {
        Campaign.fixture(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            status: .ongoing,
            notes: ""
        )
    }
}

// MARK: - Internal Method

extension CampaignEditFeatureTestSupport {

    /// 建立固定識別值與時間的表單狀態
    ///
    /// - Parameter original: 原開團；沒有時建立新增表單
    /// - Returns: 尚未修改的表單狀態
    static func makeState(original: Campaign? = nil) -> CampaignEditFeature.State {
        CampaignEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: Date(timeIntervalSince1970: 0),
            reminderTimestamp: Date(timeIntervalSince1970: 0)
        )
    }
}
