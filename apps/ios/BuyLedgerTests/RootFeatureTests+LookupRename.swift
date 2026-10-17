//
//  RootFeatureTests+LookupRename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 訂單來源改名成功後，來源清單與引用舊名的訂單都換成新名稱
    ///
    /// - Note: 共用訂單在 `saved` 回應時一併更新
    /// - Note: 總覽與分析頁的訂單在寫入子功能收到調整請求時更新
    @Test
    func more_訂單來源改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-OS", orderSource: "舊來源")
        let renamedOrder = Self.rebuiltOrder(order, orderSource: "新來源")
        var state = Self.makeIsolatedRootState(lookupKind: .orderSource)
        state.orders.$orders.withLock {
            $0 = [order]
        }
        state.more.catalog.$catalog.withLock { $0.orderSources = ["舊來源"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊來源")
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
        let rename = LookupItemRename(oldName: "舊來源", newName: "新來源")
        let cascade = OrdersCascadeOperations.Request.lookupItemRenamed(
            kind: .orderSource,
            rename: rename
        )

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.rename(.view(.saveButtonTapped(name: "新來源")))))
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
                $0.orderSources = ["新來源"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.orders.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(\.more.delegate, .lookupItemRenamed(kind: .orderSource, rename: rename))
        await store.receive(\.orders.rootRequest.cascade, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(renameKinds.value == [.orderSource])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["新來源"])
        let sources = OrdersEditorOptions.orderSources(
            orders: store.state.orders.orders,
            catalog: store.state.orders.lookupCatalog
        )
        #expect(sources.contains("新來源"))
        #expect(!sources.contains("舊來源"))
        #expect(store.state.orders.orders.first?.orderSource == "新來源")
        await store.finish()
    }

    /// 商品類別改名成功後，類別清單與引用舊名的訂單都換成新名稱
    @Test
    func more_分類改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(
            id: "T-CAT",
            orderSource: "舊類別",
            categories: ["舊類別"],
            paymentMethod: "舊類別",
            reconciliationStatus: "舊類別"
        )
        let renamedOrder = Self.rebuiltOrder(order, categories: ["新類別"])
        var state = Self.makeIsolatedRootState(lookupKind: .category)
        state.orders.$orders.withLock {
            $0 = [order]
        }
        state.more.catalog.$catalog.withLock { $0.categories = ["舊類別"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊類別")
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
        let rename = LookupItemRename(oldName: "舊類別", newName: "新類別")
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
                            .destination(.presented(.rename(.view(.saveButtonTapped(name: "新類別")))))
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
                $0.categories = ["新類別"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.orders.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(\.more.delegate, .lookupItemRenamed(kind: .category, rename: rename))
        await store.receive(\.orders.rootRequest.cascade, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(renameKinds.value == [.category])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["新類別"])
        #expect(store.state.orders.list.availableCategories.contains("新類別"))
        #expect(!store.state.orders.list.availableCategories.contains("舊類別"))
        #expect(store.state.orders.orders.first?.categories == ["新類別"])
        await store.finish()
    }

    /// 對帳狀態改名成功後，對帳狀態清單與引用舊名的訂單都換成新名稱
    @Test
    func more_對帳狀態改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-RS", reconciliationStatus: "待對帳")
        let renamedOrder = Self.rebuiltOrder(order, reconciliationStatus: "已對帳")
        var state = Self.makeIsolatedRootState(lookupKind: .reconciliationStatus)
        state.orders.$orders.withLock {
            $0 = [order]
        }
        state.more.catalog.$catalog.withLock {
            $0.reconciliationStatuses = ["待對帳"]
        }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "待對帳")
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
        let rename = LookupItemRename(oldName: "待對帳", newName: "已對帳")
        let cascade = OrdersCascadeOperations.Request.lookupItemRenamed(
            kind: .reconciliationStatus,
            rename: rename
        )

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.rename(.view(.saveButtonTapped(name: "已對帳")))))
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
                $0.reconciliationStatuses = ["已對帳"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.orders.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(
            \.more.delegate,
            .lookupItemRenamed(kind: .reconciliationStatus, rename: rename)
        )
        await store.receive(\.orders.rootRequest.cascade, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(renameKinds.value == [.reconciliationStatus])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["已對帳"])
        let statuses = OrdersEditorOptions.reconciliationStatuses(
            orders: store.state.orders.orders,
            catalog: store.state.orders.lookupCatalog
        )
        #expect(statuses.contains("已對帳"))
        #expect(!statuses.contains("待對帳"))
        #expect(store.state.orders.orders.first?.reconciliationStatus == "已對帳")
        await store.finish()
    }
}
