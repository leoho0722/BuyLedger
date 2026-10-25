//
//  RootFeatureLookupSyncTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證商品類別改名、新增、刪除與寫入失敗時，訂單與主檔如何同步
@MainActor
struct RootFeatureLookupSyncTests {

    /// 驗證商品類別改名時，含目標類別的訂單只替換該名稱，其餘類別保留，不含目標類別的訂單維持不變
    @Test
    func more_分類改名_同步更新多分類訂單() async {
        // Given
        let multi = RootFeatureTestSupport.makeTestOrder(
            id: "T-MULTI",
            categories: ["美妝", "服飾"],
            customerName: "客"
        )
        let single = RootFeatureTestSupport.makeTestOrder(
            id: "T-SINGLE",
            categories: ["服飾"],
            customerName: "客"
        )
        let cosmeticsOnly = RootFeatureTestSupport.makeTestOrder(
            id: "T-COSMETICS",
            categories: ["美妝"],
            customerName: "客"
        )
        let renamedMulti = RootFeatureTestSupport.rebuiltOrder(multi, categories: ["彩妝保養", "服飾"])
        let renamedSingle = RootFeatureTestSupport.rebuiltOrder(single, categories: ["服飾"])
        let renamedCosmeticsOnly = RootFeatureTestSupport.rebuiltOrder(
            cosmeticsOnly,
            categories: ["彩妝保養"]
        )
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .category)
        state.orders.$orders.withLock {
            $0 = [multi, single, cosmeticsOnly]
        }
        state.more.catalog.$catalog.withLock { $0.categories = ["美妝", "服飾"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "美妝")
        )
        let renameKinds = LockIsolated<[LookupKind]>([])
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.renameItem = { kind, _ in
                renameKinds.withValue {
                    $0.append(kind)
                }
            }
        }
        let rename = LookupItemRename(oldName: "美妝", newName: "彩妝保養")
        let cascade = OrdersCascadeOperations.Request.lookupItemRenamed(
            kind: .category,
            rename: rename
        )

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
            $0.more.catalog.$catalog.withLock {
                $0.categories = ["服飾", "彩妝保養"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            }
            $0.more.$orders.withLock {
                $0 = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            }
            $0.orders.$orders.withLock {
                $0 = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(\.more.delegate, .lookupItemRenamed(kind: .category, rename: rename))
        await store.receive(\.orders.rootRequest.cascade, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
            $0.insights.orders = [renamedMulti, renamedSingle, renamedCosmeticsOnly]
        }
        #expect(renameKinds.value == [.category])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["服飾", "彩妝保養"])
        #expect(store.state.orders.list.availableCategories.contains("彩妝保養"))
        #expect(!store.state.orders.list.availableCategories.contains("美妝"))
        #expect(store.state.orders.orders == [renamedMulti, renamedSingle, renamedCosmeticsOnly])
        await store.finish()
    }

    /// 驗證訂單編輯中新增類別時，寫入執行前目錄尚無該項目，寫入成功後才同步到表單與主檔管理頁
    @Test
    func orders_訂單編輯中新增分類_成功落盤後同步至查詢管理() async {
        // Given
        let state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .category) {
            var rootState = RootFeature.State()
            rootState.orders.presentation.destination = .edit(
                OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
            )
            return rootState
        }

        let catalog = state.more.catalog.$catalog
        let observedCategories = LockIsolated<[[String]]>([])
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "手工藝品",
            flags: .none
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { _, _ in
                observedCategories.withValue {
                    $0.append(catalog.wrappedValue.categories)
                }
            }
        }

        // When
        await store.send(
            .orders(
                .presentation(
                    .destination(.presented(.edit(.pickers(.view(.addCategoryTapped("手工藝品"))))))
                )
            )
        )

        // Then
        await store.receive(
            \.orders.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(kind: .category, name: "手工藝品", flags: .none)
        ) {
            $0.more.catalog.$catalog.withLock {
                $0.categories = ["手工藝品"]
            }
        }
        await store.receive(
            \.orders.presentation.destination.presented.edit.delegate,
            .addOptionRequested(kind: .category, name: "手工藝品", flags: .none)
        )
        await store.receive(\.orders.presentation.delegate.optionAddRequested, request)
        await store.receive(\.orders.delegate.optionAddRequested, request)
        await store.receive(\.more.optionAdditionRequested, request)
        await store.receive(\.more.catalog.additionRequested, request)
        await store.receive(\.more.catalog.additionResponse)
        await store.receive(\.more.catalog.delegate, .additionCompleted(request, isStored: true))
        await store.receive(\.more.delegate, .optionAdditionCompleted(request, isStored: true))
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: true)
        ) {
            $0.orders.presentation.destination?.modify(\.edit) {
                $0.pickers.options.categories = ["手工藝品"]
            }
            $0.orders.presentation.destination?.modify(\.edit) {
                $0.draft.categories = ["手工藝品"]
            }
        }
        // 管理頁尚未載入時也能讀到已落盤的新項目
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["手工藝品"])
        #expect(observedCategories.value == [[]])
        await store.finish()
    }

    /// 驗證刪除商品類別成功後，訂單編輯的選項與主檔管理頁的清單都不再含該類別
    ///
    /// - Throws: 刪除前找不到待刪類別時由 `try #require` 丟出
    @Test
    func more_刪除分類_從訂單編輯選項移除() async throws {
        // Given
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .category)
        state.more.catalog.$catalog.withLock { $0.categories = ["待刪類別"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .deleteConfirmation(
            name: "待刪類別"
        )
        let removeKinds = LockIsolated<[LookupKind]>([])
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.removeItem = { kind, _ in
                removeKinds.withValue {
                    $0.append(kind)
                }
            }
        }
        try #require(store.state.orders.list.availableCategories.contains("待刪類別"))

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
            $0.more.catalog.$catalog.withLock {
                $0.categories = []
            }
        }
        #expect(removeKinds.value == [.category])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == [])
        #expect(!store.state.orders.list.availableCategories.contains("待刪類別"))
        await store.finish()
    }

    /// 驗證商品類別改名寫入失敗時，類別清單與訂單維持原樣，不送出改名的調整請求，並顯示寫入失敗的提示
    @Test
    func more_分類改名寫入失敗_保留訂單() async {
        // Given
        let order = RootFeatureTestSupport.makeOrder(id: "T-CAT-FAIL", categories: ["服飾"])
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .category)
        state.orders.$orders.withLock {
            $0 = [order]
        }
        state.more.catalog.$catalog.withLock { $0.categories = ["服飾"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "服飾")
        )
        let renameKinds = LockIsolated<[LookupKind]>([])
        let renameCalls = LockIsolated<[LookupItemRename]>([])
        let failingRename: LookupService.RenameItem = { kind, itemRename throws(PersistenceError) in
            renameKinds.withValue {
                $0.append(kind)
            }
            renameCalls.withValue {
                $0.append(itemRename)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.renameItem = failingRename
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
        #expect(renameKinds.value == [.category])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["服飾"])
        #expect(store.state.orders.orders == [order])
        #expect(store.state.orders.list.availableCategories.contains("服飾"))
        #expect(renameCalls.value == [LookupItemRename(oldName: "服飾", newName: "衣著")])
        await store.finish()
    }
}
