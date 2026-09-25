//
//  LookupManagementFeatureTests+Failures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension LookupManagementFeatureTests {

    /// 寫入失敗時保留主檔清單，提示關閉後不會在成功操作時重現
    @Test
    func addWriteFailureIsDismissedAndDoesNotReturnAfterSuccess() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["服飾"] }
            let writeAttempt = LockIsolated(0)
            let writtenNames = LockIsolated<[String]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self].addCategory = { name throws(PersistenceError) in
                    writtenNames.withValue { $0.append(name) }
                    let attempt = writeAttempt.withValue { current in
                        current += 1
                        return current
                    }
                    if attempt == 1 {
                        throw PersistenceError.saveFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    }
                }
            }

            // When
            await store.send(.view(.addButtonTapped)) {
                $0.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            }
            await store.send(
                .destination(
                    .presented(.add(.view(.saveButtonTapped(name: "手工藝品", flags: .none))))
                )
            )
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }

            await store.receive(\.addResponse.failure) {
                $0.pendingAlert = Self.failureNotice(
                    message: "新增失敗，請稍後再試。"
                )
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.failureNotice(
                    message: "新增失敗，請稍後再試。"
                )
            }
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
            }
            await store.send(.view(.addButtonTapped)) {
                $0.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            }
            await store.send(
                .destination(
                    .presented(.add(.view(.saveButtonTapped(name: "手工藝品", flags: .none))))
                )
            )
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
                $0.$catalog.withLock { $0.categories = ["手工藝品", "服飾"] }
            }
            await store.receive(
                \.addResponse.success,
                LookupItemAddition(name: "手工藝品", flags: .none)
            )
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
            }

            // Then
            #expect(writtenNames.value == ["手工藝品", "手工藝品"])
            #expect(store.state.destination == nil)
            #expect(store.state.items == ["手工藝品", "服飾"])
            await store.finish()
        }
    }

    /// 刪除寫入失敗時保留項目並顯示一次性提示
    @Test
    func deleteWriteFailureLeavesTheItemAndPresentsNotice() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["服飾"] }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self].removeCategory = { _ throws(PersistenceError) in
                    throw PersistenceError.saveFailed(
                        underlying: TestDependencies.makeUnderlyingError(message: "boom")
                    )
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
            await store.receive(\.deleteResponse.failure) {
                $0.destination = Self.failureNotice(
                    message: "刪除失敗，請稍後再試。"
                )
            }
            #expect(store.state.items == ["服飾"])
            #expect(store.state.hasLoadFailed == false)
            await store.finish()
        }
    }

    /// 主檔改名交易失敗時保留清單且不送出改名結果
    @Test
    func lookupRenameWriteFailureLeavesTheItemAndPresentsNotice() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["服飾"] }
            let rename = LookupItemRename(oldName: "服飾", newName: "衣著")
            let renameCalls = LockIsolated<[LookupItemRename]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].applyCategoryRename = { oldName, newName throws(PersistenceError) in
                    renameCalls.withValue { calls in
                        calls.append(LookupItemRename(oldName: oldName, newName: newName))
                    }
                    throw PersistenceError.saveFailed(
                        underlying: TestDependencies.makeUnderlyingError(message: "boom")
                    )
                }
            }

            // When
            await store.send(.view(.renameButtonTapped(name: "服飾"))) {
                $0.destination = .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            }
            await store.send(
                .destination(
                    .presented(.rename(.view(.saveButtonTapped(name: "衣著"))))
                )
            )
            await store.receive(\.destination.presented.rename.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }

            await store.receive(\.renameResponse.failure) {
                $0.pendingAlert = Self.failureNotice(
                    message: "重新命名失敗，請稍後再試。"
                )
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.failureNotice(
                    message: "重新命名失敗，請稍後再試。"
                )
            }

            // Then
            #expect(store.state.items == ["服飾"])
            #expect(store.state.hasLoadFailed == false)
            #expect(renameCalls.value == [rename])
            await store.finish()
        }
    }

    /// 指定種類載入失敗時保留清單並顯示載入錯誤狀態
    ///
    /// - Parameter kind: 要載入的主檔種類
    @Test(arguments: LookupKind.allCases)
    func taskLoadFailureKeepsTheRequestedLookupKind(kind: LookupKind) async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: kind)
            state.$catalog.withLock { catalog in
                switch kind {
                case .orderSource:
                    catalog.orderSources = ["舊項目"]

                case .category:
                    catalog.categories = ["舊項目"]

                case .paymentMethod:
                    catalog.paymentMethods = [PaymentMethodInfo(name: "舊項目", flags: .none)]

                case .reconciliationStatus:
                    catalog.reconciliationStatuses = ["舊項目"]
                }
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                switch kind {
                case .orderSource:
                    $0[OrderSourceRepository.self].fetchOrderSources = { () throws(PersistenceError) in
                        throw PersistenceError.fetchFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    }

                case .category:
                    $0[CategoryRepository.self].fetchCategories = { () throws(PersistenceError) in
                        throw PersistenceError.fetchFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    }

                case .paymentMethod:
                    $0[PaymentMethodRepository.self].fetchPaymentMethodInfos = { () throws(PersistenceError) in
                        throw PersistenceError.fetchFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    }

                case .reconciliationStatus:
                    $0[ReconciliationStatusRepository.self].fetchReconciliationStatuses = { () throws(PersistenceError) in
                        throw PersistenceError.fetchFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    }
                }
            }

            // When
            await store.send(.view(.task))

            // Then
            await store.receive(\.itemsResponse.failure) {
                $0.hasLoadFailed = true
            }
            #expect(store.state.items == ["舊項目"])
            #expect(store.state.hasLoaded == false)
            await store.finish()
        }
    }
}
