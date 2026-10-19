//
//  BLUITestSeedDataTests+CategoryFilter.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import SwiftData
import Testing

@testable import BuyLedger

#if DEBUG

extension BLUITestSeedDataTests {

    /// 分類篩選一般情境寫入後，讀回的開團與訂單數量符合規格
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_分類篩選情境_讀回三個開團與十筆訂單() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilter)

        // When
        let campaignCount = seeded.campaigns.count
        let orderCount = seeded.orders.count

        // Then
        #expect(campaignCount == 3)
        #expect(orderCount == 10)
    }

    /// 分類篩選一般情境讀回後，開團中與已收單類別符合規格
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_分類篩選情境_讀回開團中與已收單類別符合規格() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilter)

        // When
        let groups = Self.groups(of: seeded)

        // Then
        let ongoing = Set(groups.first { $0.kind == .ongoing }?.categories ?? [])
        let closed = Set(groups.first { $0.kind == .closed }?.categories ?? [])
        #expect(ongoing == ["美妝", "3C", "零食"])
        #expect(closed == ["服飾", "精品", "生活雜貨", "書籍", "aespa Lemonade QQ 音樂限定禮包"])
    }

    /// 分類篩選一般情境讀回後，只出現在已收單開團的長名稱類別歸入已收單
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_分類篩選情境_讀回長名稱類別只歸入已收單() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilter)

        // When
        let groups = Self.groups(of: seeded)

        // Then
        let ongoing = groups.first { $0.kind == .ongoing }?.categories ?? []
        let closed = groups.first { $0.kind == .closed }?.categories ?? []
        #expect(groups.contains { $0.kind == .ongoing })
        #expect(!ongoing.contains("aespa Lemonade QQ 音樂限定禮包"))
        #expect(closed.contains("aespa Lemonade QQ 音樂限定禮包"))
    }

    /// 分類篩選一般情境的付款方式主檔至少有兩種，且包含信用卡與銀行轉帳
    ///
    /// - Throws: 讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_分類篩選情境_付款方式至少兩種() throws(any Error) {
        // Given
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }

        // When
        BLUITestSeedData.seed(
            .categoryFilter,
            into: container,
            referenceDate: TestDependencies.fixedNow
        )

        // Then
        let names = try ModelContext(container)
            .fetch(FetchDescriptor<PaymentMethodRecord>())
            .map(\.name)
        #expect(names.count >= 2)
        #expect(names.contains("信用卡"))
        #expect(names.contains("銀行轉帳"))
    }

    /// 讀回的訂單套用本月、信用卡與類別美妝與書籍後，回傳規格列出的四筆
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_本月信用卡選美妝與書籍_回傳四筆() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilter)

        // When
        let result = OrdersQuery.filteredOrders(
            orders: seeded.orders,
            selectedStatus: .all,
            selectedDatePeriod: .thisMonth,
            selectedCategories: ["美妝", "書籍"],
            selectedPaymentMethod: "信用卡",
            searchText: "",
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(
            result.map(\.id) == [
                "UITEST-CF-001",
                "UITEST-CF-004",
                "UITEST-CF-007",
                "UITEST-CF-010",
            ]
        )
    }

    /// 讀回的訂單不套用任何條件時全部保留
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_不限條件_回傳全部十筆() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilter)

        // When
        let result = OrdersQuery.filteredOrders(
            orders: seeded.orders,
            selectedStatus: .all,
            selectedDatePeriod: .all,
            selectedCategories: [],
            selectedPaymentMethod: nil,
            searchText: "",
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(result.count == 10)
    }

    /// 分類篩選大量情境寫入 300 個商品類別與 30 種付款方式
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_大量分類情境_類別與付款方式數量符合規格() throws(any Error) {
        // Given
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }

        // When
        BLUITestSeedData.seed(
            .categoryFilterLarge,
            into: container,
            referenceDate: TestDependencies.fixedNow
        )

        // Then
        let context = ModelContext(container)
        let categoryCount = try context.fetchCount(FetchDescriptor<CategoryRecord>())
        let paymentMethodCount = try context.fetchCount(FetchDescriptor<PaymentMethodRecord>())
        #expect(categoryCount == 300)
        #expect(paymentMethodCount == 30)
    }

    /// 分類篩選大量情境寫入後，讀回一個開團與 300 筆訂單
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_大量分類情境_讀回一個開團與三百筆訂單() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilterLarge)

        // When
        let campaignCount = seeded.campaigns.count
        let orderCount = seeded.orders.count

        // Then
        #expect(campaignCount == 1)
        #expect(orderCount == 300)
    }

    /// 分類篩選大量情境讀回後，開團中類別為前五個，其餘 295 個屬已收單
    ///
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    @Test
    func seed_大量分類情境_開團中類別為前五個() throws(any Error) {
        // Given
        let seeded = try Self.readBack(.categoryFilterLarge)

        // When
        let groups = Self.groups(of: seeded)

        // Then
        let ongoing = Set(groups.first { $0.kind == .ongoing }?.categories ?? [])
        let closedCount = groups.first { $0.kind == .closed }?.categories.count ?? 0
        #expect(ongoing == ["類別 001", "類別 002", "類別 003", "類別 004", "類別 005"])
        #expect(closedCount == 295)
    }
}

// MARK: - Nested Types

extension BLUITestSeedDataTests {

    /// 讀回的測試種子資料組合
    struct SeededDataset {

        /// 開團清單
        let campaigns: [Campaign]

        /// 訂單清單
        let orders: [LedgerOrder]

        /// 商品類別清單
        let categories: [String]
    }
}

// MARK: - Private Method

private extension BLUITestSeedDataTests {

    /// 寫入指定情境至獨立測試 container 並讀回種子資料
    ///
    /// - Parameter profile: 要寫入的種子組合
    /// - Returns: 讀回後轉成領域型別的開團、訂單與商品類別名稱
    /// - Throws: 寫入或讀回 store 失敗時重新丟出 SwiftData 的錯誤
    /// - Note: 訂單與開團依識別值排序，讓讀回結果的順序與寫入時一致
    static func readBack(_ profile: BLUITestSeedProfile) throws(any Error) -> SeededDataset {
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        BLUITestSeedData.seed(profile, into: container, referenceDate: TestDependencies.fixedNow)

        let context = ModelContext(container)
        let campaigns = try context.fetch(FetchDescriptor<CampaignRecord>())
            .map { try $0.toDomain() }
            .sorted { lhs, rhs in lhs.id < rhs.id }
        let orders = try context.fetch(FetchDescriptor<OrderRecord>())
            .map { try $0.toDomain() }
            .sorted { lhs, rhs in lhs.id < rhs.id }
        let categories = try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name)
        return SeededDataset(campaigns: campaigns, orders: orders, categories: categories)
    }

    /// 計算讀回種子資料之分類分組
    ///
    /// - Parameter seeded: 讀回的種子資料
    /// - Returns: 開團中與已收單分組
    static func groups(of seeded: SeededDataset) -> [OrderCategoryGroups.Group] {
        OrderCategoryGroups.groups(
            categories: seeded.categories,
            orders: seeded.orders,
            campaigns: seeded.campaigns,
            context: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }
}

#endif
