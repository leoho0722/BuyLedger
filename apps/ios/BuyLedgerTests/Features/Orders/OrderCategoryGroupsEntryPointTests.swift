//
//  OrderCategoryGroupsEntryPointTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/19.
//

import Testing

@testable import BuyLedger

/// `OrderCategoryGroups.groups` 的單元測試，涵蓋主檔與訂單類別的合併、歸組與排序
struct OrderCategoryGroupsEntryPointTests {

    /// 驗證只出現在主檔、未被任何訂單使用的類別，歸入已收單組
    @Test
    func groups_只有主檔類別_歸入已收單() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let catalog = LookupCatalog(categories: ["書籍"])

        // When
        let groups = OrderCategoryGroups.groups(
            orders: [],
            campaigns: [],
            catalog: catalog,
            context: context
        )

        // Then
        #expect(groups == [OrderCategoryGroups.Group(kind: .closed, categories: ["書籍"])])
    }

    /// 驗證訂單類別去除前後空白與換行後，同名的類別合併為一筆，空白或空字串的類別則排除在外
    @Test
    func groups_訂單類別含前後空白_去除空白並合併同名類別() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: [" \n書籍\t ", "書籍", " \n\t ", ""]),
        ]

        // When
        let groups = OrderCategoryGroups.groups(
            orders: orders,
            campaigns: [],
            catalog: LookupCatalog(),
            context: context
        )

        // Then
        #expect(groups == [OrderCategoryGroups.Group(kind: .closed, categories: ["書籍"])])
    }

    /// 驗證進行中開團的訂單類別去除前後空白後歸入開團中組，未關聯進行中開團的類別歸入已收單組
    @Test
    func groups_進行中開團的類別含前後空白_去除空白後歸入開團中() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let campaigns = [Campaign.fixture(id: "spring", name: "春季團", status: .ongoing)]
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: [" 美妝 "], campaignNames: ["春季團"]),
            LedgerOrder.fixture(id: "O2", categories: ["書籍"]),
        ]

        // When
        let groups = OrderCategoryGroups.groups(
            orders: orders,
            campaigns: campaigns,
            catalog: LookupCatalog(),
            context: context
        )

        // Then
        #expect(
            groups == [
                OrderCategoryGroups.Group(kind: .ongoing, categories: ["美妝"]),
                OrderCategoryGroups.Group(kind: .closed, categories: ["書籍"]),
            ]
        )
    }

    /// 驗證主檔與訂單的類別合併後各歸一組，只要有訂單把類別關聯到進行中開團，該類別就只留在開團中
    @Test
    func groups_主檔與訂單類別混合_合併後依開團分組() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let campaigns = [Campaign.fixture(id: "spring", name: "春季團", status: .ongoing)]
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: ["beauty"], campaignNames: ["春季團"]),
            LedgerOrder.fixture(id: "O2", categories: [" snacks ", "beauty", " \n "]),
        ]
        let catalog = LookupCatalog(categories: ["catalog-only", "beauty"])

        // When
        let groups = OrderCategoryGroups.groups(
            orders: orders,
            campaigns: campaigns,
            catalog: catalog,
            context: context
        )

        // Then
        #expect(
            groups == [
                OrderCategoryGroups.Group(kind: .ongoing, categories: ["beauty"]),
                OrderCategoryGroups.Group(kind: .closed, categories: ["catalog-only", "snacks"]),
            ]
        )
    }

    /// 驗證類別輸入未排序時，各組內依 `localizedStandardCompare` 排序，3C 排在 snacks 之前
    @Test
    func groups_未排序類別輸入_各組內依語言排序() {
        // Given
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let campaigns = [Campaign.fixture(id: "spring", name: "春季團", status: .ongoing)]
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: ["snacks", "3C"], campaignNames: ["春季團"]),
            LedgerOrder.fixture(id: "O2", categories: ["beauty"]),
        ]
        let categories = ["snacks", "beauty", "3C"]

        // When
        let groups = OrderCategoryGroups.groups(
            categories: categories,
            orders: orders,
            campaigns: campaigns,
            context: context
        )

        // Then
        #expect(
            groups == [
                OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "snacks"]),
                OrderCategoryGroups.Group(kind: .closed, categories: ["beauty"]),
            ]
        )
    }
}
