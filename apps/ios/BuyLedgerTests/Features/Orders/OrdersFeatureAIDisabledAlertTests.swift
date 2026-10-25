//
//  OrdersFeatureAIDisabledAlertTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證 AI 摘要未啟用提示按下前往設定後的流程
@MainActor
struct OrdersFeatureAIDisabledAlertTests {

    /// 驗證 AI 摘要未啟用的提示按下前往設定時，提示框關閉，且開啟設定的請求只向上通知一次
    @Test
    func presentation_點選前往設定_送出開啟設定委派() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = .alert(
            AlertState {
                TextState("orders.general.label.aiItemSummary")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("common.action.label.close")
                }
                ButtonState(action: .goToAISettings) {
                    TextState("orders.general.label.openSettings2")
                }
            } message: {
                TextState("orders.general.message.enableAiItem")
            }
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.presentation(.destination(.presented(.alert(.goToAISettings))))) {
            $0.presentation.destination = nil
        }

        // Then
        await store.receive(\.presentation.delegate.aiSettingsRequested)
        await store.receive(\.delegate.aiSettingsRequested)
        await store.finish()
        #expect(store.state.presentation.destination?.alert == nil)
    }
}
