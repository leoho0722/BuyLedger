//
//  LookupManagementFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證主檔管理的載入、新增與刪除流程
@MainActor
struct LookupManagementFeatureTests {

    // MARK: - Tests

    /// 載入指定種類時只替換該目錄清單，並清除載入錯誤
    ///
    /// - Parameter kind: 要載入的主檔種類
    @Test(arguments: LookupKind.allCases)
    func taskLoadsTheRequestedLookupKind(kind: LookupKind) async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            var state = LookupManagementFeature.State(kind: kind)
            state.hasLoadFailed = true
            state.$catalog.withLock { catalog in
                catalog.orderSources = ["舊來源"]
                catalog.categories = ["舊類別"]
                catalog.paymentMethods = [
                    PaymentMethodInfo(
                        name: "舊付款",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    )
                ]
                catalog.reconciliationStatuses = ["舊狀態"]
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                switch kind {
                case .orderSource:
                    $0[OrderSourceRepository.self].fetchOrderSources = { ["新來源"] }

                case .category:
                    $0[CategoryRepository.self].fetchCategories = { ["新類別"] }

                case .paymentMethod:
                    $0[PaymentMethodRepository.self].fetchPaymentMethodInfos = {
                        [
                            PaymentMethodInfo(
                                name: "新付款",
                                isCardless: true,
                                isBankTransfer: false,
                                isCashOnDelivery: false
                            )
                        ]
                    }

                case .reconciliationStatus:
                    $0[ReconciliationStatusRepository.self].fetchReconciliationStatuses = {
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
                    $0.$catalog.withLock { catalog in catalog.orderSources = ["新來源"] }

                case .category:
                    $0.$catalog.withLock { catalog in catalog.categories = ["新類別"] }

                case .paymentMethod:
                    $0.$catalog.withLock { catalog in
                        catalog.paymentMethods = [
                            PaymentMethodInfo(
                                name: "新付款",
                                isCardless: true,
                                isBankTransfer: false,
                                isCashOnDelivery: false
                            )
                        ]
                    }

                case .reconciliationStatus:
                    $0.$catalog.withLock { catalog in
                        catalog.reconciliationStatuses = ["新狀態"]
                    }
                }
            }
            #expect(store.state.catalog.names(for: kind) == [Self.loadedName(for: kind)])
            await store.finish()
        }
    }

    /// 新增四種主檔時先寫入 repository，再更新共用目錄
    ///
    /// - Parameter kind: 要新增項目的主檔種類
    /// - Note: 寫入失敗時目錄維持原值，由 `addWriteFailureIsDismissedAndDoesNotReturnAfterSuccess()` 覆蓋
    @Test(arguments: LookupKind.allCases)
    func addFormWritesTheTrimmedName(kind: LookupKind) async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let writes = LockIsolated<[LookupItemAddition]>([])
            let flags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
            let expectedAddition = LookupItemAddition(
                name: "手作小物",
                flags: kind == .paymentMethod ? flags : .none
            )
            let store = TestStore(
                initialState: LookupManagementFeature.State(kind: kind)
            ) {
                LookupManagementFeature()
            } withDependencies: {
                switch kind {
                case .orderSource:
                    $0[OrderSourceRepository.self].addOrderSource = { name in
                        writes.withValue { additions in
                            additions.append(LookupItemAddition(name: name, flags: .none))
                        }
                    }

                case .category:
                    $0[CategoryRepository.self].addCategory = { name in
                        writes.withValue { additions in
                            additions.append(LookupItemAddition(name: name, flags: .none))
                        }
                    }

                case .paymentMethod:
                    $0[PaymentMethodRepository.self].addPaymentMethod = { name, flags in
                        writes.withValue { additions in
                            additions.append(LookupItemAddition(name: name, flags: flags))
                        }
                    }

                case .reconciliationStatus:
                    $0[ReconciliationStatusRepository.self].addReconciliationStatus = { name in
                        writes.withValue { additions in
                            additions.append(LookupItemAddition(name: name, flags: .none))
                        }
                    }
                }
            }

            // When
            await store.send(.view(.addButtonTapped)) {
                $0.destination = .add(
                    LookupAddFormFeature.State(hasClassification: kind == .paymentMethod)
                )
            }
            await store.send(
                .destination(
                    .presented(
                        .add(.view(.saveButtonTapped(name: " 手作小物 ", flags: flags)))
                    )
                )
            )
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
                switch kind {
                case .orderSource:
                    $0.$catalog.withLock { catalog in
                        catalog.orderSources = ["手作小物"]
                    }

                case .category:
                    $0.$catalog.withLock { catalog in
                        catalog.categories = ["手作小物"]
                    }

                case .paymentMethod:
                    $0.$catalog.withLock { catalog in
                        catalog.paymentMethods = [
                            PaymentMethodInfo(
                                name: "手作小物",
                                isCardless: false,
                                isBankTransfer: true,
                                isCashOnDelivery: false
                            )
                        ]
                    }

                case .reconciliationStatus:
                    $0.$catalog.withLock { catalog in
                        catalog.reconciliationStatuses = ["手作小物"]
                    }
                }
            }

            await store.receive(\.addResponse.success, expectedAddition)
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
            }

            // Then
            #expect(writes.value == [expectedAddition])
            #expect(store.state.items == [expectedAddition.name])
            #expect(sharedCatalog.names(for: kind) == ["手作小物"])
            await store.finish()
        }
    }

    /// 刪除前要求確認，確認後寫入並從共用目錄移除
    ///
    /// - Note: 先寫後改由 `deleteWriteFailureLeavesTheItemAndPresentsNotice` 保證：寫入失敗時項目保留
    @Test
    func deleteConfirmationWritesAndRemovesTheItem() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["服飾"] }
            let removeCalls = LockIsolated<[String]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self].removeCategory = { name in
                    removeCalls.withValue { $0.append(name) }
                }
            }

            // When
            await store.send(.view(.deleteButtonTapped(name: "服飾"))) {
                $0.destination = Self.deleteConfirmationAlert(name: "服飾")
            }
            await store.send(
                .destination(.presented(.alert(.confirmDelete(name: "服飾"))))
            ) {
                $0.destination = nil
            }

            // Then
            await store.receive(\.deleteResponse.success, "服飾") {
                $0.$catalog.withLock { $0.categories = [] }
            }
            #expect(removeCalls.value == ["服飾"])
            #expect(store.state.items.isEmpty)
            await store.finish()
        }
    }
}
