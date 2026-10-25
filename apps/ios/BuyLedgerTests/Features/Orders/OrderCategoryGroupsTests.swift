//
//  OrderCategoryGroupsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderCategoryGroups` 的單元測試，涵蓋開團活動分組與組內排序
struct OrderCategoryGroupsTests {

    /// 驗證依規格範例表計算時，分組結果與組內筆畫排序都符合預期
    @Test
    func groups_開團活動範例表_產生預期分組與排序() {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: fixture.categories,
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )

        // Then
        #expect(
            groups == [
                OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "美妝", "零食"]),
                OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
            ]
        )
    }

    /// 驗證規格範例表中的每個類別，都歸入其預期的組別
    ///
    /// - Parameter testCase: 類別名稱與預期歸屬的組別
    @Test(arguments: [
        CategoryKindCase(category: "3C", expectedKind: .ongoing),
        CategoryKindCase(category: "美妝", expectedKind: .ongoing),
        CategoryKindCase(category: "零食", expectedKind: .ongoing),
        CategoryKindCase(category: "保健", expectedKind: .closed),
        CategoryKindCase(category: "書籍", expectedKind: .closed),
        CategoryKindCase(category: "精品", expectedKind: .closed),
        CategoryKindCase(category: "食品", expectedKind: .closed),
    ])
    func groups_開團活動範例表每列類別_歸入預期組別(testCase: CategoryKindCase) {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: fixture.categories,
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )
        let group = groups.first { $0.categories.contains(testCase.category) }

        // Then
        #expect(group?.kind == testCase.expectedKind)
    }

    /// 驗證開團原本即為已收單時，即使結單日晚於現在，類別仍歸入已收單組，不改為開團中
    @Test
    func groups_原本已收單開團之結單日在未來_仍維持已收單() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let futureClosedCampaign = Campaign.fixture(
            id: "future-closed",
            name: "未來已結團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_778_803_200),
            status: .closed
        )
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: ["美妝"], campaignNames: ["未來已結團"]),
        ]

        // When
        let groups = OrderCategoryGroups.groups(
            categories: ["美妝"],
            orders: orders,
            campaigns: [futureClosedCampaign],
            context: context
        )

        // Then
        #expect(groups == [OrderCategoryGroups.Group(kind: .closed, categories: ["美妝"])])
    }

    /// 驗證訂單關聯的開團名稱不在開團清單中時，類別歸入已收單組，不視為進行中
    @Test
    func groups_訂單關聯未知名稱之開團_歸入已收單() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: ["精品"], campaignNames: ["不存在的開團"]),
        ]

        // When
        let groups = OrderCategoryGroups.groups(
            categories: ["精品"],
            orders: orders,
            campaigns: [],
            context: context
        )

        // Then
        #expect(groups == [OrderCategoryGroups.Group(kind: .closed, categories: ["精品"])])
    }

    /// 驗證可用類別為空時，即使訂單與開團都有資料，仍回傳空陣列
    @Test
    func groups_可用類別為空_回傳空陣列() {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: [],
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )

        // Then
        #expect(groups.isEmpty)
    }

    /// 驗證可用類別只有美妝，且其訂單關聯進行中的春季團時，只回傳開團中組
    @Test
    func groups_僅單一進行中類別_僅回傳開團中組() {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: ["美妝"],
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )

        // Then
        #expect(groups == [OrderCategoryGroups.Group(kind: .ongoing, categories: ["美妝"])])
    }

    /// 驗證可用類別全部屬於進行中開團時，只回傳開團中組，不回傳已收單組
    @Test
    func groups_所有類別皆為開團中_不回傳已收單組() {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: ["3C", "美妝", "零食"],
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )

        // Then
        #expect(
            groups == [
                OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "美妝", "零食"]),
            ]
        )
    }

    /// 驗證可用類別全部屬於已收單時，只回傳已收單組，不回傳開團中組
    @Test
    func groups_所有類別皆為已收單_不回傳開團中組() {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: ["保健", "書籍"],
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )

        // Then
        #expect(groups == [OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "書籍"])])
    }
}

// MARK: - Nested Types

extension OrderCategoryGroupsTests {

    /// 範例表分組測試的單一案例，含類別名稱與預期的組別種類
    struct CategoryKindCase: Sendable {

        /// 測試類別名稱
        let category: String

        /// 預期歸屬的組別種類
        let expectedKind: OrderCategoryGroups.Kind
    }

    /// `makeSpecFixture` 回傳的測試夾具，含日期脈絡、開團、訂單與可用類別
    private struct SpecFixture {

        /// 注入的日期脈絡
        let context: OrderDateContext

        /// 開團清單
        let campaigns: [Campaign]

        /// 訂單清單
        let orders: [LedgerOrder]

        /// 可用類別清單
        let categories: [String]
    }
}

// MARK: - Private Method

private extension OrderCategoryGroupsTests {

    /// 依規格範例表建立測試用的日期脈絡、開團、訂單與可用類別
    ///
    /// - Returns: 組裝好的測試夾具資料
    private static func makeSpecFixture() -> SpecFixture {
        let calendar = TestDependencies.fixedCalendar
        let now = TestDependencies.fixedNow
        let context = OrderDateContext(now: now, calendar: calendar)

        let spring = Campaign.fixture(
            id: "spring",
            name: "春季團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_778_803_200),
            status: .ongoing
        )

        let winter = Campaign.fixture(
            id: "winter",
            name: "冬季團",
            openDate: Date(timeIntervalSince1970: 1_767_225_600),
            closeDate: Date(timeIntervalSince1970: 1_769_817_600),
            status: .closed
        )

        let old = Campaign.fixture(
            id: "old",
            name: "舊團",
            openDate: Date(timeIntervalSince1970: 1_772_323_200),
            closeDate: Date(timeIntervalSince1970: 1_776_211_200),
            status: .ongoing
        )

        let orders = [
            LedgerOrder.fixture(id: "O1", categories: ["美妝"], campaignNames: ["春季團"]),
            LedgerOrder.fixture(id: "O2", categories: ["3C", "零食"], campaignNames: ["冬季團", "春季團"]),
            LedgerOrder.fixture(id: "O3", categories: ["精品"], campaignNames: ["冬季團"]),
            LedgerOrder.fixture(id: "O4", categories: ["食品"], campaignNames: ["舊團"]),
            LedgerOrder.fixture(id: "O5", categories: ["書籍"], campaignNames: []),
            LedgerOrder.fixture(id: "O6", categories: ["精品"], campaignNames: ["已刪除團"]),
        ]

        let categories = ["3C", "保健", "美妝", "食品", "書籍", "零食", "精品"]

        return SpecFixture(
            context: context,
            campaigns: [spring, winter, old],
            orders: orders,
            categories: categories
        )
    }
}
