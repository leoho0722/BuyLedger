//
//  RootFeatureTests+NewOrderOptions.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 從總覽頁開新訂單，表單的來源、類別、付款方式與對帳狀態選項與訂單分頁相同，並只列出進行中的開團
    @Test
    func dashboard_總覽新增訂單_帶入相同主檔與進行中開團() async {
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
        let sources = Set(
            store.state.orders.presentation.destination?.edit?.pickers.options.orderSources ?? []
        )
        #expect(sources == ["IG", "LINE", "蝦皮"])
        let categories = Set(
            store.state.orders.presentation.destination?.edit?.pickers.options.categories ?? []
        )
        #expect(categories == ["美妝", "服飾", "精品"])
        #expect(
            store.state.orders.presentation.destination?.edit?.pickers.options.campaigns
                == ["May-JP"]
        )
        #expect(store.state.orders.presentation.destination?.edit?.draft.campaignNames == [])
        #expect(store.state.more.catalog.catalog.categories == ["美妝", "服飾"])
        #expect(store.state.launch.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
    }

    /// 從訂單分頁開新訂單，表單的來源、類別、付款方式與對帳狀態選項與總覽頁相同，並只列出進行中的開團
    @Test
    func orders_訂單分頁新增訂單_帶入相同主檔與進行中開團() async {
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
        let sources = Set(
            store.state.orders.presentation.destination?.edit?.pickers.options.orderSources ?? []
        )
        #expect(sources == ["IG", "LINE", "蝦皮"])
        let categories = Set(
            store.state.orders.presentation.destination?.edit?.pickers.options.categories ?? []
        )
        #expect(categories == ["美妝", "服飾", "精品"])
        #expect(
            store.state.orders.presentation.destination?.edit?.pickers.options.campaigns
                == ["May-JP"]
        )
        #expect(store.state.orders.presentation.destination?.edit?.draft.campaignNames == [])
        #expect(store.state.more.catalog.catalog.categories == ["美妝", "服飾"])
        #expect(store.state.launch.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
    }

    /// 新訂單的幣別選項使用啟動時載入的共用清單；清單為空時退回預設的常用幣別
    ///
    /// - Parameters:
    ///   - codes: 啟動載入後的共用幣別清單
    ///   - expectedCodes: 表單中依代碼排序的幣別選項
    @Test(arguments: [
        ([CurrencyCode.twd, .jpy, CurrencyCode(rawValue: "EUR")], ["EUR", "JPY", "TWD"]),
        ([], ["CNY", "JPY", "KRW", "TWD", "USD"]),
    ])
    func orders_共用幣別清單非空或為空_帶入快取或常用幣別(codes: [CurrencyCode], expectedCodes: [String]) async {
        // Given
        let initial = Self.makeIsolatedRootState()
        initial.launch.$currencyCodes.withLock {
            $0 = codes
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }
        let options = OrderEditOptions(
            currencyCodes: expectedCodes.map { CurrencyCode(rawValue: $0) },
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
        #expect(store.state.launch.currencyCodes == codes)
        let pickerCodes = store.state.orders.presentation.destination?.edit?.pickers
            .options.currencyCodes.map(\.rawValue)
        #expect(pickerCodes == expectedCodes)
    }

    /// 從總覽頁開新訂單時依現在時間判斷結單日，已過結單日的開團不再列入可選清單
    ///
    /// - Throws: 指定日期無法建立時由 `#require` 丟出
    @Test
    func dashboard_總覽新增訂單且結單日已過_排除過期開團() async throws {
        // Given
        let calendar = TestDependencies.fixedCalendar
        let closingDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 31))
        )
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let expired = Campaign.fixture(name: "May-JP", closeDate: closingDate)
        var initial = Self.makeIsolatedRootState()
        initial.selectedTab = .dashboard
        initial.orders.campaigns = [expired]
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

    /// 從訂單分頁開新訂單時依現在時間判斷結單日，已過結單日的開團不再列入可選清單
    ///
    /// - Throws: 指定日期無法建立時由 `#require` 丟出
    @Test
    func orders_訂單分頁新增訂單且結單日已過_排除過期開團() async throws {
        // Given
        let calendar = TestDependencies.fixedCalendar
        let closingDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 31))
        )
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let expired = Campaign.fixture(name: "May-JP", closeDate: closingDate)
        var initial = Self.makeIsolatedRootState()
        initial.selectedTab = .orders
        initial.orders.campaigns = [expired]
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

// MARK: - Private Method

private extension RootFeatureTests {

    /// 建立已有來源、類別、付款方式、對帳狀態、幣別與開團的根狀態，供新訂單選項測試使用
    ///
    /// - Parameter method: 主檔中已登錄的付款方式
    /// - Returns: 帶有主檔、幣別、訂單與開團資料的根狀態
    static func makeNewOrderCatalogState(method: PaymentMethodInfo) -> RootFeature.State {
        var initial = Self.makeIsolatedRootState()
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
        initial.orders.campaigns = [
            Campaign.fixture(id: "MAY", name: "May-JP"),
            Campaign.fixture(id: "APRIL", name: "April-KR", status: .closed),
        ]
        return initial
    }
}
