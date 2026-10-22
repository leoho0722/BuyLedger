//
//  RootFeatureTests+LookupCatalogAdditionForms.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 表單已關閉時才完成寫入，只更新主檔目錄，不重新呈現表單
    @Test
    func orders_新增完成前關閉來源表單_只更新目錄不重開表單() async {
        // Given
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let initial = Self.makeOptionAdditionRootState()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { _, _ in
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }
        await store.send(
            .orders(
                .presentation(
                    .destination(.presented(.edit(.pickers(.view(.addCategoryTapped("香氛"))))))
                )
            )
        )
        await Self.receiveOptionAdditionRequest(in: store, request: request)
        await store.send(.orders(.presentation(.destination(.dismiss)))) {
            $0.orders.presentation.destination = nil
            $0.orders.presentation.queue.isFormClosing = true
        }

        // When
        await store.send(.orders(.view(.formSheetDismissed))) {
            $0.orders.presentation.queue.isFormClosing = false
        }

        // Then
        release.continuation.finish()
        await Self.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: true,
            expectedCatalog: LookupCatalog(categories: ["美妝", "香氛"])
        )
        await store.receive(\.orders.rootRequest, .optionAdditionCompleted(request, isStored: true))
        #expect(store.state.orders.presentation.destination == nil)
        #expect(store.state.more.catalog.catalog.categories == ["美妝", "香氛"])
        await store.finish()
    }

    /// 表單 A 關閉後重開同筆訂單的 B，A 的回應保留原識別值且不改 B 的草稿與選取
    @Test
    func orders_新增完成前重開另一張表單_只更新目錄並保留新表單() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", categories: ["美妝"])
        let initial = Self.makeOptionAdditionRootState(original: original)
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let formB = OrderEditFeature.State(
            original: original,
            id: UUID(1),
            options: OrderEditOptions(
                categories: ["美妝"],
                currencyCodes: [.twd],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(1))
            $0.lookupService.addItem = { _, _ in
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }
        await store.send(
            .orders(
                .presentation(
                    .destination(.presented(.edit(.pickers(.view(.addCategoryTapped("香氛"))))))
                )
            )
        )
        await Self.receiveOptionAdditionRequest(in: store, request: request)
        await store.send(.orders(.presentation(.destination(.dismiss)))) {
            $0.orders.presentation.destination = nil
            $0.orders.presentation.queue.isFormClosing = true
        }
        await store.send(.orders(.view(.formSheetDismissed))) {
            $0.orders.presentation.queue.isFormClosing = false
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.edit("O1")))))) {
            $0.orders.presentation.destination = .edit(formB)
        }

        // Then
        release.continuation.finish()
        await Self.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: true,
            expectedCatalog: LookupCatalog(categories: ["美妝", "香氛"])
        )
        await store.receive(\.orders.rootRequest, .optionAdditionCompleted(request, isStored: true))
        #expect(store.state.orders.presentation.destination?.edit == formB)
        #expect(store.state.orders.presentation.destination?.edit?.id == UUID(1))
        #expect(store.state.orders.presentation.destination?.edit?.draft.categories == ["美妝"])
        #expect(store.state.more.catalog.catalog.categories == ["美妝", "香氛"])
        await store.finish()
    }

    /// 合併表單新增類別時保留原有類別，再追加新增的選取
    @Test
    func orders_合併表單新增類別成功_保留既有類別並追加選取() async {
        // Given
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let initial = Self.makeOptionAdditionRootState(isMerge: true)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { _, _ in
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }

        // When
        await store.send(
            .orders(
                .presentation(
                    .destination(.presented(.edit(.pickers(.view(.addCategoryTapped("香氛"))))))
                )
            )
        )

        // Then
        await Self.receiveOptionAdditionRequest(in: store, request: request)
        release.continuation.finish()
        await Self.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: true,
            expectedCatalog: LookupCatalog(categories: ["美妝", "香氛"])
        )
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: true)
        ) {
            $0.orders.presentation.destination?.modify(\.edit) {
                $0.pickers.options.categories = ["美妝", "香氛"]
                $0.draft.categories = ["美妝", "香氛"]
            }
        }
        let categories = store.state.orders.presentation.destination?.edit?.draft.categories
        #expect(categories == ["美妝", "香氛"])
        await store.finish()
    }
}
