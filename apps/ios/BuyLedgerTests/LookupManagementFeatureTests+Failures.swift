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

extension LookupManagementFeatureTests {

    /// 先前新增失敗提示關閉後，後續成功操作不會再次呈現該提示
    @Test
    func formSheetDismissed_新增失敗後再次成功_通知不再出現() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            state.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            let observedKinds = LockIsolated<[LookupKind]>([])
            let writtenNames = LockIsolated<[String]>([])
            let expectedAddition = LookupItemAddition(name: "手工藝品", flags: .none)
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let expectedAlert = Self.writeFailureAlert(
                message: "orders.lookup.message.itemAddedTry"
            )
            let failingThenSuccessfulAdd: LookupService.AddItem = { kind, addition throws(PersistenceError) in
                observedKinds.withValue {
                    $0.append(kind)
                }
                let attempt = writtenNames.withValue {
                    $0.append(addition.name)
                    return $0.count
                }
                if attempt == 1 {
                    throw .saveFailed(underlying: underlyingError)
                }
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.addItem = failingThenSuccessfulAdd
            }
            await store.send(
                .destination(.presented(.add(.view(.saveButtonTapped(name: "手工藝品", flags: .none)))))
            )
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }
            await store.receive(\.addResponse.failure) {
                $0.pendingAlert = expectedAlert
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = expectedAlert
            }
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
            }
            await store.send(.view(.addButtonTapped)) {
                $0.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            }
            await store.send(
                .destination(.presented(.add(.view(.saveButtonTapped(name: "手工藝品", flags: .none)))))
            )
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
                $0.$catalog.withLock {
                    $0.categories = ["手工藝品", "服飾"]
                }
            }
            await store.receive(\.addResponse.success, expectedAddition)

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
            }

            // Then
            #expect(store.state.isFormSheetDismissing == false)
            #expect(observedKinds.value == [.category, .category])
            #expect(writtenNames.value == ["手工藝品", "手工藝品"])
            #expect(store.state.destination == nil)
            #expect(store.state.items == ["手工藝品", "服飾"])
            await store.finish()
        }
    }

    /// 刪除寫入失敗時保留項目並呈現錯誤提示
    @Test
    func destination_刪除寫入失敗_保留項目並呈現通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            state.destination = Self.deleteConfirmationAlert(name: "服飾")
            let observedKinds = LockIsolated<[LookupKind]>([])
            let removeCalls = LockIsolated<[String]>([])
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let expectedAlert = Self.writeFailureAlert(
                message: "orders.lookup.message.itemDeletedTry"
            )
            let failingRemove: LookupService.RemoveItem = { kind, name throws(PersistenceError) in
                observedKinds.withValue {
                    $0.append(kind)
                }
                removeCalls.withValue {
                    $0.append(name)
                }
                throw .saveFailed(underlying: underlyingError)
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.removeItem = failingRemove
            }

            // When
            await store.send(.destination(.presented(.alert(.confirmDelete(name: "服飾"))))) {
                $0.destination = nil
            }

            // Then
            await store.receive(\.deleteResponse.failure) {
                $0.destination = expectedAlert
            }
            #expect(observedKinds.value == [.category])
            #expect(removeCalls.value == ["服飾"])
            #expect(store.state.items == ["服飾"])
            #expect(store.state.hasLoadFailed == false)
            await store.finish()
        }
    }

    /// 主檔改名寫入失敗時保留清單、不送出改名結果，失敗提示暫存到表單關閉後才呈現
    @Test
    func destination_重新命名寫入失敗_保留項目並暫存通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            state.destination = .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            let rename = LookupItemRename(oldName: "服飾", newName: "衣著")
            let observedKinds = LockIsolated<[LookupKind]>([])
            let renameCalls = LockIsolated<[LookupItemRename]>([])
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let expectedAlert = Self.writeFailureAlert(
                message: "orders.lookup.message.itemRenamedTry"
            )
            let failingRename: LookupService.RenameItem = { kind, itemRename throws(PersistenceError) in
                observedKinds.withValue {
                    $0.append(kind)
                }
                renameCalls.withValue {
                    $0.append(itemRename)
                }
                throw .saveFailed(underlying: underlyingError)
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.renameItem = failingRename
            }

            // When
            await store.send(
                .destination(.presented(.rename(.view(.saveButtonTapped(name: "衣著")))))
            )

            // Then
            await store.receive(\.destination.presented.rename.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }
            await store.receive(\.renameResponse.failure) {
                $0.pendingAlert = expectedAlert
            }
            #expect(store.state.pendingAlert == expectedAlert)
            #expect(store.state.destination == nil)
            #expect(store.state.items == ["服飾"])
            #expect(store.state.hasLoadFailed == false)
            #expect(observedKinds.value == [.category])
            #expect(renameCalls.value == [rename])
            await store.finish()
        }
    }

    /// 指定種類載入失敗時保留原目錄內容並標記載入錯誤
    ///
    /// - Parameter kind: 要載入的主檔種類
    @Test(arguments: LookupKind.allCases)
    func task_指定查詢種類載入失敗_保留舊項目(kind: LookupKind) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let state = LookupManagementFeature.State(kind: kind)
            state.$catalog.withLock {
                switch kind {
                case .orderSource:
                    $0.orderSources = ["舊項目"]

                case .category:
                    $0.categories = ["舊項目"]

                case .paymentMethod:
                    $0.paymentMethods = [PaymentMethodInfo(name: "舊項目", flags: .none)]

                case .reconciliationStatus:
                    $0.reconciliationStatuses = ["舊項目"]
                }
            }
            let observedKinds = LockIsolated<[LookupKind]>([])
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let failingFetchItems: LookupService.FetchItems = { requestKind throws(PersistenceError) in
                observedKinds.withValue {
                    $0.append(requestKind)
                }
                throw .fetchFailed(underlying: underlyingError)
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.fetchItems = failingFetchItems
            }

            // When
            await store.send(.view(.task))

            // Then
            await store.receive(\.itemsResponse.failure) {
                $0.hasLoadFailed = true
            }
            #expect(observedKinds.value == [kind])
            #expect(store.state.items == ["舊項目"])
            #expect(store.state.hasLoaded == false)
            await store.finish()
        }
    }
}
