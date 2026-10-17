//
//  CampaignEditFeatureTests+Binding.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignEditFeatureTests {

    /// 經畫面使用的 `@Bindable` 綁定改名時，草稿名稱更新且過期的重名訊息被清除
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

    /// 經畫面使用的 `@Bindable` 綁定切換提醒開關與修改日期時，保留重名訊息
    @Test
    func binding_經畫面綁定路徑切換提醒與修改日期_保留重名訊息() {
        // Given
        let store = Self.makeConflictedStore()
        @Bindable var bindable = store
        let pickedDate = Date(timeIntervalSince1970: 86_400)

        // When
        $bindable.draft.wantsReminder.wrappedValue = true
        $bindable.draft.openDate.wrappedValue = pickedDate

        // Then
        #expect(store.draft.wantsReminder)
        #expect(store.draft.openDate == Date(timeIntervalSince1970: 86_400))
        #expect(store.nameConflictMessage == "campaigns.edit.message.anotherCampaignAlready")
    }
}

// MARK: - Private Method

private extension CampaignEditFeatureTests {

    /// 建立帶著父層寫回重名訊息的表單 store，走正式 reducer 與畫面相同的綁定路徑
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
