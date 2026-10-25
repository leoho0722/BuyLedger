//
//  RootFeatureLookupCatalogRequestsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證主檔已載入時略過讀取、主檔完成後才讀取訂單，以及新增選項的請求如何處理
@MainActor
struct RootFeatureLookupCatalogRequestsTests {

    /// 驗證主檔四種都已載入時，重新整理略過主檔讀取，原目錄保持不變，並直接繼續載入訂單
    @Test
    func dashboard_重新整理時四種主檔已載入_略過主檔讀取並保留原目錄() async {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
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
        await RootFeatureTestSupport.receiveCatalogFinished(in: store)
        await RootFeatureTestSupport.receiveEmptyOrders(in: store, release: release.continuation)
        await store.finish()
        #expect(store.state.more.catalog.catalog.categories == ["服飾"])
        #expect(
            store.state.more.catalog.catalog.paymentMethods == [
                PaymentMethodInfo(name: "信用卡", flags: .none),
            ]
        )
        #expect(reads.value == 1)
    }

    /// 驗證訂單分頁出現或按下重試時，Root 先完成四種主檔讀取，之後才開始讀取訂單
    ///
    /// - Parameter shouldRetry: 是否送出重試事件
    @Test(arguments: [false, true])
    func orders_分頁要求載入_完成主檔後才讀取訂單(shouldRetry: Bool) async {
        // Given
        let reads = LockIsolated<[LookupKind]>([])
        let orderReads = LockIsolated(0)
        let catalogRelease = AsyncStream<Void>.makeStream()
        let orderRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: RootFeatureTestSupport.makeIsolatedRootState()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            RootFeatureTestSupport.stubCatalogAndOrders(
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
        await RootFeatureTestSupport.receiveCatalogRequested(in: store)
        #expect(orderReads.value == 0)
        #expect(store.state.orders.load.isLoading == false)
        catalogRelease.continuation.finish()
        await RootFeatureTestSupport.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .category: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .paymentMethod: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .reconciliationStatus: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
            ],
            expectedCatalog: LookupCatalog(
                orderSources: [],
                categories: [],
                paymentMethods: [],
                reconciliationStatuses: []
            ),
            hasLoaded: true
        )
        await RootFeatureTestSupport.receiveEmptyOrders(
            in: store,
            release: orderRelease.continuation
        )
        await store.finish()
        #expect(reads.value.count == 4)
        #expect(orderReads.value == 1)
    }

    /// 驗證新增無卡付款方式 (街口支付) 成功時，寫入參數、目錄與來源表單都保留無卡旗標，且表單的選取視為無卡
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
        let initial = RootFeatureTestSupport.makeOptionAdditionRootState()
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
        await RootFeatureTestSupport.receiveOptionAdditionRequest(in: store, request: request)
        #expect(store.state.more.catalog.catalog.paymentMethods == [])
        #expect(store.state.orders.presentation.destination?.edit?.draft.paymentMethod == "")
        release.continuation.finish()
        await RootFeatureTestSupport.receiveOptionAdditionResult(
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

    /// 驗證空白名稱的新增請求由主檔端略過，不寫入也不回應，表單與提示都維持原狀
    @Test
    func orders_新增選項名稱為空白_略過且表單維持可操作() async {
        // Given
        let initial = RootFeatureTestSupport.makeOptionAdditionRootState()
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
