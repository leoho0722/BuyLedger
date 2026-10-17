//
//  RootFeatureTests+LookupCatalogRequests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 已完整讀取主檔時，原目錄保持不變且直接繼續載入訂單
    @Test
    func dashboard_重新整理時四種主檔已載入_略過主檔讀取並保留原目錄() async {
        // Given
        var initial = Self.makeIsolatedRootState()
        initial.more.catalog.hasLoaded = true
        initial.more.catalog.$catalog.withLock {
            $0.categories = ["服飾"]
            $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
        }
        let reads = LockIsolated(0)
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                reads.withValue {
                    $0 += 1
                }
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
                return []
            }
        }

        // When
        await store.send(.dashboard(.delegate(.refresh))) {
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested)
        await Self.receiveCatalogFinished(in: store)
        await Self.receiveEmptyOrders(in: store, release: release.continuation)
        await store.finish()
        #expect(store.state.more.catalog.catalog.categories == ["服飾"])
        #expect(
            store.state.more.catalog.catalog.paymentMethods == [
                PaymentMethodInfo(name: "信用卡", flags: .none),
            ]
        )
        #expect(reads.value == 1)
    }

    /// 訂單分頁出現與重試都先交給 Root 完成主檔讀取，再開始訂單讀取
    ///
    /// - Parameter shouldRetry: 是否送出重試事件
    @Test(arguments: [false, true])
    func orders_分頁要求載入_完成主檔後才讀取訂單(shouldRetry: Bool) async {
        // Given
        let reads = LockIsolated<[LookupKind]>([])
        let orderReads = LockIsolated(0)
        let catalogRelease = AsyncStream<Void>.makeStream()
        let orderRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: Self.makeIsolatedRootState()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            Self.stubCatalogAndOrders(
                &$0,
                catalogs: [:],
                catalogRelease: catalogRelease.stream,
                orderRelease: orderRelease.stream,
                reads: reads,
                orderReads: orderReads
            )
        }

        // When
        let action: OrderListFeature.Action.View = shouldRetry ? .retryTapped : .task
        await store.send(.orders(.list(.view(action)))) {
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.orders.list.delegate.loadRequested)
        await store.receive(\.orders.delegate.loadRequested)
        await Self.receiveCatalogRequested(in: store)
        #expect(orderReads.value == 0)
        #expect(store.state.orders.load.isLoading == false)
        catalogRelease.continuation.finish()
        await Self.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(),
                .category: LookupCatalog(),
                .paymentMethod: LookupCatalog(),
                .reconciliationStatus: LookupCatalog(),
            ],
            expectedCatalog: LookupCatalog(),
            hasLoaded: true
        )
        await Self.receiveEmptyOrders(in: store, release: orderRelease.continuation)
        await store.finish()
        #expect(reads.value.count == 4)
        #expect(orderReads.value == 1)
    }

    /// 新增無卡付款方式時，Service 參數、目錄與來源表單都保留無卡旗標
    @Test
    func orders_新增街口支付成功_寫入與表單保留無卡旗標() async {
        // Given
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let info = PaymentMethodInfo(name: "街口支付", flags: flags)
        let kinds = LockIsolated<[LookupKind]>([])
        let additions = LockIsolated<[LookupItemAddition]>([])
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .paymentMethod,
            name: "街口支付",
            flags: flags
        )
        let initial = Self.makeOptionAdditionRootState()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { kind, addition in
                kinds.withValue {
                    $0.append(kind)
                }
                additions.withValue {
                    $0.append(addition)
                }
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }

        // When
        await store.send(
            .orders(
                .presentation(
                    .destination(
                        .presented(
                            .edit(
                                .pickers(.view(.addPaymentMethodTapped(name: "街口支付", flags: flags)))
                            )
                        )
                    )
                )
            )
        )

        // Then
        await Self.receiveOptionAdditionRequest(in: store, request: request)
        #expect(store.state.more.catalog.catalog.paymentMethods == [])
        #expect(store.state.orders.presentation.destination?.edit?.draft.paymentMethod == "")
        release.continuation.finish()
        await Self.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: true,
            expectedCatalog: LookupCatalog(categories: ["美妝"], paymentMethods: [info])
        )
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: true)
        ) {
            $0.orders.presentation.destination?.modify(\.edit) {
                $0.pickers.options.paymentMethods = [info]
                $0.draft.paymentMethod = "街口支付"
            }
        }
        #expect(kinds.value == [.paymentMethod])
        #expect(additions.value == [LookupItemAddition(name: "街口支付", flags: flags)])
        #expect(store.state.more.catalog.catalog.paymentMethods == [info])
        let form = store.state.orders.presentation.destination?.edit
        #expect(form?.pickers.options.paymentMethods == [info])
        #expect(form?.isSelectedPaymentMethodCardless == true)
        await store.finish()
    }

    /// 空白名稱被主檔端略過時，訂單容器不等待回應也不更改表單
    @Test
    func orders_新增選項名稱為空白_略過且表單維持可操作() async {
        // Given
        let initial = Self.makeOptionAdditionRootState()
        let form = initial.orders.presentation.destination
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: " \n ",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.orders(.presentation(.delegate(.optionAddRequested(request)))))

        // Then
        await store.receive(\.orders.delegate, .optionAddRequested(request))
        await store.receive(\.more.optionAdditionRequested, request)
        await store.receive(\.more.catalog.additionRequested, request)
        await store.finish()
        #expect(store.state.orders.presentation.destination == form)
        #expect(store.state.orders.presentation.queue.pendingNotice == nil)
        #expect(store.state.more.catalog.catalog.categories == ["美妝"])
    }
}
