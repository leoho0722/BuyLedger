//
//  OrdersPresentationFeatureDelegateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersPresentationFeature` 的單元測試，以 TestStore 逐步驗證表單與提示的操作如何送給上層功能
@MainActor
struct OrdersPresentationFeatureDelegateTests {

    /// 驗證表單請求存檔時，`delegate.saveRequested` 原樣帶著目前的表單狀態送給上層功能
    @Test
    func destination_表單請求存檔_轉送存檔請求() async {
        // Given
        let edit = OrdersPresentationFeatureTestSupport.editState()
        let initial = OrdersPresentationFeatureTestSupport.makeState(destination: .edit(edit))
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.edit(.delegate(.saveRequested)))))

        // Then
        await store.receive(\.delegate, .saveRequested(edit))
    }

    /// 驗證表單請求新增訂單來源「蝦皮」時，`optionAddRequested` 帶著表單的識別值、種類與名稱送給上層功能
    @Test
    func destination_表單請求新增選項_轉送帶表單識別值的寫入請求() async {
        // Given
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: .edit(OrdersPresentationFeatureTestSupport.editState())
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(
                .presented(
                    .edit(
                        .delegate(.addOptionRequested(kind: .orderSource, name: "蝦皮", flags: .none))
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.delegate,
            .optionAddRequested(
                LookupAdditionRequest(
                    id: UUID(0),
                    kind: .orderSource,
                    name: "蝦皮",
                    flags: .none
                )
            )
        )
    }

    /// 驗證合併候選完成時，主訂單、副訂單與保留的照片轉成 `mergeCandidatesCompleted` 送給上層功能，由上層計算合併草稿
    @Test
    func destination_合併候選完成_轉送合併候選完成() async {
        // Given
        let primary = LedgerOrder.fixture(id: "A")
        let secondary = LedgerOrder.fixture(id: "B")
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: OrdersPresentationFeatureTestSupport.mergeDestination()
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(
                .presented(
                    .merge(
                        .delegate(
                            .completed(primary: primary, secondary: secondary, keptPhotos: [])
                        )
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.delegate,
            .mergeCandidatesCompleted(primary: primary, secondary: secondary, keptPhotos: [])
        )
    }

    /// 驗證確認刪除時清空提示，並送出 `deleteConfirmed` 帶著要刪除的訂單 A 給上層功能
    @Test
    func destination_確認刪除_清空提示並轉送刪除訂單() async {
        // Given
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: Self.deleteAlert()
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmDelete("A"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate, .deleteConfirmed("A"))
    }

    /// 驗證點選前往設定時清空提示，並送出 `aiSettingsRequested` 給上層功能，要求開啟 AI 設定
    @Test
    func destination_前往開啟設定_清空提示並轉送設定請求() async {
        // Given
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: Self.aiSettingsAlert()
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.alert(.goToAISettings)))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate, .aiSettingsRequested)
    }
}

// MARK: - Private Method

private extension OrdersPresentationFeatureDelegateTests {

    /// 建立刪除訂單的確認提示，刪除按鈕帶入訂單識別值 A
    ///
    /// - Returns: 帶有確認刪除動作的提示目的地
    static func deleteAlert() -> OrdersPresentationFeature.Destination.State {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("orders.detail.label.deleteOrder")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete("A")) {
                    TextState("common.action.button.delete")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "orders.detail.message.deleteUndoneNotice",
                        defaultValue: "\("A")"
                    )
                )
            }
        )
    }

    /// 建立 AI 商品明細摘要未啟用的提示，前往開啟按鈕帶入設定動作
    ///
    /// - Returns: 帶有前往設定動作的提示目的地
    static func aiSettingsAlert() -> OrdersPresentationFeature.Destination.State {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
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
    }
}
