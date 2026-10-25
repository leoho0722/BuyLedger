//
//  OrderWritesFeatureCascadeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證開團刪除、開團改名與主檔改名時，連帶更新的訂單歸屬
@MainActor
struct OrderWritesFeatureCascadeTests {

    // MARK: - Properties

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證刪除開團時，訂單上該開團的歸屬被移除且名稱前後空白先去除，其他開團與其他訂單保留不變，共用清單於送出請求時同步更新
    @Test
    func cascadeRequested_刪除開團_保留其他歸屬與訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", campaignNames: ["舊團", "其他團"])
        let expected = LedgerOrder.fixture(id: "O1", campaignNames: ["其他團"])
        let initial = OrderWritesFeatureTestSupport.makeCascadeState(orders: [original, Self.other])
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

    /// 驗證開團改名時，訂單上的舊名替換為新名 (名稱前後空白先去除)，其他開團與其他訂單保留不變
    @Test
    func cascadeRequested_開團改名_只替換目標歸屬() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", campaignNames: ["舊團", "其他團"])
        let expected = LedgerOrder.fixture(id: "O1", campaignNames: ["新團", "其他團"])
        let initial = OrderWritesFeatureTestSupport.makeCascadeState(orders: [original, Self.other])
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

    /// 驗證主檔改名時，只替換指定種類的欄位，其他種類中同名的值保持不變
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
        let initial = OrderWritesFeatureTestSupport.makeCascadeState(orders: [original, Self.other])
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

    /// 驗證開團改名的舊名或新名去除空白後為空，或兩者相同時，訂單保持原樣不被改寫
    ///
    /// - Parameter testCase: 空白或相同的開團名稱
    @Test(arguments: [
        CampaignRenameCase(from: " ", to: "新團"),
        CampaignRenameCase(from: "舊團", to: "\n"),
        CampaignRenameCase(from: " 舊團 ", to: "舊團"),
    ])
    func cascadeRequested_開團改名無效或未變_保留訂單(testCase: CampaignRenameCase) async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", campaignNames: ["舊團", "其他團"])
        let initial = OrderWritesFeatureTestSupport.makeCascadeState(orders: [original, Self.other])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.cascadeRequested(.campaignRenamed(from: testCase.from, to: testCase.to)))

        // Then
        await store.finish()
        #expect(initial.orders == [original, Self.other])
    }
}

// MARK: - Nested Types

extension OrderWritesFeatureCascadeTests {

    /// 無效或相同的開團改名輸入
    struct CampaignRenameCase: Sendable {

        /// 空白或原名稱
        let from: String

        /// 空白或相同名稱
        let to: String
    }
}
