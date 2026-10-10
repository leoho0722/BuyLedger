//
//  OrderWritesFeatureTests+Merge.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 合併在單次持久化前更新兩筆來源與新增結果，保留樂觀更新例外
    @Test
    func saveRequested_合併成功_先更新訂單再單次落盤() async {
        // Given
        let initial = Self.makeState()
        let edit = Self.makeMergeEdit()
        let expected = Self.expectedMergedOrder
        let sourceA = LedgerOrder.fixture(id: "O1", status: .merged, categories: ["美妝"])
        let sourceB = LedgerOrder.fixture(id: "OTHER", status: .merged, categories: ["食品"])
        let shared = initial.$orders
        let observed = LockIsolated<[[LedgerOrder]]>([])
        let saved = LockIsolated<[LedgerOrder]>([])
        let consumed = LockIsolated<[[String]]>([])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(0))
            $0.orderService.mergeOrders = { order, sourceIDs in
                observed.withValue {
                    $0.append(shared.wrappedValue)
                }
                saved.withValue {
                    $0.append(order)
                }
                consumed.withValue {
                    $0.append(sourceIDs)
                }
            }
        }

        // When
        await store.send(.saveRequested(edit)) {
            $0.$orders.withLock {
                $0 = [expected, sourceA, sourceB]
            }
        }

        // Then
        await store.receive(\.delegate, .merged(id: expected.id))
        await store.receive(\.mergeResponse)
        #expect(observed.value == [[expected, sourceA, sourceB]])
        #expect(saved.value == [expected])
        #expect(consumed.value == [["O1", "OTHER"]])
        #expect(store.state.orders == [expected, sourceA, sourceB])
        await store.finish()
    }

    /// 合併失敗前可觀察樂觀更新，失敗回應在寫入子層還原完整快照
    @Test
    func saveRequested_合併失敗_回滾快照並回報失敗() async {
        // Given
        let initial = Self.makeState()
        let edit = Self.makeMergeEdit()
        let expected = Self.expectedMergedOrder
        let sourceA = LedgerOrder.fixture(id: "O1", status: .merged, categories: ["美妝"])
        let sourceB = LedgerOrder.fixture(id: "OTHER", status: .merged, categories: ["食品"])
        let clock = TestClock()
        let shared = initial.$orders
        let observed = LockIsolated<[[LedgerOrder]]>([])
        let failingMerge: OrderService.MergeOrders = { _, _ in
            observed.withValue {
                $0.append(shared.wrappedValue)
            }
            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                throw .storage(.saveFailed(underlying: error))
            }
            throw .storage(
                .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
            )
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(0))
            $0.orderService.mergeOrders = failingMerge
        }

        // When
        await store.send(.saveRequested(edit)) {
            $0.$orders.withLock {
                $0 = [expected, sourceA, sourceB]
            }
        }

        // Then
        await store.receive(\.delegate, .merged(id: expected.id))
        #expect(store.state.orders == [expected, sourceA, sourceB])
        await clock.advance(by: .seconds(1))
        await store.receive(\.mergeResponse) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
        }
        await store.receive(\.delegate, .failed(.merge))
        #expect(observed.value == [[expected, sourceA, sourceB]])
        #expect(store.state.orders == [Self.original, Self.other])
        await store.finish()
    }
}

// MARK: - Private Method

private extension OrderWritesFeatureTests {

    /// 合併請求中的預期新增結果，以字面值獨立定義
    static var expectedMergedOrder: LedgerOrder {
        LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "合併客戶", initials: "TC", tier: .regular),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝", "食品"],
            paymentMethod: "",
            photos: [Data([8])],
            mergedSourceIDs: ["O1", "OTHER"]
        )
    }

    /// 建立包含兩筆來源與一張保留照片的合併草稿
    ///
    /// - Returns: 可儲存的合併確認表單
    static func makeMergeEdit() -> OrderEditFeature.State {
        var edit = OrderEditFeature.State(id: UUID(2), currentDate: TestDependencies.fixedNow)
        edit.draft.customerName = "合併客戶"
        edit.draft.orderSource = "IG"
        edit.draft.categories = ["美妝", "食品"]
        edit.mergeSourceIDs = ["O1", "OTHER"]
        edit.photos.draftPhotos = [Data([8])]
        return edit
    }
}
