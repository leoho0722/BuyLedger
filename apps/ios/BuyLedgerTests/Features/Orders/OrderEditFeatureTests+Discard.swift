//
//  OrderEditFeatureTests+Discard.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 草稿有變更時按取消，先詢問是否捨棄，不直接關閉表單
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

    /// 確認捨棄未儲存變更時關閉表單
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

    /// 沒改過任何欄位時按取消，不詢問就關閉表單
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
