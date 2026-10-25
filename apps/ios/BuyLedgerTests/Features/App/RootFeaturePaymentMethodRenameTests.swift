//
//  RootFeaturePaymentMethodRenameTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證付款方式改名後，引用舊名的訂單與各頁投影如何改寫
@MainActor
struct RootFeaturePaymentMethodRenameTests {

    /// 驗證付款方式改名成功後，付款方式清單與引用舊名的訂單都換成新名稱，訂單由 Root 送出的調整請求改寫
    @Test
    func more_付款方式改名_透過委派改寫訂單() async {
        // Given
        let order = RootFeatureTestSupport.makeOrder(id: "T-PM", paymentMethod: "舊付款")
        let renamedOrder = RootFeatureTestSupport.rebuiltOrder(order, paymentMethod: "新付款")
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.$orders.withLock {
            $0 = [order]
        }
        state.more.catalog.$catalog.withLock {
            $0.paymentMethods = [PaymentMethodInfo(name: "舊付款", flags: .none)]
        }
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊付款")
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
        let rename = LookupItemRename(oldName: "舊付款", newName: "新付款")
        let cascade = OrdersCascadeOperations.Request.lookupItemRenamed(
            kind: .paymentMethod,
            rename: rename
        )

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
            $0.more.catalog.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "新付款", flags: .none)]
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
            .lookupItemRenamed(kind: .paymentMethod, rename: rename)
        )
        await store.receive(\.orders.rootRequest.cascade, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = [renamedOrder]
            $0.insights.orders = [renamedOrder]
        }
        #expect(renameKinds.value == [.paymentMethod])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["新付款"])
        #expect(store.state.orders.list.availablePaymentMethods.map(\.name).contains("新付款"))
        #expect(!store.state.orders.list.availablePaymentMethods.map(\.name).contains("舊付款"))
        #expect(store.state.orders.orders.first?.paymentMethod == "新付款")
        await store.finish()
    }
}
