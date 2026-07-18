//
//  RootFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct RootFeatureTests {

    // MARK: - Tests

    @Test func taskRestoresSettingsBeforeSettingsScreenIsVisited() async {
        var snapshot = SettingsSnapshot.default
        snapshot.language = .english
        snapshot.appearance = .dark
        let storedSnapshot = snapshot
        let refresh = RootTaskRefreshBox()

        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { storedSnapshot },
                save: { _ in }
            )
            $0[CurrencyMetadataRepository.self] = CurrencyMetadataRepository(
                fetchCodes: { CurrencyCode.defaults },
                refreshIfStale: { _ in
                    refresh.wasCalled = true
                    return false
                },
                forceRefresh: { }
            )
        }
        store.exhaustivity = .off

        await store.send(.task)
        await store.receive(.settings(.task)) {
            $0.settings.language = .english
            $0.settings.appearance = .dark
        }
        await store.finish()

        #expect(store.state.settings.language == .english)
        #expect(store.state.settings.appearance == .dark)
        #expect(refresh.wasCalled)
    }

    @Test func smartGroupSelectedJumpsToOrdersAndAppliesStatus() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(.smartGroupSelected(.shipping)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedOrderID = "BL-2604-018"
        }
    }

    @Test func smartGroupSelectedResetsDatePeriodAndPreviousStatus() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        // 預先設定殘留的類別篩選，驗證 smart group 跳轉會一併清掉它
        // 避免「狀態 + 類別」兩條條件夾擊出空列表
        state.orders.selectedCategory = "美妝"
        state.orders.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(.smartGroupSelected(.shipping)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedDatePeriod = .all
            $0.orders.selectedCategory = nil
            $0.orders.selectedOrderID = "BL-2604-018"
        }
    }

    @Test func smartGroupSelectionFlipsCorrespondingStatusChipPredicate() async {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(.smartGroupSelected(.purchased)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.purchased)
            $0.orders.selectedOrderID = "BL-2604-017"
        }

        // 確認對應 chip 的「isSelected」判定 (與 view 端 `store.selectedStatus == filter` 一致) 會翻成 true，
        // 其餘狀態 chip 維持 false，避免未來 reducer 變更時 UI 同步行為悄悄走樣
        let purchasedFilter = OrderStatusFilter.status(.purchased)
        #expect(store.state.orders.selectedStatus == purchasedFilter)

        let otherFilters: [OrderStatusFilter] = OrderStatusFilter.orderBrowsingCases
            .filter { $0 != purchasedFilter }
        for filter in otherFilters {
            #expect(store.state.orders.selectedStatus != filter)
        }
    }

    @Test func customerSelectedResetsResidualCategoryFilter() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders
        // 預先設定殘留的類別篩選，驗證客戶名深連結會清掉它
        // 避免在另一頁帶著舊類別狀態跳轉後撈不到任何訂單
        state.orders.selectedCategory = "精品"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(.customerSelected("Alice")) {
            $0.selectedTab = .orders
            $0.orders.searchText = "Alice"
            $0.orders.selectedCategory = nil
        }
    }

    @Test func categorySelectedJumpsToOrdersAndAppliesCategoryFilter() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders
        // 預先把幾個篩選器設成非預設值，驗證 categorySelected 會將它們一併重設
        // 避免「狀態 + 日期 + 搜尋」與類別深連結互卡
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.searchText = "stale query"
        state.orders.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // 從「分析」分頁點擊「美妝」類別 row → 切到「訂單」分頁、類別篩選膠囊套用「美妝」
        // 其餘篩選器全部歸零、選取為 filtered 後第一筆
        await store.send(.categorySelected("美妝")) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .all
            $0.orders.selectedDatePeriod = .all
            $0.orders.searchText = ""
            $0.orders.selectedCategory = "美妝"
            $0.orders.selectedOrderID = "BL-2604-018"
        }
    }

    @Test func categorySelectedFiltersOrdersByExactCategoryFieldNotSearchText() async {
        // 設計這組 fixture 讓「searchText 路徑」與「selectedCategory 路徑」結果不同：
        // - realBeauty1 / realBeauty2 的 category 欄位即 "美妝"，兩條路徑都會包進來
        // - falsePositive 的 category 是 "服飾"，但客戶名「美妝小編」會讓舊的 searchText="美妝" 模糊命中
        //   新的 selectedCategory="美妝" 走精準欄位比對，必須排除這筆訂單
        let realBeauty1 = Self.makeTestOrder(id: "TEST-BEAUTY-1", category: "美妝", customerName: "林書宇")
        let falsePositive = Self.makeTestOrder(id: "TEST-FALSE-1", category: "服飾", customerName: "美妝小編")
        let realBeauty2 = Self.makeTestOrder(id: "TEST-BEAUTY-2", category: "美妝", customerName: "Carol")

        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = [realBeauty1, falsePositive, realBeauty2]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(.categorySelected("美妝")) {
            $0.selectedTab = .orders
            $0.orders.selectedCategory = "美妝"
            $0.orders.selectedOrderID = "TEST-BEAUTY-1"
        }

        // 進一步以 filteredOrders 驗證 false-positive 確實被排除
        // 舊的 searchText 路徑會把 "美妝小編" 模糊命中、新的欄位精準比對不會
        let filteredIDs = store.state.orders
            .filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
            .map(\.id)
        #expect(filteredIDs == ["TEST-BEAUTY-1", "TEST-BEAUTY-2"])
    }

    @Test func editPaymentMethodCascadesRenameAndOverwritesFlagToOrdersState() async {
        // 編輯付款方式改名「匯款」→「銀行匯款」並取消銀行匯款旗標；
        // RootFeature 應 cascade 改名到 in-memory 訂單與 master，且最終旗標以使用者選擇 (false) 為準
        var order = RootFeatureTests.makeTestOrder(id: "BL-PM-EDIT", category: "美妝", customerName: "編輯測試")
        order = LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: "匯款",
            notes: order.notes,
            verificationStatus: order.verificationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: []
        )

        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.paymentMethodMaster = [
            PaymentMethodInfo(name: "匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
        ]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(
            .paymentMethodManagement(
                .editConfirmed(originalName: "匯款", name: "銀行匯款", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)
            )
        )
        await store.finish()

        // 訂單付款方式 cascade 改名
        #expect(store.state.orders.orders.first?.paymentMethod == "銀行匯款")
        // master 改名且旗標被權威覆寫為 false (不因 rename 合併而殘留 true)
        let renamed = store.state.orders.paymentMethodMaster.first { $0.name == "銀行匯款" }
        #expect(store.state.orders.paymentMethodMaster.contains { $0.name == "匯款" } == false)
        #expect(renamed?.isBankTransfer == false)
    }

    @Test func categoryRenameCascadesInsideMultiCategoryOrders() async {
        // 多類別訂單僅目標元素改名，其餘元素與順序不變；未含目標的訂單不受影響
        let multi = Self.makeTestOrder(id: "T-MULTI", categories: ["美妝", "服飾"], customerName: "客")
        let single = Self.makeTestOrder(id: "T-SINGLE", categories: ["服飾"], customerName: "客")

        var state = RootFeature.State()
        state.orders.orders = [multi, single]
        state.orders.categoryMaster = ["美妝", "服飾"]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.categoryManagement(.renameRequested(from: "美妝", to: "彩妝保養")))
        await store.finish()

        #expect(store.state.orders.orders.first { $0.id == "T-MULTI" }?.categories == ["彩妝保養", "服飾"])
        #expect(store.state.orders.orders.first { $0.id == "T-SINGLE" }?.categories == ["服飾"])
        #expect(store.state.orders.categoryMaster.contains("彩妝保養"))
        #expect(!store.state.orders.categoryMaster.contains("美妝"))
    }

    @Test func campaignRenameCascadesInsideMultiCampaignOrders() async {
        // 開團改名於陣列內逐元素取代 (in-memory 副本)；其餘元素不變
        let multi = Self.makeTestOrder(
            id: "T-CAMP",
            categories: ["美妝"],
            customerName: "客",
            campaignNames: ["三月日本團", "四月韓國團"]
        )

        var state = RootFeature.State()
        state.orders.orders = [multi]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.campaigns(.campaignRenamed(from: "三月日本團", to: "三月日本團 (補)")))
        await store.finish()

        #expect(store.state.orders.orders.first?.campaignNames == ["三月日本團 (補)", "四月韓國團"])
    }

    @Test func insightsDateRangeBindingUpdatesState() async {
        var state = RootFeature.State()
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(\.binding.insightsDateRange, .thirtyDays) {
            $0.insightsDateRange = .thirtyDays
        }
    }

    @Test func goToAISettingsDeepLinksToMoreTabAndSettings() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[SettingsStorage.self] = SettingsStorage(load: { .default }, save: { _ in })
        }
        store.exhaustivity = .off

        // 設定關閉時點「AI 總結」→ 出現提示 alert
        await store.send(.orders(.aiSummaryTapped))
        #expect(store.state.orders.aiDisabledAlert != nil)

        // 點「前往開啟」→ root 攔截並切到「更多」分頁、要求 push 設定頁
        await store.send(.orders(.aiDisabledAlert(.presented(.goToAISettings))))
        #expect(store.state.selectedTab == .more)
        #expect(store.state.showsSettingsFromDeepLink == true)
    }
}

/// 記錄 Root 啟動 task 是否保留幣別 cache refresh effect
private final class RootTaskRefreshBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 是否呼叫過 refresh
    var wasCalled = false
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 建立用於跨頁深連結測試的最小化訂單；除了 `id`、`category`、`customerName` 之外，其餘欄位採可預測的中性預設
    ///
    /// 避免汙染篩選器斷言
    /// - Parameters:
    ///   - id: 訂單編號
    ///   - category: 商品類別欄位 (測試精準欄位比對的關鍵欄位)
    ///   - customerName: 客戶名稱 (用於塞入會被舊 `searchText` 路徑模糊命中的字串)
    /// - Returns: 可塞進 `OrdersFeature.State.orders` 的訂單實例
    static func makeTestOrder(
        id: String,
        category: String,
        customerName: String
    ) -> LedgerOrder {
        makeTestOrder(id: id, categories: [category], customerName: customerName)
    }

    /// 多類別/多開團版本的測試訂單 helper
    static func makeTestOrder(
        id: String,
        categories: [String],
        customerName: String,
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "TC", tier: .new),
            status: .purchased,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "測試",
            categories: categories,
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
