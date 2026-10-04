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

    /// 訂單來源改名成功後，主檔清單與引用舊名的訂單都換成新名
    ///
    /// - Note: 共享訂單投影在首個 `saved` 回應核對，其餘投影在 More 的改名委派核對
    @Test
    func more_訂單來源改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-OS", orderSource: "舊來源")
        let renamedOrder = Self.makeOrder(id: "T-OS", orderSource: "新來源")
        var state = Self.makeIsolatedRootState(lookupKind: .orderSource)
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.orderSources = ["舊來源"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊來源")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyOrderSourceRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "舊來源", newName: "新來源")

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
            $0.orders.$lookupCatalog.withLock {
                $0.orderSources = ["新來源"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(
            \.more.delegate,
            .lookupItemRenamed(kind: .orderSource, rename: rename)
        ) {
            $0.orders.orders = [renamedOrder]
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["新來源"])
        #expect(store.state.orders.availableOrderSources.contains("新來源"))
        #expect(!store.state.orders.availableOrderSources.contains("舊來源"))
        #expect(store.state.orders.orders.first?.orderSource == "新來源")
        await store.finish()
    }

    /// 商品類別改名成功後，主檔清單與引用舊名的訂單都換成新名
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
        let renamedOrder = Self.makeOrder(
            id: "T-CAT",
            orderSource: "舊類別",
            categories: ["新類別"],
            paymentMethod: "舊類別",
            reconciliationStatus: "舊類別"
        )
        var state = Self.makeIsolatedRootState(lookupKind: .category)
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.categories = ["舊類別"] }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊類別")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyCategoryRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "舊類別", newName: "新類別")

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
            $0.orders.$lookupCatalog.withLock {
                $0.categories = ["新類別"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(\.more.delegate, .lookupItemRenamed(kind: .category, rename: rename)) {
            $0.orders.orders = [renamedOrder]
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["新類別"])
        #expect(store.state.orders.availableCategories.contains("新類別"))
        #expect(!store.state.orders.availableCategories.contains("舊類別"))
        #expect(store.state.orders.orders.first?.categories == ["新類別"])
        await store.finish()
    }

    /// 對帳狀態改名成功後，主檔清單與引用舊名的訂單都換成新名
    @Test
    func more_對帳狀態改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-RS", reconciliationStatus: "待對帳")
        let renamedOrder = Self.makeOrder(id: "T-RS", reconciliationStatus: "已對帳")
        var state = Self.makeIsolatedRootState(lookupKind: .reconciliationStatus)
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock {
            $0.reconciliationStatuses = ["待對帳"]
        }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "待對帳")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyReconciliationStatusRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "待對帳", newName: "已對帳")

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
            $0.orders.$lookupCatalog.withLock {
                $0.reconciliationStatuses = ["已對帳"]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(
            \.more.delegate,
            .lookupItemRenamed(kind: .reconciliationStatus, rename: rename)
        ) {
            $0.orders.orders = [renamedOrder]
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["已對帳"])
        #expect(store.state.orders.availableReconciliationStatuses.contains("已對帳"))
        #expect(!store.state.orders.availableReconciliationStatuses.contains("待對帳"))
        #expect(store.state.orders.orders.first?.reconciliationStatus == "已對帳")
        await store.finish()
    }

    /// 付款方式改名成功後，主檔清單與引用舊名的訂單都換成新名
    @Test
    func more_付款方式改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-PM", paymentMethod: "舊付款")
        let renamedOrder = Self.makeOrder(id: "T-PM", paymentMethod: "新付款")
        var state = Self.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock {
            $0.paymentMethods = [PaymentMethodInfo(name: "舊付款", flags: .none)]
        }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊付款")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyPaymentMethodRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "舊付款", newName: "新付款")

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.rename(.view(.saveButtonTapped(name: "新付款")))))
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
                $0.paymentMethods = [PaymentMethodInfo(name: "新付款", flags: .none)]
            }
            $0.campaigns.$orders.withLock {
                $0 = [renamedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [renamedOrder]
            }
        }
        await store.receive(\.more.path[id: 0].lookupManagement.renameResponse.success, rename)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.itemRenamed, rename)
        await store.receive(
            \.more.delegate,
            .lookupItemRenamed(kind: .paymentMethod, rename: rename)
        ) {
            $0.orders.orders = [renamedOrder]
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["新付款"])
        #expect(store.state.orders.availablePaymentMethods.map(\.name).contains("新付款"))
        #expect(!store.state.orders.availablePaymentMethods.map(\.name).contains("舊付款"))
        #expect(store.state.orders.orders.first?.paymentMethod == "新付款")
        await store.finish()
    }
}
