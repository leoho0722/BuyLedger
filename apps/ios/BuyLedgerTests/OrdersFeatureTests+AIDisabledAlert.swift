//
//  OrdersFeatureTests+AIDisabledAlert.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// AI 總結停用時選擇前往設定，關閉提示並只送出一次開啟設定委派
    @Test
    func aiDisabledAlert_點選前往設定_送出開啟設定委派() async {
        // Given
        var initial = OrdersFeature.State()
        initial.aiDisabledAlert = AlertState {
            TextState("AI 商品明細總結")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
            ButtonState(action: .goToAISettings) {
                TextState("前往開啟")
            }
        } message: {
            TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.aiDisabledAlert(.presented(.goToAISettings))) {
            $0.aiDisabledAlert = nil
        }

        // Then
        await store.receive(\.delegate.aiSettingsRequested)
        await store.finish()
        #expect(store.state.aiDisabledAlert == nil)
    }
}
