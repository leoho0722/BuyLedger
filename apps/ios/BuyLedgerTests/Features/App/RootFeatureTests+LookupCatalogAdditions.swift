//
//  RootFeatureTests+LookupCatalogAdditions.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 四種新增皆先落盤，原表單收到相同識別值的結果才加入選項並選取
    ///
    /// - Parameter kind: 要新增的主檔種類
    @Test(arguments: LookupKind.allCases)
    func orders_四種選項新增成功_先落盤再更新目錄與來源表單(kind: LookupKind) async {
        // Given
        let initial = Self.makeOptionAdditionRootState()
        let catalog = SharedReader(initial.more.catalog.$catalog)
        let observed = LockIsolated<[LookupCatalog]>([])
        let kinds = LockIsolated<[LookupKind]>([])
        let additions = LockIsolated<[LookupItemAddition]>([])
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: kind,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { kind, addition in
                observed.withValue {
                    $0.append(catalog.wrappedValue)
                }
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
        let action = Self.optionAdditionAction(kind: kind, name: " 香氛 ")

        // When
        await store.send(
            .orders(.presentation(.destination(.presented(.edit(.pickers(.view(action)))))))
        )

        // Then
        await Self.receiveOptionAdditionRequest(in: store, request: request)
        #expect(store.state.more.catalog.catalog == LookupCatalog(categories: ["美妝"]))
        #expect(store.state.orders.presentation.destination?.edit?.draft.categories == ["美妝"])
        release.continuation.finish()
        let catalogs: [LookupKind: LookupCatalog] = [
            .orderSource: LookupCatalog(orderSources: ["香氛"], categories: ["美妝"]),
            .category: LookupCatalog(categories: ["美妝", "香氛"]),
            .paymentMethod: LookupCatalog(
                categories: ["美妝"],
                paymentMethods: [PaymentMethodInfo(name: "香氛", flags: .none)]
            ),
            .reconciliationStatus: LookupCatalog(
                categories: ["美妝"],
                reconciliationStatuses: ["香氛"]
            ),
        ]
        await Self.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: true,
            expectedCatalog: catalogs[kind] ?? LookupCatalog()
        )
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: true)
        ) {
            switch kind {
            case .orderSource:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.orderSources = ["香氛"]
                    $0.draft.orderSource = "香氛"
                }

            case .category:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.categories = ["美妝", "香氛"]
                    $0.draft.categories = ["香氛"]
                }

            case .paymentMethod:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.paymentMethods = [
                        PaymentMethodInfo(name: "香氛", flags: .none),
                    ]
                    $0.draft.paymentMethod = "香氛"
                }

            case .reconciliationStatus:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.reconciliationStatuses = ["香氛"]
                    $0.draft.reconciliationStatus = "香氛"
                }
            }
        }
        #expect(observed.value == [LookupCatalog(categories: ["美妝"])])
        #expect(kinds.value == [kind])
        #expect(additions.value == [LookupItemAddition(name: "香氛", flags: .none)])
        #expect(store.state.more.catalog.catalog.names(for: kind).contains("香氛"))
        #expect(store.state.orders.presentation.destination?.edit?.id == UUID(0))
        await store.finish()
    }

    /// 四種新增失敗皆保留目錄與表單，關閉動畫結束後才呈現原有失敗文案
    ///
    /// - Parameter kind: 要新增的主檔種類
    /// - Throws: 寫入失敗後的表單或目錄不符前置條件時由 `#require` 丟出
    @Test(arguments: LookupKind.allCases)
    func orders_四種選項新增失敗_保留資料並於表單關閉後提示(kind: LookupKind) async throws {
        // Given
        let initial = Self.makeOptionAdditionRootState()
        let originalForm = initial.orders.presentation.destination
        let kinds = LockIsolated<[LookupKind]>([])
        let additions = LockIsolated<[LookupItemAddition]>([])
        let release = AsyncStream<Void>.makeStream()
        let failingAdd: LookupService.AddItem = { kind, addition throws(PersistenceError) in
            kinds.withValue {
                $0.append(kind)
            }
            additions.withValue {
                $0.append(addition)
            }
            var iterator = release.stream.makeAsyncIterator()
            _ = await iterator.next()
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
        }
        let messages: [LookupKind: LocalizedStringKey] = [
            .orderSource: "orders.general.message.orderSourceAdded",
            .category: "orders.general.message.categoryAddedTry",
            .paymentMethod: "orders.general.message.paymentMethodAdded",
            .reconciliationStatus: "orders.general.message.reconciliationStatusAdded",
        ]
        let notice = OrdersFeatureTests.failureNotice(messages[kind] ?? "")
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: kind,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = failingAdd
        }
        let action = Self.optionAdditionAction(kind: kind, name: "香氛")
        await store.send(
            .orders(.presentation(.destination(.presented(.edit(.pickers(.view(action)))))))
        )
        await Self.receiveOptionAdditionRequest(in: store, request: request)
        release.continuation.finish()
        await Self.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: false,
            expectedCatalog: LookupCatalog(categories: ["美妝"])
        )
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: false)
        )
        await store.receive(\.orders.presentation.noticeRequested, notice) {
            $0.orders.presentation.queue.pendingNotice = notice
        }
        try #require(store.state.orders.presentation.destination == originalForm)
        try #require(store.state.orders.presentation.destination?.edit?.draft.categories == ["美妝"])
        try #require(store.state.more.catalog.catalog == LookupCatalog(categories: ["美妝"]))
        await store.send(.orders(.presentation(.destination(.dismiss)))) {
            $0.orders.presentation.destination = nil
            $0.orders.presentation.queue.isFormClosing = true
        }

        // When
        await store.send(.orders(.view(.formSheetDismissed))) {
            $0.orders.presentation.queue.isFormClosing = false
            $0.orders.presentation.queue.pendingNotice = nil
            $0.orders.presentation.destination = notice
        }

        // Then
        #expect(store.state.more.catalog.catalog == LookupCatalog(categories: ["美妝"]))
        #expect(store.state.orders.presentation.destination == notice)
        #expect(store.state.orders.presentation.queue.pendingNotice == nil)
        #expect(kinds.value == [kind])
        #expect(additions.value == [LookupItemAddition(name: "香氛", flags: .none)])
        await store.finish()
    }
}
