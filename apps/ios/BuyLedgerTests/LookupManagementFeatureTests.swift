//
//  LookupManagementFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證主檔目錄載入、表單操作與付款方式更正
@MainActor
struct LookupManagementFeatureTests {

    // MARK: - Tests

    /// 載入指定種類時只替換該目錄清單，並清除載入錯誤
    ///
    /// - Parameter kind: 要載入的主檔種類
    @Test(arguments: LookupKind.allCases)
    func task_指定查詢種類_載入對應項目(kind: LookupKind) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: kind)
            state.hasLoadFailed = true
            state.$catalog.withLock {
                $0.orderSources = ["舊來源"]
                $0.categories = ["舊類別"]
                $0.paymentMethods = [PaymentMethodInfo(name: "舊付款", flags: .none)]
                $0.reconciliationStatuses = ["舊狀態"]
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                switch kind {
                case .orderSource:
                    $0.orderSourceService.fetchOrderSources = {
                        ["新來源"]
                    }

                case .category:
                    $0.categoryService.fetchCategories = {
                        ["新類別"]
                    }

                case .paymentMethod:
                    $0.paymentMethodService.fetchPaymentMethodInfos = {
                        [
                            PaymentMethodInfo(
                                name: "新付款",
                                flags: PaymentMethodFlags(
                                    isCardless: true,
                                    isBankTransfer: false,
                                    isCashOnDelivery: false
                                )
                            ),
                        ]
                    }

                case .reconciliationStatus:
                    $0.reconciliationStatusService.fetchReconciliationStatuses = {
                        ["新狀態"]
                    }
                }
            }

            // When
            await store.send(.view(.task))

            // Then
            await store.receive(\.itemsResponse.success) {
                $0.hasLoaded = true
                $0.hasLoadFailed = false
                switch kind {
                case .orderSource:
                    $0.$catalog.withLock {
                        $0.orderSources = ["新來源"]
                    }

                case .category:
                    $0.$catalog.withLock {
                        $0.categories = ["新類別"]
                    }

                case .paymentMethod:
                    $0.$catalog.withLock {
                        $0.paymentMethods = [
                            PaymentMethodInfo(
                                name: "新付款",
                                flags: PaymentMethodFlags(
                                    isCardless: true,
                                    isBankTransfer: false,
                                    isCashOnDelivery: false
                                )
                            ),
                        ]
                    }

                case .reconciliationStatus:
                    $0.$catalog.withLock {
                        $0.reconciliationStatuses = ["新狀態"]
                    }
                }
            }
            await store.finish()
        }
    }

    /// 點擊新增時呈現符合目前主檔種類的表單
    ///
    /// - Parameter example: 主檔種類與表單分類狀態
    @Test(arguments: LookupAdditionExample.examples)
    func addButtonTapped_點擊新增_呈現對應表單(example: LookupAdditionExample) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let store = TestStore(initialState: LookupManagementFeature.State(kind: example.kind)) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.addButtonTapped)) {
                $0.destination = .add(
                    LookupAddFormFeature.State(hasClassification: example.hasClassification)
                )
            }

            // Then
            #expect(
                store.state.destination == .add(
                    LookupAddFormFeature.State(hasClassification: example.hasClassification)
                )
            )
            await store.finish()
        }
    }

    /// 新增表單修剪前後空白後將預期名稱與旗標寫入 service 和目錄
    ///
    /// - Parameter example: 主檔種類及該種類應寫入的付款方式旗標
    @Test(arguments: LookupAdditionExample.examples)
    func destination_新增名稱含前後空白_寫入修剪後名稱(example: LookupAdditionExample) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let writes = LockIsolated<[LookupItemAddition]>([])
            let submittedFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
            let expectedAddition = LookupItemAddition(name: "手作小物", flags: example.expectedFlags)
            var initialState = LookupManagementFeature.State(kind: example.kind)
            initialState.destination = .add(
                LookupAddFormFeature.State(hasClassification: example.hasClassification)
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                switch example.kind {
                case .orderSource:
                    $0.orderSourceService.addOrderSource = { name in
                        writes.withValue {
                            $0.append(LookupItemAddition(name: name, flags: .none))
                        }
                    }

                case .category:
                    $0.categoryService.addCategory = { name in
                        writes.withValue {
                            $0.append(LookupItemAddition(name: name, flags: .none))
                        }
                    }

                case .paymentMethod:
                    $0.paymentMethodService.addPaymentMethod = { name, flags in
                        writes.withValue {
                            $0.append(LookupItemAddition(name: name, flags: flags))
                        }
                    }

                case .reconciliationStatus:
                    $0.reconciliationStatusService.addReconciliationStatus = { name in
                        writes.withValue {
                            $0.append(LookupItemAddition(name: name, flags: .none))
                        }
                    }
                }
            }

            // When
            await store.send(
                .destination(
                    .presented(
                        .add(.view(.saveButtonTapped(name: " 手作小物 ", flags: submittedFlags)))
                    )
                )
            )

            // Then
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
                switch example.kind {
                case .orderSource:
                    $0.$catalog.withLock {
                        $0.orderSources = ["手作小物"]
                    }

                case .category:
                    $0.$catalog.withLock {
                        $0.categories = ["手作小物"]
                    }

                case .paymentMethod:
                    $0.$catalog.withLock {
                        $0.paymentMethods = [
                            PaymentMethodInfo(name: "手作小物", flags: example.expectedFlags),
                        ]
                    }

                case .reconciliationStatus:
                    $0.$catalog.withLock {
                        $0.reconciliationStatuses = ["手作小物"]
                    }
                }
            }
            await store.receive(\.addResponse.success, expectedAddition)
            #expect(writes.value == [expectedAddition])
            #expect(store.state.items == [expectedAddition.name])
            #expect(sharedCatalog.names(for: example.kind) == ["手作小物"])
            await store.finish()
        }
    }

    /// 點擊刪除時顯示對應主檔名稱的確認 alert
    @Test
    func deleteButtonTapped_點擊刪除_呈現刪除確認() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.deleteButtonTapped(name: "服飾"))) {
                $0.destination = Self.deleteConfirmationAlert(name: "服飾")
            }

            // Then
            #expect(store.state.destination == Self.deleteConfirmationAlert(name: "服飾"))
            await store.finish()
        }
    }

    /// 確認刪除後呼叫 service 並從共用目錄移除項目
    ///
    /// - Note: 寫入失敗保留項目由 `destination_刪除寫入失敗_保留項目並呈現通知()` 覆蓋
    @Test
    func destination_確認刪除項目_寫入並移除項目() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            state.destination = Self.deleteConfirmationAlert(name: "服飾")
            let removeCalls = LockIsolated<[String]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.categoryService.removeCategory = { name in
                    removeCalls.withValue {
                        $0.append(name)
                    }
                }
            }

            // When
            await store.send(.destination(.presented(.alert(.confirmDelete(name: "服飾"))))) {
                $0.destination = nil
            }

            // Then
            await store.receive(\.deleteResponse.success, "服飾") {
                $0.$catalog.withLock {
                    $0.categories = []
                }
            }
            #expect(removeCalls.value == ["服飾"])
            #expect(store.state.items.isEmpty)
            await store.finish()
        }
    }
}
