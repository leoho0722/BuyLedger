//
//  CampaignEditFeatureNavigationTitleTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignEditFeature.State` 的單元測試，涵蓋新增與編輯模式下的導覽列標題鍵
struct CampaignEditFeatureNavigationTitleTests {

    /// 驗證新增表單沒有原開團時，導覽列標題取新增開團的本地化 key，兩種 App 語言解析出各自的完整文字
    @Test
    func navigationTitleKey_新增表單_回傳新增開團的鍵() {
        // Given
        let state = CampaignEditFeatureTestSupport.makeState(original: nil)

        // When
        let title = state.navigationTitleKey

        // Then
        #expect(title.key == "campaigns.list.label.addCampaign")
        #expect(AppLanguage.traditionalChinese.resolve(title) == "新增開團")
        #expect(AppLanguage.english.resolve(title) == "Add Campaign")
    }

    /// 驗證編輯表單帶有原開團時，導覽列標題取編輯開團的本地化 key，兩種 App 語言解析出各自的完整文字
    @Test
    func navigationTitleKey_編輯表單_回傳編輯開團的鍵() {
        // Given
        let state = CampaignEditFeatureTestSupport.makeState(
            original: CampaignEditFeatureTestSupport.original
        )

        // When
        let title = state.navigationTitleKey

        // Then
        #expect(title.key == "campaigns.list.label.editCampaign")
        #expect(AppLanguage.traditionalChinese.resolve(title) == "編輯開團")
        #expect(AppLanguage.english.resolve(title) == "Edit Campaign")
    }
}
