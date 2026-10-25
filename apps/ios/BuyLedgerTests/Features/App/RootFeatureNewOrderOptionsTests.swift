//
//  RootFeatureNewOrderOptionsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證從總覽與訂單分頁新增訂單時，表單帶入的主檔、進行中開團與幣別
@MainActor
struct RootFeatureNewOrderOptionsTests {

    /// 驗證從總覽頁開新訂單時，表單的來源、類別、付款方式與對帳狀態選項與訂單分頁相同，且只列出進行中的開團
    ///
    /// - Throws: 新訂單表單未呈現時由 `#require` 丟出測試斷言錯誤
    @Test
    func dashboard_總覽新增訂單_帶入相同主檔與進行中開團() async throws {
        // Given
        let method = PaymentMethodInfo(
            name: "信用卡",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let usedMethod = PaymentMethodInfo(
            name: "現金",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        var initial = Self.makeNewOrderCatalogState(method: method)
        initial.selectedTab = .dashboard
        let expectedOptions = OrderEditOptions(
            orderSources: ["IG", "LINE", "蝦皮"],
            categories: ["美妝", "服飾", "精品"],
            paymentMethods: [method, usedMethod],
            reconciliationStatuses: ["已對帳", "待對帳"],
            campaigns: ["May-JP"],
            currencyCodes: [.twd, .jpy, CurrencyCode(rawValue: "EUR")],
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped))) {
            $0.selectedTab = .orders
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: expectedOptions,
                    currentDate: TestDependencies.fixedNow
                )
            )
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        let edit = try #require(store.state.orders.presentation.destination?.edit)
        #expect(Set(edit.pickers.options.orderSources) == ["IG", "LINE", "蝦皮"])
        #expect(Set(edit.pickers.options.categories) == ["美妝", "服飾", "精品"])
        #expect(edit.pickers.options.paymentMethods == [method, usedMethod])
        #expect(edit.pickers.options.reconciliationStatuses == ["已對帳", "待對帳"])
        #expect(
            store.state.orders.presentation.destination?.edit?.pickers.options.campaigns
                == ["May-JP"]
        )
        #expect(store.state.orders.presentation.destination?.edit?.draft.campaignNames == [])
        #expect(store.state.more.catalog.catalog.categories == ["美妝", "服飾"])
        #expect(store.state.launch.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
    }

    /// 驗證從訂單分頁開新訂單時，表單的來源、類別、付款方式與對帳狀態選項與總覽頁相同，且只列出進行中的開團
    ///
    /// - Throws: 新訂單表單未呈現時由 `#require` 丟出測試斷言錯誤
    @Test
    func orders_訂單分頁新增訂單_帶入相同主檔與進行中開團() async throws {
        // Given
        let method = PaymentMethodInfo(
            name: "信用卡",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let usedMethod = PaymentMethodInfo(
            name: "現金",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        var initial = Self.makeNewOrderCatalogState(method: method)
        initial.selectedTab = .orders
        let expectedOptions = OrderEditOptions(
            orderSources: ["IG", "LINE", "蝦皮"],
            categories: ["美妝", "服飾", "精品"],
            paymentMethods: [method, usedMethod],
            reconciliationStatuses: ["已對帳", "待對帳"],
            campaigns: ["May-JP"],
            currencyCodes: [.twd, .jpy, CurrencyCode(rawValue: "EUR")],
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.create))))) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: expectedOptions,
                    currentDate: TestDependencies.fixedNow
                )
            )
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        let edit = try #require(store.state.orders.presentation.destination?.edit)
        #expect(Set(edit.pickers.options.orderSources) == ["IG", "LINE", "蝦皮"])
        #expect(Set(edit.pickers.options.categories) == ["美妝", "服飾", "精品"])
        #expect(edit.pickers.options.paymentMethods == [method, usedMethod])
        #expect(edit.pickers.options.reconciliationStatuses == ["已對帳", "待對帳"])
        #expect(
            store.state.orders.presentation.destination?.edit?.pickers.options.campaigns
                == ["May-JP"]
        )
        #expect(store.state.orders.presentation.destination?.edit?.draft.campaignNames == [])
        #expect(store.state.more.catalog.catalog.categories == ["美妝", "服飾"])
        #expect(store.state.launch.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
    }

    /// 驗證新訂單的幣別選項使用啟動時載入的共用清單，清單為空時退回預設的常用幣別
    ///
    /// - Parameter scenario: 啟動載入後的共用幣別清單與表單中依代碼排序的幣別選項
    @Test(arguments: CurrencyOptionCase.allCases)
    func orders_共用幣別清單非空或為空_帶入快取或常用幣別(scenario: CurrencyOptionCase) async {
        // Given
        let initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.launch.$currencyCodes.withLock {
            $0 = scenario.codes
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }
        let options = OrderEditOptions(
            currencyCodes: scenario.expectedCodes.map { CurrencyCode(rawValue: $0) },
            calendar: TestDependencies.fixedCalendar
        )

        // When
        await store.send(.orders(.list(.delegate(.requested(.create))))) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: options,
                    currentDate: TestDependencies.fixedNow
                )
            )
        }

        // Then
        await store.finish()
        #expect(store.state.launch.currencyCodes == scenario.codes)
        let pickerCodes = store.state.orders.presentation.destination?.edit?.pickers
            .options.currencyCodes.map(\.rawValue)
        #expect(pickerCodes == scenario.expectedCodes)
    }

    /// 驗證從總覽頁開新訂單時，依現在時間判斷結單日，已過結單日的開團不列入可選清單
    ///
    /// - Throws: 指定日期無法建立時由 `try #require` 丟出
    @Test
    func dashboard_總覽新增訂單且結單日已過_排除過期開團() async throws {
        // Given
        let calendar = TestDependencies.fixedCalendar
        let closingDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 31))
        )
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let expired = Campaign.fixture(name: "May-JP", closeDate: closingDate)
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.selectedTab = .dashboard
        initial.orders.$campaigns.withLock {
            $0 = [expired]
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped))) {
            $0.selectedTab = .orders
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(calendar: calendar),
                    currentDate: now
                )
            )
        }

        // Then
        await store.finish()
        #expect(store.state.orders.presentation.destination?.edit?.pickers.options.campaigns == [])
        #expect(store.state.orders.campaigns == [expired])
    }

    /// 驗證從訂單分頁開新訂單時，依現在時間判斷結單日，已過結單日的開團不列入可選清單
    ///
    /// - Throws: 指定日期無法建立時由 `try #require` 丟出
    @Test
    func orders_訂單分頁新增訂單且結單日已過_排除過期開團() async throws {
        // Given
        let calendar = TestDependencies.fixedCalendar
        let closingDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 31))
        )
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let expired = Campaign.fixture(name: "May-JP", closeDate: closingDate)
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.selectedTab = .orders
        initial.orders.$campaigns.withLock {
            $0 = [expired]
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.create))))) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(calendar: calendar),
                    currentDate: now
                )
            )
        }

        // Then
        await store.finish()
        #expect(store.state.orders.presentation.destination?.edit?.pickers.options.campaigns == [])
        #expect(store.state.orders.campaigns == [expired])
    }
}

