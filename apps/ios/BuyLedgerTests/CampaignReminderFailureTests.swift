//
//  CampaignReminderFailureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 行事曆提醒的失敗路徑分流
///
/// 只有「權限請求本身回報未獲授權」才走權限說明；權限已授予後的失敗一律走建立失敗路徑，
/// 訊息不得要使用者去改一個已經給了的權限
@MainActor
struct CampaignReminderFailureTests {

    // MARK: - Nested Types

    /// 測試用的建立失敗
    private enum ReminderTestFailure: Error {

        // MARK: - Cases

        /// 模擬事件儲存或連結寫入拋錯
        case boom
    }

    // MARK: - Tests

    @Test func accessNotGrantedRoutesToThePermissionPath() async {
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { false }
        }

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderAccessDenied)

        #expect(store.state.reminderAccessAlert != nil)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    @Test func eventSaveFailureRoutesToTheCreationFailurePath() async {
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { true }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in
                throw ReminderTestFailure.boom
            }
        }

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderCreationFailed)

        #expect(store.state.reminderAccessAlert != nil)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    @Test func missingEventIdentifierRoutesToTheCreationFailurePath() async {
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { true }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in
                throw CalendarReminderClient.Failure.eventIdentifierMissing
            }
        }

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderCreationFailed)

        #expect(store.state.reminderAccessAlert != nil)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    @Test func linkPersistenceFailureRoutesToTheCreationFailurePath() async {
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { true }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in "EVT-new" }
            $0[CampaignReminderRepository.self].saveLink = { _, _, _ in
                throw ReminderTestFailure.boom
            }
        }

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderCreationFailed)

        #expect(store.state.reminderAccessAlert != nil)
        // 事件建立成功但連結寫入失敗時不得留下部分寫入的連結
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 權限提示的「前往設定」以注入的相依開啟系統設定
    @Test func openSettingsButtonInvokesTheInjectedDependency() async {
        let opened = OpenedBox()
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { false }
            $0[OpenSettingsClient.self].open = { opened.value = true }
        }

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderAccessDenied)
        await store.send(.reminderAccessAlert(.presented(.openSettings)))
        await store.finish()

        #expect(opened.value)
    }

    /// 移除不存在的事件維持「視為無操作、不報錯」，不因錯誤路徑拆分而改變
    @Test func removingAnAbsentEventRemainsANoOp() async {
        var initial = CampaignFeature.State()
        initial.reminderLinks[Self.campaignID] = CampaignReminderLink(
            eventIdentifier: "EVT-gone",
            reminderTimestamp: TestDependencies.fixedNow
        )
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CalendarReminderClient.self].removeReminder = { _ in
                throw ReminderTestFailure.boom
            }
            $0[CampaignReminderRepository.self].removeLink = { _ in }
        }
        store.exhaustivity = .off

        await store.send(.reminderStored(Self.campaignID, nil))

        #expect(store.state.reminderLinks[Self.campaignID] == nil)
        #expect(store.state.reminderAccessAlert == nil)
    }
}

// MARK: - Private Method

private extension CampaignReminderFailureTests {

    /// 測試共用的開團識別值
    static let campaignID = "11111111-1111-1111-1111-111111111111"

    /// 建立一個「儲存新開團並要求建立提醒」的 store
    /// - Parameter dependencies: 依測試情境覆寫的相依
    /// - Returns: 已設定初始編輯狀態的 TestStore
    static func makeStore(
        _ dependencies: @escaping (inout DependencyValues) -> Void
    ) -> TestStoreOf<CampaignFeature> {
        let newID = UUID(uuidString: campaignID)!
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow.addingTimeInterval(18 * 3600)
        )
        editState.draftName = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0[CampaignRepository.self].saveCampaign = { _ in }
            dependencies(&$0)
        }
        store.exhaustivity = .off
        return store
    }
}

/// 記錄開啟系統設定是否被呼叫
private final class OpenedBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 是否已被呼叫
    var value = false
}
