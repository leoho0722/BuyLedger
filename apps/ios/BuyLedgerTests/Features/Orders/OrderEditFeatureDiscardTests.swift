//
//  OrderEditFeatureDiscardTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋取消時依草稿變更決定詢問捨棄或直接關閉
@MainActor
struct OrderEditFeatureDiscardTests {

    /// 驗證草稿有變更時按下取消，呈現捨棄確認的提示框，表單不直接關閉
    ///
    /// - Note: 不覆寫 `dismiss`，若誤呼叫，TCA 預設的 `DismissEffect` 測試替身會回報 issue
    @Test
    func cancelTapped_草稿已有變更_呈現捨棄確認() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.customerName = "小明"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.view(.cancelTapped)) {
            $0.discardConfirmation = AlertState {
                TextState("orders.list.label.discardChanges")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("orders.list.label.discardChanges")
                }
                ButtonState(role: .cancel) {
                    TextState("orders.list.label.keepEditing")
                }
            } message: {
                TextState("orders.edit.message.orderHasUnsaved")
            }
        }

        // Then
        #expect(store.state.discardConfirmation != nil)
    }

    /// 驗證在捨棄確認框選擇捨棄後，清空確認框並以 `dismiss` 關閉表單，且只呼叫一次
    @Test
    func discardConfirmation_選擇捨棄_關閉表單() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.discardConfirmation = AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
        }
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
        }

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 1)
    }

    /// 驗證草稿沒有變更時按下取消，不呈現確認框，直接以 `dismiss` 關閉表單
    @Test
    func cancelTapped_草稿沒有變更_直接關閉畫面() async {
        // Given
        let dismissCallCount = LockIsolated(0)
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.cancelTapped))

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 1)
    }
}