// MARK: - Nested Types

extension RootFeatureNewOrderOptionsTests {

    /// 一組測試案例，含啟動載入後的共用幣別清單與表單預期的幣別選項
    struct CurrencyOptionCase: Sendable {

        /// 共用清單非空時沿用清單、為空時退回常用幣別的兩種案例
        static let allCases = [
            Self(
                codes: [.twd, .jpy, CurrencyCode(rawValue: "EUR")],
                expectedCodes: ["EUR", "JPY", "TWD"]
            ),
            Self(codes: [], expectedCodes: ["CNY", "JPY", "KRW", "TWD", "USD"]),
        ]

        /// 啟動載入後的共用幣別清單
        let codes: [CurrencyCode]

        /// 表單中依代碼排序的幣別選項
        let expectedCodes: [String]
    }
}

// MARK: - Private Method

private extension RootFeatureNewOrderOptionsTests {

    /// 建立已有來源、類別、付款方式、對帳狀態、幣別與開團的根狀態，供新訂單選項測試使用
    ///
    /// - Parameter method: 主檔中已登錄的付款方式
    /// - Returns: 帶有主檔、幣別、訂單與開團資料的根狀態
    static func makeNewOrderCatalogState(method: PaymentMethodInfo) -> RootFeature.State {
        let initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.more.catalog.$catalog.withLock {
            $0.orderSources = ["IG", "LINE"]
            $0.categories = ["美妝", "服飾"]
            $0.paymentMethods = [method]
            $0.reconciliationStatuses = ["已對帳"]
        }
        initial.launch.$currencyCodes.withLock {
            $0 = [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
        }
        initial.orders.$orders.withLock {
            $0 = [
                LedgerOrder.fixture(
                    orderSource: "蝦皮",
                    categories: ["精品"],
                    paymentMethod: "現金",
                    reconciliationStatus: "待對帳"
                ),
            ]
        }
        initial.orders.$campaigns.withLock {
            $0 = [
                Campaign.fixture(id: "MAY", name: "May-JP"),
                Campaign.fixture(id: "APRIL", name: "April-KR", status: .closed),
            ]
        }
        return initial
    }
}
