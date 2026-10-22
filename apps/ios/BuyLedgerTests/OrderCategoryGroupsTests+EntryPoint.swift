//
//  OrderCategoryGroupsTests+EntryPoint.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/19.
//

import Testing

@testable import BuyLedger

extension OrderCategoryGroupsTests {

    /// 將只有主檔提供且未被訂單使用的類別歸入已收單
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

    /// 移除訂單類別前後的空白與換行，並排除空白名稱
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

    /// 將進行中開團的訂單類別去掉前後空白後，與未歸團類別分開歸組
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

    /// 合併主檔與訂單提供的類別，依開團狀態產生固定分組
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

    /// 未排序的類別輸入，各組內仍依語言排序
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
