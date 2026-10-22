//
//  OrderCategoryGroupsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證 `OrderCategoryGroups` 的開團活動分組與組內排序邏輯
struct OrderCategoryGroupsTests {

    /// 依 spec 範例表驗證完整分組結果與組內筆畫排序
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

    /// 逐列驗證 spec 範例表中各類別歸入之組別
    ///
    /// - Parameters:
    ///   - category: 測試類別名稱
    ///   - expectedKind: 預期歸屬的組別種類
    @Test(arguments: [
        ("3C", OrderCategoryGroups.Kind.ongoing),
        ("美妝", OrderCategoryGroups.Kind.ongoing),
        ("零食", OrderCategoryGroups.Kind.ongoing),
        ("保健", OrderCategoryGroups.Kind.closed),
        ("書籍", OrderCategoryGroups.Kind.closed),
        ("精品", OrderCategoryGroups.Kind.closed),
        ("食品", OrderCategoryGroups.Kind.closed),
    ])
    func groups_開團活動範例表每列類別_歸入預期組別(category: String, expectedKind: OrderCategoryGroups.Kind) {
        // Given
        let fixture = Self.makeSpecFixture()

        // When
        let groups = OrderCategoryGroups.groups(
            categories: fixture.categories,
            orders: fixture.orders,
            campaigns: fixture.campaigns,
            context: fixture.context
        )
        let group = groups.first { $0.categories.contains(category) }

        // Then
        #expect(group?.kind == expectedKind)
    }

    /// 原本即為 `closed` 的開團即使結單日晚於現在時間，仍維持 `closed` 不變為進行中
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

    /// 訂單關聯的開團名稱不存在於已知開團清單時，不視為進行中
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

    /// 可用類別為空陣列時，回傳空的分組清單
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

    /// 僅有單一類別且所屬開團進行中時，僅回傳開團中組
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

    /// 所有可用類別皆屬於進行中開團時，不回傳已收單組
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

    /// 所有可用類別皆屬於已收單時，不回傳開團中組
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

    /// spec 測試夾具資料型別
    struct SpecFixture {

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

    /// 依 spec 規格範例建立測試用日期脈絡、開團清單與訂單清單
    ///
    /// - Returns: 組裝好的測試夾具資料
    static func makeSpecFixture() -> SpecFixture {
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
