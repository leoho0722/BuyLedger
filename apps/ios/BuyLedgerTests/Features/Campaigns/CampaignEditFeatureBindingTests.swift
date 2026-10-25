//
//  CampaignEditFeatureBindingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `CampaignEditFeature` 的單元測試，以 `Store` 與 `@Bindable` 走畫面實際的綁定路徑，涵蓋草稿更新與重名訊息的保留或清除
@MainActor
struct CampaignEditFeatureBindingTests {

    /// 驗證經畫面的 `@Bindable` 綁定改名時，草稿名稱更新，並清除已不再適用的重名訊息
    @Test
    func binding_經畫面綁定路徑修改名稱_更新草稿並清除重名訊息() {
        // Given
        let store = Self.makeConflictedStore()
        @Bindable var bindable = store

        // When
        $bindable.draftName.wrappedValue = "五月團"

        // Then
        #expect(store.draft.name == "五月團")
        #expect(store.nameConflictMessage == nil)
    }

    /// 驗證經畫面的 `@Bindable` 綁定切換提醒開關時，草稿的提醒開關更新，重名訊息保留
    @Test
    func binding_經畫面綁定路徑切換提醒_保留重名訊息() {
        // Given
        let store = Self.makeConflictedStore()
        @Bindable var bindable = store

        // When
        $bindable.draft.wantsReminder.wrappedValue = true

        // Then
        #expect(store.draft.wantsReminder)
        #expect(store.nameConflictMessage == "campaigns.edit.message.anotherCampaignAlready")
    }

    /// 驗證經畫面的 `@Bindable` 綁定修改日期時，草稿的開團日期更新，重名訊息保留
    @Test
    func binding_經畫面綁定路徑修改日期_保留重名訊息() {
        // Given
        let store = Self.makeConflictedStore()
        @Bindable var bindable = store
        let pickedDate = Date(timeIntervalSince1970: 86_400)

        // When
        $bindable.draft.openDate.wrappedValue = pickedDate

        // Then
        #expect(store.draft.openDate == Date(timeIntervalSince1970: 86_400))
        #expect(store.nameConflictMessage == "campaigns.edit.message.anotherCampaignAlready")
    }
}

// MARK: - Private Method

private extension CampaignEditFeatureBindingTests {

    /// 建立已帶有重名訊息的新增表單 store，由正式 reducer 處理畫面送出的綁定
    ///
    /// - Returns: 新增表單的 store，`nameConflictMessage` 為固定的重名訊息
    static func makeConflictedStore() -> StoreOf<CampaignEditFeature> {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
        return Store(initialState: state) {
            CampaignEditFeature()
        }
    }
}
