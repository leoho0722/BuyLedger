//
//  MoreFeatureTests+Relays.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension MoreFeatureTests {

    /// 客戶頁出現時的載入要求原樣轉送，不直接載入或更改投影
    @Test
    func path_客戶頁要求載入訂單_轉送委派() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        initial.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.$orders)))
        )
        let store = TestStore(initialState: initial) {
            MoreFeature()
        }

        // When
        await store.send(.path(.element(id: 0, action: .customers(.view(.task)))))

        // Then
        await store.receive(\.path[id: 0].customers.delegate.ordersLoadRequested)
        await store.receive(\.delegate.ordersLoadRequested)
        await store.finish()
        #expect(store.state.path.count == 1)
    }

    /// 客戶選取先清空整個堆疊，才向根功能交出跨分頁意圖
    @Test
    func path_客戶頁選取客戶_清空堆疊並轉送委派() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        initial.path.append(.fx(FxFeature.State()))
        initial.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.$orders)))
        )
        let store = TestStore(initialState: initial) {
            MoreFeature()
        }

        // When
        await store.send(
            .path(.element(id: 1, action: .customers(.view(.customerTapped("Alice")))))
        )

        // Then
        await store.receive(\.path[id: 1].customers.delegate.customerSelected, "Alice") {
            $0.path.removeAll()
        }
        await store.receive(\.delegate.customerSelected, "Alice")
        await store.finish()
        #expect(store.state.path.isEmpty)
    }

    /// 主檔改名委派附上來源頁的種類，讓根功能只改對應的訂單欄位
    @Test
    func path_主檔改名_帶種類轉送委派() async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = MoreFeature.State(appVersion: "1.7.0")
            state.path.append(.lookupManagement(LookupManagementFeature.State(kind: .category)))
            return state
        }
        let store = TestStore(initialState: initial) {
            MoreFeature()
        }
        let rename = LookupItemRename(oldName: "美妝", newName: "彩妝")

        // When
        await store.send(
            .path(.element(id: 0, action: .lookupManagement(.delegate(.itemRenamed(rename)))))
        )

        // Then
        await store.receive(\.delegate, .lookupItemRenamed(kind: .category, rename: rename))
        await store.finish()
        #expect(store.state.path[id: 0, case: \.lookupManagement]?.kind == .category)
    }

    /// 付款方式更正完成後轉送同一份 `plan`，不重算也不呼叫訂單寫入
    @Test
    func path_付款方式更正完成_轉送委派() async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = MoreFeature.State(appVersion: "1.7.0")
            state.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .paymentMethod))
            )
            return state
        }
        let store = TestStore(initialState: initial) {
            MoreFeature()
        }
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "orders.edit.label.bankTransfer",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [LedgerOrder.fixture(id: "PM-1", paymentMethod: "orders.edit.label.bankTransfer")]
        )

        // When
        await store.send(
            .path(.element(id: 0, action: .lookupManagement(.delegate(.paymentMethodEdited(plan)))))
        )

        // Then
        await store.receive(\.delegate.paymentMethodEdited, plan)
        await store.finish()
        #expect(store.state.path.count == 1)
    }

    /// 設定頁保存後轉送完整偏好，更多頁投影仍由根功能同步
    @Test
    func path_設定變更_轉送偏好委派() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        initial.path.append(.settings(SettingsFeature.State()))
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let expected = SettingsSnapshot(
            language: .english,
            defaultCurrency: .twd,
            monthlyProfitGoalTWD: 80_000,
            isAISummaryEnabled: false,
            aiSummaryModel: "gemma4:31b-cloud",
            isBiometricUnlockEnabled: false
        )
        let store = TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .path(.element(id: 0, action: .settings(.binding(.set(\.language, .english)))))
        ) {
            $0.path[id: 0, case: \.settings]?.language = .english
        }

        // Then
        await store.receive(\.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.delegate.preferencesChanged, expected)
        await store.finish()
        #expect(saved.value == [expected])
        #expect(store.state.preferences.language == .traditionalChinese)
    }
}
