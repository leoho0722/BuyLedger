//
//  CampaignEditFeatureBindingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignEditFeature` 的單元測試，以 `TestStore` 送出畫面實際送出的 binding action，涵蓋草稿更新與重名訊息的保留或清除
@MainActor
struct CampaignEditFeatureBindingTests {

    /// 驗證表單修改名稱時，畫面送出 `draftName` 自己的 binding action，草稿名稱更新並清除已不再適用的重名訊息
    ///
    /// - Note: 畫面綁定 `$store.draftName`，這是可寫的 computed property，送出自己的 key path
    @Test
    func binding_修改名稱_更新草稿並清除重名訊息() async {
        // Given
        let store = TestStore(initialState: Self.makeConflictedState()) {
            CampaignEditFeature()
        }

        // When
        await store.send(\.binding.draftName, "五月團") {
            $0.draft.name = "五月團"
            $0.nameConflictMessage = nil
        }

        // Then
        #expect(store.state.draft.name == "五月團")
        #expect(store.state.nameConflictMessage == nil)
    }

    /// 驗證表單切換提醒開關時，畫面送出整份草稿的 binding action，草稿的提醒開關更新，重名訊息保留
    ///
    /// - Note: 畫面綁定 `$store.draft.wantsReminder`，巢狀欄位送出的是整個 `draft`
    @Test
    func binding_切換提醒_保留重名訊息() async {
        // Given
        let initial = Self.makeConflictedState()
        var editedDraft = initial.draft
        editedDraft.wantsReminder = true
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(\.binding.draft, editedDraft) {
            $0.draft.wantsReminder = true
        }

        // Then
        #expect(store.state.draft.wantsReminder)
        #expect(store.state.nameConflictMessage == "campaigns.edit.message.anotherCampaignAlready")
    }

    /// 驗證表單修改開團日期時，畫面送出整份草稿的 binding action，草稿的開團日期更新，重名訊息保留
    ///
    /// - Note: 畫面綁定 `$store.draft.openDate`，巢狀欄位送出的是整個 `draft`
    @Test
    func binding_修改日期_保留重名訊息() async {
        // Given
        let initial = Self.makeConflictedState()
        var editedDraft = initial.draft
        editedDraft.openDate = Date(timeIntervalSince1970: 86_400)
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(\.binding.draft, editedDraft) {
            $0.draft.openDate = Date(timeIntervalSince1970: 86_400)
        }

        // Then
        #expect(store.state.draft.openDate == Date(timeIntervalSince1970: 86_400))
        #expect(store.state.nameConflictMessage == "campaigns.edit.message.anotherCampaignAlready")
    }
}

// MARK: - Private Method

private extension CampaignEditFeatureBindingTests {

    /// 建立已帶有重名訊息的新增表單狀態
    ///
    /// - Returns: 新增表單的狀態，`nameConflictMessage` 為固定的重名訊息
    static func makeConflictedState() -> CampaignEditFeature.State {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
        return state
    }
}
