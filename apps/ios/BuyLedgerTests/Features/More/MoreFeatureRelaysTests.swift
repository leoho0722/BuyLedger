//
//  MoreFeatureRelaysTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `MoreFeature` 的單元測試，以 TestStore 驗證更多頁如何把子頁面的要求與結果轉給 Root
@MainActor
struct MoreFeatureRelaysTests {

    /// 驗證客戶頁出現時的載入要求原樣送給 Root，更多頁本身不載入資料，也不改動訂單投影
    @Test
    func path_客戶頁要求載入訂單_轉送委派() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        initial.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.$orders)))
        )
        let store = TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.path(.element(id: 0, action: .customers(.view(.task)))))

        // Then
        await store.receive(\.path[id: 0].customers.delegate.ordersLoadRequested)
        await store.receive(\.delegate.ordersLoadRequested)
        await store.finish()
        #expect(store.state.path.count == 1)
    }

    /// 驗證客戶頁選取客戶時，先清空整個更多頁堆疊，再把選取的客戶送給 Root
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
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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

    /// 驗證主檔改名時，送給 Root 的事件附上來源頁的主檔種類，讓 Root 只改對應的訂單欄位
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
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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

    /// 驗證付款方式更正完成後，原樣送出同一份 `plan`，不重算，也不呼叫訂單寫入
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
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "orders.edit.label.bankTransfer",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [
                LedgerOrder.fixture(id: "PM-1", paymentMethod: "orders.edit.label.bankTransfer"),
            ]
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

    /// 驗證設定頁保存後，更多頁把完整偏好送給 Root，自身的偏好欄位維持原值
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
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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

    /// 驗證 Root 要求主檔目錄載入時，更多頁把載入請求交給目錄功能，目錄已載入時仍回報完成
    @Test
    func catalogLoadRequested_目錄已載入_轉送載入與完成通知() async {
        // Given
        var initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            MoreFeature.State(appVersion: "1.7.0")
        }
        initial.catalog.hasLoaded = true
        let store = TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.catalogLoadRequested)

        // Then
        await store.receive(\.catalog.loadRequested)
        await store.receive(\.catalog.delegate, .loadFinished)
        await store.receive(\.delegate.catalogLoadFinished)
        await store.finish()
    }

    /// 驗證目錄功能完成載入後，更多頁通知 Root 完成，不直接要求訂單載入
    @Test
    func catalog_目錄載入完成_轉送完成委派() async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            MoreFeature.State(appVersion: "1.7.0")
        }
        let store = TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.catalog(.delegate(.loadFinished)))

        // Then
        await store.receive(\.delegate.catalogLoadFinished)
        await store.finish()
    }

    /// 驗證 Root 要求新增選項時，更多頁把請求交給主檔目錄寫入，成功後更新目錄，並原樣把請求與結果送回 Root
    @Test
    func optionAdditionRequested_寫入成功_轉送請求與原表單的結果() async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            MoreFeature.State(appVersion: "1.7.0")
        }
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(3),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { _, _ in
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }

        // When
        await store.send(.optionAdditionRequested(request))

        // Then
        await store.receive(\.catalog.additionRequested, request)
        release.continuation.finish()
        await store.receive(\.catalog.additionResponse) {
            $0.catalog.$catalog.withLock {
                $0.categories = ["香氛"]
            }
        }
        await store.receive(\.catalog.delegate, .additionCompleted(request, isStored: true))
        await store.receive(\.delegate, .optionAdditionCompleted(request, isStored: true))
        await store.finish()
    }

    /// 驗證主檔目錄回報新增完成時，成功與失敗的結果都原樣轉送，保留原表單的識別值與儲存旗標
    ///
    /// - Parameter isStored: 主檔端回報的儲存結果
    @Test(arguments: [false, true])
    func catalog_新增選項已完成_原樣轉送結果(isStored: Bool) async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            MoreFeature.State(appVersion: "1.7.0")
        }
        let request = LookupAdditionRequest(
            id: UUID(3),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.catalog(.delegate(.additionCompleted(request, isStored: isStored))))

        // Then
        await store.receive(\.delegate, .optionAdditionCompleted(request, isStored: isStored))
        await store.finish()
    }
}
