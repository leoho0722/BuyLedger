//
//  OrderWritesFeatureTests+Cascade.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

// MARK: - Internal Method

extension OrderWritesFeatureTests {

    /// 刪除開團只移除目標歸屬，並在處理請求時更新共用來源
    @Test
    func cascadeRequested_刪除開團_保留其他歸屬與訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", campaignNames: ["舊團", "其他團"])
        let expected = LedgerOrder.fixture(id: "O1", campaignNames: ["其他團"])
        let initial = Self.makeCascadeState(orders: [original, Self.other])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.cascadeRequested(.campaignDeleted(" \n舊團 \t"))) {
            $0.$orders.withLock {
                $0 = [expected, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(initial.orders == [expected, Self.other])
        #expect(store.state.orders == [expected, Self.other])
    }

    /// 改名開團只替換目標歸屬，並正規化名稱的頭尾空白
    @Test
    func cascadeRequested_開團改名_只替換目標歸屬() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", campaignNames: ["舊團", "其他團"])
        let expected = LedgerOrder.fixture(id: "O1", campaignNames: ["新團", "其他團"])
        let initial = Self.makeCascadeState(orders: [original, Self.other])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.cascadeRequested(.campaignRenamed(from: " 舊團 ", to: " 新團 "))) {
            $0.$orders.withLock {
                $0 = [expected, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(initial.orders == [expected, Self.other])
        #expect(store.state.orders == [expected, Self.other])
    }

    /// 主檔改名只替換指定種類，保留同名但屬於其他種類的欄位
    ///
    /// - Parameter kind: 要改名的四種主檔
    @Test(arguments: LookupKind.allCases)
    func cascadeRequested_四種主檔改名_只更新指定種類(kind: LookupKind) async {
        // Given
        let original = LedgerOrder.fixture(
            id: "O1",
            orderSource: "舊名",
            categories: ["舊名", "其他類別"],
            paymentMethod: "舊名",
            reconciliationStatus: "舊名"
        )
        let expected: LedgerOrder
        switch kind {
        case .orderSource:
            expected = LedgerOrder.fixture(
                id: "O1",
                orderSource: "新名",
                categories: ["舊名", "其他類別"],
                paymentMethod: "舊名",
                reconciliationStatus: "舊名"
            )

        case .category:
            expected = LedgerOrder.fixture(
                id: "O1",
                orderSource: "舊名",
                categories: ["新名", "其他類別"],
                paymentMethod: "舊名",
                reconciliationStatus: "舊名"
            )

        case .paymentMethod:
            expected = LedgerOrder.fixture(
                id: "O1",
                orderSource: "舊名",
                categories: ["舊名", "其他類別"],
                paymentMethod: "新名",
                reconciliationStatus: "舊名"
            )

        case .reconciliationStatus:
            expected = LedgerOrder.fixture(
                id: "O1",
                orderSource: "舊名",
                categories: ["舊名", "其他類別"],
                paymentMethod: "舊名",
                reconciliationStatus: "新名"
            )
        }
        let initial = Self.makeCascadeState(orders: [original, Self.other])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }
        let rename = LookupItemRename(oldName: " 舊名 ", newName: " 新名 ")

        // When
        await store.send(.cascadeRequested(.lookupItemRenamed(kind: kind, rename: rename))) {
            $0.$orders.withLock {
                $0 = [expected, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(initial.orders == [expected, Self.other])
        #expect(store.state.orders == [expected, Self.other])
    }

    /// 無效或未改變的開團名稱不改寫訂單
    ///
    /// - Parameters:
    ///   - from: 空白或原名稱
    ///   - to: 空白或相同名稱
    @Test(arguments: [(" ", "新團"), ("舊團", "\n"), (" 舊團 ", "舊團")])
    func cascadeRequested_開團改名無效或未變_保留訂單(from: String, to: String) async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", campaignNames: ["舊團", "其他團"])
        let initial = Self.makeCascadeState(orders: [original, Self.other])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.cascadeRequested(.campaignRenamed(from: from, to: to))) {
            $0.$orders.withLock {
                $0 = [original, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(initial.orders == [original, Self.other])
    }

    /// 設定共用初值，讓測試持有與 reducer 相同的訂單引用
    ///
    /// - Parameter orders: 待操作的固定訂單
    /// - Returns: 與容器共用引用的寫入狀態
    static func makeCascadeState(orders: [LedgerOrder]) -> OrderWritesFeature.State {
        let sharedOrders = Shared<[LedgerOrder]>(value: [])
        sharedOrders.withLock {
            $0 = orders
        }
        return OrderWritesFeature.State(orders: sharedOrders)
    }
}
