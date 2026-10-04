//
//  RootFeatureTests+LookupSync.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 改名分類時，只替換訂單中的目標名稱，並保留其他分類
    @Test
    func more_分類改名_同步更新多分類訂單() async {
        // Given
        let multi = Self.makeTestOrder(id: "T-MULTI", categories: ["美妝", "服飾"], customerName: "客")
        let single = Self.makeTestOrder(id: "T-SINGLE", categories: ["服飾"], customerName: "客")
        let cosmeticsOnly = Self.makeTestOrder(
            id: "T-COSMETICS",
            categories: ["美妝"],
            customerName: "客"
        )
        let renamedMulti = Self.rebuiltOrder(multi, categories: ["彩妝保養", "服飾"])
        let renamedSingle = Self.rebuiltOrder(single, categories: ["服飾"])
        let renamedCosmeticsOnly = Self.rebuiltOrder(cosmeticsOnly, categories: ["彩妝保養"])
        var state = Self.makeIsolatedRootState(lookupKind: .category)
        state.orders.orders = [multi, single, cosmeticsOnly]
        state.orders.$lookupCatalog.withLock { $0.categories = ["美妝", "服飾"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "美妝")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyCategoryRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "美妝", newName: "彩妝保養")

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(
                                .presented(.rename(.view(.saveButtonTapped(name: "彩妝保養"))))
                            )
                        )
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: 0].lookupManagement.destination.presented.rename.delegate.saved
        ) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = nil
            $0.more.path[id: 0, case: \.lookupManagement]?.isFormSheetDismissing = true
            $0.orders.$lookupCatalog.withLock {
                $0.categories = ["服飾", "彩妝保養"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            }
            $0.more.$orders.withLock {
                $0 = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(\.more.delegate, .lookupItemRenamed(kind: .category, rename: rename)) {
            $0.orders.orders = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            $0.dashboard.orders = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            $0.insights.orders = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["服飾", "彩妝保養"])
        #expect(store.state.orders.availableCategories.contains("彩妝保養"))
        #expect(!store.state.orders.availableCategories.contains("美妝"))
        #expect(store.state.orders.orders == [renamedMulti, renamedSingle, renamedCosmeticsOnly])
        await store.finish()
    }

    /// 訂單編輯新增的類別會同步到管理頁
    @Test
    func orders_訂單編輯中新增分類_同步至查詢管理() async {
        // Given
        let state = Self.makeIsolatedRootState(lookupKind: .category) {
            var rootState = RootFeature.State()
            rootState.orders.editOrder = OrderEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            return rootState
        }

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.categoryService.addCategory = { _ in
            }
        }

        // When
        await store.send(.orders(.editOrder(.presented(.addCategoryTapped("手工藝品"))))) {
            $0.orders.editOrder?.availableCategories = ["手工藝品"]
            $0.orders.editOrder?.draft.categories = ["手工藝品"]
            $0.orders.$lookupCatalog.withLock {
                $0.categories = ["手工藝品"]
            }
        }

        // Then
        // 管理頁尚未載入時也要立即讀到共用目錄的新項目
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["手工藝品"])
    }

    /// 刪除分類後，訂單編輯選單不再提供該類別
    ///
    /// - Throws: 刪除前找不到待刪類別時由 `try #require` 丟出
    @Test
    func more_刪除分類_從訂單編輯選項移除() async throws(any Error) {
        // Given
        var state = Self.makeIsolatedRootState(lookupKind: .category)
        state.orders.$lookupCatalog.withLock { $0.categories = ["待刪類別"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .deleteConfirmation(
            name: "待刪類別"
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.categoryService.removeCategory = { _ in
            }
        }
        try #require(store.state.orders.availableCategories.contains("待刪類別"))

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.alert(.confirmDelete(name: "待刪類別"))))
                        )
                    )
                )
            )
        ) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = nil
        }

        // Then
        await store.receive(\.more.path[id: 0].lookupManagement.deleteResponse.success, "待刪類別") {
            $0.orders.$lookupCatalog.withLock {
                $0.categories = []
            }
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == [])
        #expect(!store.state.orders.availableCategories.contains("待刪類別"))
        await store.finish()
    }

    /// 分類改名失敗時保留原主檔與訂單，不送出成功改名
    @Test
    func more_分類改名寫入失敗_保留訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-CAT-FAIL", categories: ["服飾"])
        var state = Self.makeIsolatedRootState(lookupKind: .category)
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.categories = ["服飾"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "服飾")
        )
        let renameCalls = LockIsolated<[LookupItemRename]>([])
        let failingRename: OrderService.ApplyCategoryRename = { oldName, newName in
            renameCalls.withValue {
                $0.append(LookupItemRename(oldName: oldName, newName: newName))
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyCategoryRename = failingRename
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.rename(.view(.saveButtonTapped(name: "衣著")))))
                        )
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: 0].lookupManagement.destination.presented.rename.delegate.saved
        ) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = nil
            $0.more.path[id: 0, case: \.lookupManagement]?.isFormSheetDismissing = true
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.failure) {
            $0.more.path[id: 0, case: \.lookupManagement]?.pendingAlert = .writeFailure(.rename)
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["服飾"])
        #expect(store.state.orders.orders == [order])
        #expect(store.state.orders.availableCategories.contains("服飾"))
        #expect(renameCalls.value == [LookupItemRename(oldName: "服飾", newName: "衣著")])
        await store.finish()
    }
}
