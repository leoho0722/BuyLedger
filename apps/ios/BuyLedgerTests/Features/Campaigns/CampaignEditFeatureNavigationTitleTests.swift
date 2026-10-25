//
//  CampaignEditFeatureNavigationTitleTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `CampaignEditFeature.State` 的單元測試，涵蓋新增與編輯模式下的導覽列標題鍵
struct CampaignEditFeatureNavigationTitleTests {

    /// 驗證新增表單沒有原開團時，導覽列標題取新增開團的本地化 key
    @Test
    func navigationTitleKey_新增表單_回傳新增開團的鍵() {
        // Given
        let state = CampaignEditFeatureTestSupport.makeState(original: nil)

        // When
        let key = state.navigationTitleKey

        // Then
        #expect(key == "campaigns.list.label.addCampaign")
    }

    /// 驗證編輯表單帶有原開團時，導覽列標題取編輯開團的本地化 key
    @Test
    func navigationTitleKey_編輯表單_回傳編輯開團的鍵() {
        // Given
        let state = CampaignEditFeatureTestSupport.makeState(
            original: CampaignEditFeatureTestSupport.original
        )

        // When
        let key = state.navigationTitleKey

        // Then
        #expect(key == "campaigns.list.label.editCampaign")
    }
}
