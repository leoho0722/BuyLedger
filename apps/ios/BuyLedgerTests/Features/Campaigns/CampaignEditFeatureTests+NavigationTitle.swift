//
//  CampaignEditFeatureTests+NavigationTitle.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignEditFeatureTests {

    /// 新增表單沒有原開團時，導覽標題使用新增開團的本地化 key
    @Test
    func navigationTitleKey_新增表單_回傳新增開團的鍵() {
        // Given
        let state = Self.makeState(original: nil)

        // When
        let key = state.navigationTitleKey

        // Then
        #expect(key == "campaigns.list.label.addCampaign")
    }

    /// 編輯表單帶有原開團時，導覽標題使用編輯開團的本地化 key
    @Test
    func navigationTitleKey_編輯表單_回傳編輯開團的鍵() {
        // Given
        let state = Self.makeState(original: Self.original)

        // When
        let key = state.navigationTitleKey

        // Then
        #expect(key == "campaigns.list.label.editCampaign")
    }
}
