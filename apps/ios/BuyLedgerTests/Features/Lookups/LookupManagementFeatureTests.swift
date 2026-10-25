//
//  LookupManagementFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `LookupManagementFeature` 的單元測試，以 TestStore 逐步驗證主檔目錄的載入、項目的新增與刪除
@MainActor
struct LookupManagementFeatureTests {

    /// 驗證任一種類載入成功時，只替換該種類的目錄清單、其他種類維持原樣，並清除載入失敗的標記
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
            let observedKinds = LockIsolated<[LookupKind]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.fetchItems = { requestKind in
                    observedKinds.withValue {
                        $0.append(requestKind)
                    }
                    switch requestKind {
                    case .orderSource:
                        return LookupCatalog(orderSources: ["新來源"])

                    case .category:
                        return LookupCatalog(categories: ["新類別"])

                    case .paymentMethod:
                        return LookupCatalog(paymentMethods: [
                            PaymentMethodInfo(
                                name: "新付款",
                                flags: PaymentMethodFlags(
                                    isCardless: true,
                                    isBankTransfer: false,
                                    isCashOnDelivery: false
                                )
                            ),
                        ])

                    case .reconciliationStatus:
                        return LookupCatalog(reconciliationStatuses: ["新狀態"])
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
            #expect(observedKinds.value == [kind])
            await store.finish()
        }
    }

    /// 驗證點擊新增時，依目前的主檔種類呈現新增表單，是否帶付款方式分類由案例決定
    ///
    /// - Parameter example: 主檔種類與表單是否帶付款方式分類
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
                store.state.destination
                    == .add(
                        LookupAddFormFeature.State(hasClassification: example.hasClassification)
                    )
            )
            await store.finish()
        }
    }

    /// 驗證新增名稱前後含空白時，寫入服務與目錄的都是修剪後的名稱，旗標依案例保留或捨棄
    ///
    /// - Parameter example: 主檔種類及該種類應寫入的付款方式旗標
    @Test(arguments: LookupAdditionExample.examples)
    func destination_新增名稱含前後空白_寫入修剪後名稱(example: LookupAdditionExample) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let observedKinds = LockIsolated<[LookupKind]>([])
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
                $0.lookupService.addItem = { kind, addition in
                    observedKinds.withValue {
                        $0.append(kind)
                    }
                    writes.withValue {
                        $0.append(addition)
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
            #expect(observedKinds.value == [example.kind])
            #expect(writes.value == [expectedAddition])
            #expect(store.state.items == [expectedAddition.name])
            #expect(sharedCatalog.names(for: example.kind) == ["手作小物"])
            await store.finish()
        }
    }

    /// 驗證點擊刪除時，呈現帶入該項目名稱的刪除確認框，目錄內容維持不變
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
                $0.destination = LookupManagementFeatureTestSupport.deleteConfirmationAlert(
                    name: "服飾"
                )
            }

            // Then
            #expect(
                store.state.destination
                    == LookupManagementFeatureTestSupport.deleteConfirmationAlert(name: "服飾")
            )
            await store.finish()
        }
    }

    /// 驗證確認刪除後，服務以該種類與名稱被呼叫一次，共用目錄與清單都移除該項目
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
            state.destination = LookupManagementFeatureTestSupport.deleteConfirmationAlert(
                name: "服飾"
            )
            let observedKinds = LockIsolated<[LookupKind]>([])
            let removeCalls = LockIsolated<[String]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.removeItem = { kind, name in
                    observedKinds.withValue {
                        $0.append(kind)
                    }
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
            #expect(observedKinds.value == [.category])
            #expect(removeCalls.value == ["服飾"])
            #expect(store.state.items.isEmpty)
            await store.finish()
        }
    }
}

// MARK: - Nested Types

extension LookupManagementFeatureTests {

    /// 新增流程的參數化測試案例，每筆描述一種主檔的表單是否帶分類，以及新增後預期保存的付款方式旗標
    struct LookupAdditionExample: Sendable {

        /// 每種主檔各一筆的新增案例，非付款方式捨棄送入的旗標，付款方式則保留
        static let examples = [
            Self(kind: .orderSource, hasClassification: false, expectedFlags: .none),
            Self(kind: .category, hasClassification: false, expectedFlags: .none),
            Self(
                kind: .paymentMethod,
                hasClassification: true,
                expectedFlags: PaymentMethodFlags(
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                )
            ),
            Self(kind: .reconciliationStatus, hasClassification: false, expectedFlags: .none),
        ]

        /// 要新增的主檔種類
        let kind: LookupKind

        /// 此主檔種類是否保留付款方式分類
        let hasClassification: Bool

        /// 此案例新增後預期保存的付款方式旗標
        let expectedFlags: PaymentMethodFlags
    }
}
