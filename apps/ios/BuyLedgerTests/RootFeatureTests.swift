//
//  RootFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證根功能的導覽與跨功能同步
@MainActor
struct RootFeatureTests {
    
    // MARK: - Tests
    
    @Test func degradedPersistenceOutcomeStartsWithBlockingFailureState() {
        let state = RootFeature.State(persistenceOutcome: .degraded(reason: "Unable to open store"))
        
        #expect(state.persistenceFailure != nil)
        #expect(state.persistenceFailure?.phase == .blocked)
    }
    
    @Test func healthyPersistenceOutcomeDoesNotBlockNormalLayout() {
        let state = RootFeature.State()
        
        #expect(state.persistenceFailure == nil)
    }
    
    /// 帳本保護開啟時，建構 State 即進入鎖定狀態
    @Test func protectionEnabledAtLaunchStartsLocked() {
        let state = RootFeature.State(isBiometricUnlockEnabled: true)
        
        #expect(state.settings.appLock.isBiometricUnlockEnabled)
        #expect(state.settings.appLock.isLocked)
    }
    
    @Test func protectionDisabledAtLaunchStartsUnlocked() {
        let state = RootFeature.State()
        
        #expect(state.settings.appLock.isBiometricUnlockEnabled == false)
        #expect(state.settings.appLock.isLocked == false)
    }
    
    @Test func taskRestoresSettingsBeforeSettingsScreenIsVisited() async {
        var snapshot = SettingsSnapshot.default
        snapshot.language = .english
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
                fetchCodes: { () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode] in
                    throw CurrencyMetadataRepositoryError.persistence(
                        .storage(.fetchFailed(message: "suppressed"))
                    )
                },
                refreshIfStale: { _ in
                    refresh.wasCalled = true
                    return false
                },
                forceRefresh: {}
            )
        }
        await store.send(.task)
        await store.receive(.settings(.task)) {
            $0.settings.language = .english
        }
        // `appDidBecomeActive` 一律查詢 `biometryType`。
        // 保護關閉時僅此欄位變化，不觸發驗證流程
        await store.receive(\.settings.appLock.appDidBecomeActive) {
            $0.settings.appLock.biometryType = .faceID
        }
        await store.finish()
        
        #expect(store.state.settings.language == .english)
        #expect(refresh.wasCalled)
    }
    
    /// 重啟後一律回到總覽分頁
    @Test func taskKeepsTheDashboardTabAsTheLaunchTab() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(load: { .default }, save: { _ in })
            $0[CurrencyMetadataRepository.self] = CurrencyMetadataRepository(
                fetchCodes: { () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode] in
                    throw CurrencyMetadataRepositoryError.persistence(
                        .storage(.fetchFailed(message: "suppressed"))
                    )
                },
                refreshIfStale: { _ in false },
                forceRefresh: {}
            )
        }
        await store.send(.task)
        // 預設設定與 state 相同，因此不會產生變化
        await store.receive(\.settings.task)
        // 保護關閉時只更新 biometryType。
        await store.receive(\.settings.appLock.appDidBecomeActive) {
            $0.settings.appLock.biometryType = .faceID
        }
        await store.finish()
        
        #expect(store.state.selectedTab == .dashboard)
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
    
    /// 智慧分組只切換狀態篩選，不靜默覆寫使用者既有的日期區間與類別篩選
    @Test func smartGroupSelectedOnlySwitchesTheStatusFilter() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.selectedCategory = "美妝"
        state.orders.selectedOrderID = "BL-2604-016"
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        var expectedOrders = state.orders
        expectedOrders.selectedStatus = .status(.shipping)
        let expectedSelectedOrderID =
            expectedOrders
            .filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            )
            .first?.id
        await store.send(.smartGroupSelected(.shipping)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedOrderID = expectedSelectedOrderID
        }
        
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(.shipping))
        #expect(store.state.orders.selectedDatePeriod == .thisMonth)
        #expect(store.state.orders.selectedCategory == "美妝")
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
        
        // 驗證選取狀態會同步到對應篩選 chip
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
        
        // 從分析頁點擊類別後，切到訂單頁並套用篩選。
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
        // category 篩選只比對 category 欄位，不會誤中客戶名稱
        let realBeauty1 = Self.makeTestOrder(
            id: "TEST-BEAUTY-1", category: "美妝", customerName: "林書宇")
        let falsePositive = Self.makeTestOrder(
            id: "TEST-FALSE-1", category: "服飾", customerName: "美妝小編")
        let realBeauty2 = Self.makeTestOrder(
            id: "TEST-BEAUTY-2", category: "美妝", customerName: "Carol")
        
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
            .filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            )
            .map(\.id)
        #expect(filteredIDs == ["TEST-BEAUTY-1", "TEST-BEAUTY-2"])
    }
    
    @Test func paymentMethodEditSuccessForwardsTheSameNormalizedOrdersToOrdersFeature() async {
        // 只有寫入成功後才同步主檔，並轉送同一份資料
        var order = RootFeatureTests.makeTestOrder(
            id: "BL-PM-EDIT", category: "美妝", customerName: "編輯測試")
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
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: "匯款",
            notes: order.notes,
            reconciliationStatus: "待對帳",
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: true,
            photos: order.photos,
            mergedSourceIDs: []
        )
        
        let corrected =
            order
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        let plan = LookupManagementFeature.PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            flagsChanged: true,
            affectedOrders: [corrected]
        )
        
        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock {
            $0.paymentMethods = [
                PaymentMethodInfo(
                    name: "匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
            ]
        }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        
        await store.send(
            .lookupManagements(
                .element(id: .paymentMethod, action: .paymentMethodEditSucceeded(plan)))
        ) {
            $0.orders.$lookupCatalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "銀行匯款", isCardless: false, isBankTransfer: false,
                        isCashOnDelivery: false)
                ]
            }
        }
        
        await store.receive(\.orders.paymentMethodFlagsApplied) {
            $0.orders.orders = [corrected]
            $0.customers.orders = [corrected]
            $0.campaigns.orders = [corrected]
            $0.dashboard.orders = [corrected]
            $0.insights.orders = [corrected]
        }
        
        #expect(store.state.orders.orders == [corrected])
        #expect(
            store.state.orders.paymentMethodMaster == [
                PaymentMethodInfo(
                    name: "銀行匯款", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)
            ])
        // 主檔管理清單應同步反映新名稱與旗標。
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["銀行匯款"])
        #expect(
            store.state.lookupManagements[id: .paymentMethod]?.paymentMethodIsBankTransfer == [
                "銀行匯款": false
            ])
        #expect(
            store.state.lookupManagements[id: .paymentMethod]?.paymentMethodIsCardless == [
                "銀行匯款": false
            ])
        #expect(
            store.state.lookupManagements[id: .paymentMethod]?.paymentMethodIsCashOnDelivery == [
                "銀行匯款": false
            ])
    }
    
    @Test func paymentMethodEditCancellationLeavesRootOrdersAndMasterUnchanged() async {
        let original = Self.makeTestOrder(id: "BL-PM-CANCEL", category: "美妝", customerName: "取消測試")
            .renamingPaymentMethod(to: "匯款")
        let corrected =
            original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        let plan = LookupManagementFeature.PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            flagsChanged: true,
            affectedOrders: [corrected]
        )
        let originalMaster = PaymentMethodInfo(
            name: "匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
        
        var state = RootFeature.State()
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock { $0.paymentMethods = [originalMaster] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        await store.send(
            .lookupManagements(
                .element(id: .paymentMethod, action: .paymentMethodEditPrepared(plan)))
        ) {
            $0.lookupManagements[id: .paymentMethod]?.pendingPaymentMethodEdit = plan
            $0.lookupManagements[id: .paymentMethod]?.retroactiveConfirmation = AlertState {
                TextState("更正付款方式")
            } actions: {
                ButtonState(role: .destructive, action: .confirmPaymentMethodEdit) {
                    TextState("確認更正")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("確認後將重算 1 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。")
            }
        }
        #expect(store.state.lookupManagements[id: .paymentMethod]?.pendingPaymentMethodEdit == plan)
        #expect(store.state.lookupManagements[id: .paymentMethod]?.retroactiveConfirmation != nil)
        // 純 `AlertState` 的 `.ifLet` 收到呈現動作 (含 `.dismiss`) 會自動清空呈現狀態。
        // LookupManagementFeature 的取消分支另外清 pendingPaymentMethodEdit
        await store.send(
            .lookupManagements(
                .element(id: .paymentMethod, action: .retroactiveConfirmation(.dismiss)))
        ) {
            $0.lookupManagements[id: .paymentMethod]?.pendingPaymentMethodEdit = nil
            $0.lookupManagements[id: .paymentMethod]?.retroactiveConfirmation = nil
        }
        
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.paymentMethodMaster == [originalMaster])
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["匯款"])
        #expect(
            store.state.lookupManagements[id: .paymentMethod]?.paymentMethodIsBankTransfer == [
                "匯款": true
            ])
    }
    
    @Test func paymentMethodEditPersistenceFailureLeavesOrdersAndMasterUnchanged() async {
        let original = Self.makeTestOrder(id: "BL-PM-FAIL", category: "美妝", customerName: "失敗測試")
        let corrected =
            original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        let plan = LookupManagementFeature.PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            flagsChanged: true,
            affectedOrders: [corrected]
        )
        let originalMaster = PaymentMethodInfo(
            name: "匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
        
        var state = RootFeature.State()
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock { $0.paymentMethods = [originalMaster] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { (_: String, _: String, _: PaymentMethodFlags, _: [LedgerOrder]) async throws(PaymentMethodPersistenceError) in
                throw .storage(.saveFailed(message: "boom"))
            }
        }
        await store.send(
            .lookupManagements(
                .element(id: .paymentMethod, action: .paymentMethodEditPrepared(plan)))
        ) {
            $0.lookupManagements[id: .paymentMethod]?.pendingPaymentMethodEdit = plan
            $0.lookupManagements[id: .paymentMethod]?.retroactiveConfirmation = AlertState {
                TextState("更正付款方式")
            } actions: {
                ButtonState(role: .destructive, action: .confirmPaymentMethodEdit) {
                    TextState("確認更正")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("確認後將重算 1 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。")
            }
        }
        #expect(store.state.lookupManagements[id: .paymentMethod]?.pendingPaymentMethodEdit == plan)
        #expect(store.state.lookupManagements[id: .paymentMethod]?.retroactiveConfirmation != nil)
        // 確認更正後清除待處理資料與提示
        await store.send(
            .lookupManagements(
                .element(
                    id: .paymentMethod,
                    action: .retroactiveConfirmation(.presented(.confirmPaymentMethodEdit))))
        ) {
            $0.lookupManagements[id: .paymentMethod]?.pendingPaymentMethodEdit = nil
            $0.lookupManagements[id: .paymentMethod]?.retroactiveConfirmation = nil
        }
        await store.receive(
            .lookupManagements(
                .element(id: .paymentMethod, action: .paymentMethodEditFailed("付款方式編輯失敗，請稍後再試。")))
        ) {
            $0.lookupManagements[id: .paymentMethod]?.writeFailureAlert = AlertState {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("付款方式編輯失敗，請稍後再試。")
            }
        }
        
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.paymentMethodMaster == [originalMaster])
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["匯款"])
        #expect(
            store.state.lookupManagements[id: .paymentMethod]?.paymentMethodIsBankTransfer == [
                "匯款": true
            ])
        #expect(store.state.lookupManagements[id: .paymentMethod]?.errorMessage == nil)
        #expect(store.state.lookupManagements[id: .paymentMethod]?.writeFailureAlert != nil)
    }
    
    @Test func categoryRenameCascadesInsideMultiCategoryOrders() async {
        // 只改名目標類別，其他元素與順序不變。
        let multi = Self.makeTestOrder(id: "T-MULTI", categories: ["美妝", "服飾"], customerName: "客")
        let single = Self.makeTestOrder(id: "T-SINGLE", categories: ["服飾"], customerName: "客")
        
        var state = RootFeature.State()
        state.orders.orders = [multi, single]
        state.orders.$lookupCatalog.withLock { $0.categories = ["美妝", "服飾"] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        // `LookupCatalog` 會重新排序整份主檔清單。
        // 「服飾」在 zh-Hant 語系排序下排在「彩妝保養」之前
        await store.send(
            .lookupManagements(
                .element(id: .category, action: .renameRequested(from: "美妝", to: "彩妝保養")))
        ) {
            $0.orders.$lookupCatalog.withLock { $0.categories = ["服飾", "彩妝保養"] }
            $0.orders.orders[0] = Self.rebuildOrder(multi, categories: ["彩妝保養", "服飾"])
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        await store.finish()
        
        #expect(
            store.state.orders.orders.first { $0.id == "T-MULTI" }?.categories == ["彩妝保養", "服飾"])
        #expect(store.state.orders.orders.first { $0.id == "T-SINGLE" }?.categories == ["服飾"])
        #expect(store.state.orders.categoryMaster.contains("彩妝保養"))
        #expect(!store.state.orders.categoryMaster.contains("美妝"))
        // 主檔管理與訂單選項應在同次 reducer 呼叫後同步。
        #expect(store.state.lookupManagements[id: .category]?.items.contains("彩妝保養") == true)
        #expect(store.state.lookupManagements[id: .category]?.items.contains("美妝") == false)
        #expect(store.state.orders.availableCategories.contains("美妝") == false)
    }
    
    @Test func campaignRenameCascadesInsideMultiCampaignOrders() async {
        // 只更新目標開團名稱，其他元素保持不變
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
        await store.send(.campaigns(.campaignRenamed(from: "三月日本團", to: "三月日本團 (補)"))) {
            $0.orders.orders[0] = Self.rebuildOrder(
                multi,
                campaignNames: ["三月日本團 (補)", "四月韓國團"]
            )
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        await store.finish()
        
        #expect(store.state.orders.orders.first?.campaignNames == ["三月日本團 (補)", "四月韓國團"])
    }
    
    // 分析區間由 InsightsFeature 自己驗證
    
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
        // 設定關閉時點「AI 總結」→ 出現提示 alert
        await store.send(.orders(.aiSummaryTapped)) {
            $0.orders.aiDisabledAlert = Self.aiDisabledAlert()
        }
        #expect(store.state.orders.aiDisabledAlert != nil)
        
        // 點「前往開啟」→ root 攔截並切到「更多」分頁、要求 push 設定頁
        await store.send(.orders(.aiDisabledAlert(.presented(.goToAISettings)))) {
            $0.orders.aiDisabledAlert = nil
            $0.selectedTab = .more
            $0.morePath = [.settings]
        }
        #expect(store.state.selectedTab == .more)
        #expect(store.state.morePath == [.settings])
    }
    
    /// 深連結一律先清空路徑再推入，確保設定頁只有一份且掛在根層
    @Test func aiSettingsDeepLinkReplacesAnyExistingMorePath() async {
        var initial = RootFeature.State()
        initial.morePath = [.customers, .settings]
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[SettingsStorage.self] = SettingsStorage(load: { .default }, save: { _ in })
        }
        // 先讓提示 alert 存在，再走深連結；此時路徑已有兩層殘留
        await store.send(.orders(.aiSummaryTapped)) {
            $0.orders.aiDisabledAlert = Self.aiDisabledAlert()
        }
        await store.send(.orders(.aiDisabledAlert(.presented(.goToAISettings)))) {
            $0.orders.aiDisabledAlert = nil
            $0.selectedTab = .more
            $0.morePath = [.settings]
        }
        
        #expect(store.state.morePath == [.settings])
    }
    
    // MARK: - Tests (Lookup Single Source of Truth)
    
    /// 驗證訂單編輯新增的類別會同步到管理頁
    @Test func addingCategoryInsideOrderEditIsVisibleToLookupManagement() async {
        var state = RootFeature.State()
        state.orders.editOrder = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow)
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[CategoryRepository.self] = .testValue
        }
        
        await store.send(.orders(.editOrder(.presented(.addCategoryTapped("手工藝品"))))) {
            $0.orders.editOrder?.availableCategories = ["手工藝品"]
            $0.orders.editOrder?.draft.categories = ["手工藝品"]
            $0.orders.$lookupCatalog.withLock { $0.categories = ["手工藝品"] }
        }
        
        // 主檔管理清單從未被載入過，仍立即反映同一份共享目錄的新項目
        #expect(store.state.lookupManagements[id: .category]?.items == ["手工藝品"])
    }
    
    /// 驗證主檔改名後，管理頁、訂單選項與既有訂單同步
    @Test func renamingOrderSourceSyncsManagementOrdersAndAvailableListInOneReducerCall() async {
        let order = Self.makeOrder(id: "T-OS", orderSource: "舊來源")
        
        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.orderSources = ["舊來源"] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[OrderSourceRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        
        await store.send(
            .lookupManagements(
                .element(id: .orderSource, action: .renameRequested(from: "舊來源", to: "新來源")))
        ) {
            $0.orders.$lookupCatalog.withLock { $0.orderSources = ["新來源"] }
            $0.orders.orders[0] = Self.makeOrder(id: "T-OS", orderSource: "新來源")
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        
        #expect(store.state.lookupManagements[id: .orderSource]?.items == ["新來源"])
        #expect(store.state.orders.availableOrderSources.contains("新來源"))
        #expect(!store.state.orders.availableOrderSources.contains("舊來源"))
        #expect(store.state.orders.orders.first?.orderSource == "新來源")
    }
    
    @Test func renamingCategorySyncsManagementOrdersAndAvailableListInOneReducerCall() async {
        let order = Self.makeOrder(id: "T-CAT", categories: ["舊類別"])
        
        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.categories = ["舊類別"] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[CategoryRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        
        await store.send(
            .lookupManagements(
                .element(id: .category, action: .renameRequested(from: "舊類別", to: "新類別")))
        ) {
            $0.orders.$lookupCatalog.withLock { $0.categories = ["新類別"] }
            $0.orders.orders[0] = Self.makeOrder(id: "T-CAT", categories: ["新類別"])
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        
        #expect(store.state.lookupManagements[id: .category]?.items == ["新類別"])
        #expect(store.state.orders.availableCategories.contains("新類別"))
        #expect(!store.state.orders.availableCategories.contains("舊類別"))
        #expect(store.state.orders.orders.first?.categories == ["新類別"])
    }
    
    @Test func renamingReconciliationStatusSyncsManagementOrdersAndAvailableListInOneReducerCall() async {
        let order = Self.makeOrder(id: "T-RS", reconciliationStatus: "待對帳")
        
        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.reconciliationStatuses = ["待對帳"] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[ReconciliationStatusRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        
        await store.send(
            .lookupManagements(
                .element(
                    id: .reconciliationStatus, action: .renameRequested(from: "待對帳", to: "已對帳")))
        ) {
            $0.orders.$lookupCatalog.withLock { $0.reconciliationStatuses = ["已對帳"] }
            $0.orders.orders[0] = Self.makeOrder(id: "T-RS", reconciliationStatus: "已對帳")
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        
        #expect(store.state.lookupManagements[id: .reconciliationStatus]?.items == ["已對帳"])
        #expect(store.state.orders.availableReconciliationStatuses.contains("已對帳"))
        #expect(!store.state.orders.availableReconciliationStatuses.contains("待對帳"))
        #expect(store.state.orders.orders.first?.reconciliationStatus == "已對帳")
    }
    
    /// 驗證付款方式改名也走統一 cascade
    @Test func renamingPaymentMethodSyncsManagementOrdersAndAvailableListInOneReducerCall() async {
        let order = Self.makeOrder(id: "T-PM", paymentMethod: "舊付款")
        
        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock {
            $0.paymentMethods = [
                PaymentMethodInfo(
                    name: "舊付款", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)
            ]
        }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[PaymentMethodRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        
        await store.send(
            .lookupManagements(
                .element(id: .paymentMethod, action: .renameRequested(from: "舊付款", to: "新付款")))
        ) {
            $0.orders.$lookupCatalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "新付款", isCardless: false, isBankTransfer: false,
                        isCashOnDelivery: false)
                ]
            }
            $0.orders.orders[0] = Self.makeOrder(id: "T-PM", paymentMethod: "新付款")
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["新付款"])
        #expect(store.state.orders.availablePaymentMethods.map(\.name).contains("新付款"))
        #expect(!store.state.orders.availablePaymentMethods.map(\.name).contains("舊付款"))
        #expect(store.state.orders.orders.first?.paymentMethod == "新付款")
    }
    
    /// 刪除主檔後，訂單編輯不再提供該值
    @Test func deletingCategoryRemovesItFromOrderEditorAvailableList() async {
        let state = RootFeature.State()
        state.orders.$lookupCatalog.withLock { $0.categories = ["待刪類別"] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[CategoryRepository.self] = .testValue
        }
        
        #expect(store.state.orders.availableCategories.contains("待刪類別"))
        
        await store.send(
            .lookupManagements(.element(id: .category, action: .deleteRequested("待刪類別"))))
        await store.receive(
            .lookupManagements(.element(id: .category, action: .deleteSucceeded("待刪類別")))
        ) {
            $0.orders.$lookupCatalog.withLock { $0.categories = [] }
        }
        
        #expect(store.state.lookupManagements[id: .category]?.items.isEmpty == true)
        #expect(!store.state.orders.availableCategories.contains("待刪類別"))
    }
    
    // MARK: - Tests (Layer Boundary Cleanup)
    
    /// 驗證 RootFeature 的 onChange 監看
    @Test func ordersChangeSyncsAllProjections() async {
        let order = Self.makeOrder(id: "T-SYNC", orderSource: "舊來源")
        
        var state = RootFeature.State()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.orderSources = ["舊來源"] }
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[OrderSourceRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        
        await store.send(
            .lookupManagements(
                .element(id: .orderSource, action: .renameRequested(from: "舊來源", to: "新來源")))
        ) {
            $0.orders.$lookupCatalog.withLock { $0.orderSources = ["新來源"] }
            $0.orders.orders[0] = Self.makeOrder(id: "T-SYNC", orderSource: "新來源")
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        
        #expect(store.state.customers.orders == store.state.orders.orders)
        #expect(store.state.campaigns.orders == store.state.orders.orders)
        #expect(store.state.dashboard.orders == store.state.orders.orders)
        #expect(store.state.insights.orders == store.state.orders.orders)
    }
    
    /// 驗證 RootFeature 的 onChange 監看
    @Test func campaignsChangeSyncsDashboardAndInsightsProjections() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        let loaded = [
            Campaign(
                id: "C1",
                name: "四月韓國團",
                openDate: TestDependencies.fixedNow,
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            )
        ]
        await store.send(.campaigns(.campaignsLoaded(loaded))) {
            $0.campaigns.campaigns = loaded
            $0.campaigns.hasLoaded = true
            $0.orders.campaigns = loaded
            $0.dashboard.campaigns = loaded
            $0.insights.campaigns = loaded
        }
        
        #expect(store.state.orders.campaigns == loaded)
        #expect(store.state.dashboard.campaigns == loaded)
        #expect(store.state.insights.campaigns == loaded)
    }
    
    /// 跨 feature 意圖經 delegate 轉發到既有導覽 action
    @Test func dashboardCampaignTappedDelegateForwardsToCampaignSelected() async {
        var state = RootFeature.State()
        state.campaigns.campaigns = [
            Campaign(
                id: "C1",
                name: "四月韓國團",
                openDate: TestDependencies.fixedNow,
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            )
        ]
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        
        await store.send(.dashboard(.delegate(.campaignTapped("四月韓國團"))))
        await store.receive(\.campaignSelected) {
            $0.selectedTab = .campaigns
            $0.campaigns.selectedCampaignID = "C1"
        }
    }
    
    /// 總覽的新增訂單 delegate 只轉發到根既有的 startNewOrder
    @Test func dashboardNewOrderTappedDelegateForwardsToStartNewOrder() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
        }
        
        await store.send(.dashboard(.delegate(.newOrderTapped)))
        await store.receive(\.startNewOrder) {
            $0.selectedTab = .orders
            $0.orders.editOrder = OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        }
    }
    
    /// 總覽的「查看全部」delegate 只轉發到根既有的 tabSelected
    @Test func dashboardViewAllOrdersTappedDelegateForwardsToTabSelected() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }
        
        await store.send(.dashboard(.delegate(.viewAllOrdersTapped)))
        await store.receive(\.tabSelected) {
            $0.selectedTab = .orders
        }
    }
    
    /// 總覽重新整理會依序載入訂單與設定
    @Test func dashboardRefreshDelegateSendsOrdersAndSettingsLoadEffects() async {
        var state = RootFeature.State()
        state.orders.hasLoaded = true
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(load: { .default }, save: { _ in })
            $0[CurrencyMetadataRepository.self] = CurrencyMetadataRepository(
                fetchCodes: { () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode] in
                    throw CurrencyMetadataRepositoryError.persistence(
                        .storage(.fetchFailed(message: "suppressed"))
                    )
                },
                refreshIfStale: { _ in false },
                forceRefresh: {}
            )
        }
        
        await store.send(.dashboard(.task))
        await store.receive(\.dashboard.delegate.refresh)
        await store.receive(\.orders.task)
        await store.receive(\.settings.task)
    }
    
    /// 分析頁的開團選取會轉發到既有導覽 action
    @Test func insightsCampaignTappedDelegateForwardsToCampaignSelected() async {
        var state = RootFeature.State()
        state.campaigns.campaigns = [
            Campaign(
                id: "C1",
                name: "四月韓國團",
                openDate: TestDependencies.fixedNow,
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            )
        ]
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        
        await store.send(.insights(.delegate(.campaignTapped("四月韓國團"))))
        await store.receive(\.campaignSelected) {
            $0.selectedTab = .campaigns
            $0.campaigns.selectedCampaignID = "C1"
        }
    }
    
    /// 分析的類別排行點選 delegate 只轉發到根既有的 categorySelected
    @Test func insightsCategoryTappedDelegateForwardsToCategorySelected() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.insights(.delegate(.categoryTapped("美妝"))))
        await store.receive(\.categorySelected) {
            $0.selectedTab = .orders
            $0.orders.selectedCategory = "美妝"
        }
    }
    
    /// 跨 feature 意圖經 delegate 轉發到既有導覽 action
    @Test func campaignReceiptStatusToggledDelegateForwardsToOrdersReceiptStatusChanged() async {
        let order = Self.makeTestOrder(id: "BL-RS-TOGGLE", category: "美妝", customerName: "收款測試")
        var state = RootFeature.State()
        state.orders.orders = [order]
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { _ in }
        }
        
        await store.send(.campaigns(.delegate(.receiptStatusToggled(order.id, .received))))
        await store.receive(\.orders.receiptStatusChanged)
        await store.receive(\.orders.receiptStatusChangePersisted) {
            $0.orders.orders[0] = Self.rebuildOrder(order, paymentReceiptStatus: .received)
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
    }
    
    /// 驗證客戶頁的導覽路徑
    @Test func customersCustomerTappedClearsMorePathBeforeTabSwitch() async {
        var state = RootFeature.State()
        state.selectedTab = .more
        state.morePath = [.customers]
        state.orders.orders = LedgerOrder.sampleOrders
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.customers(.delegate(.customerTapped("Alice"))))
        await store.receive(\.customerSelected) {
            $0.morePath = []
            $0.selectedTab = .orders
            $0.orders.searchText = "Alice"
            $0.orders.selectedStatus = .all
            $0.orders.selectedDatePeriod = .all
            // 沒有符合的客戶訂單，因此不會選取訂單
        }
        
        #expect(store.state.morePath.isEmpty)
        #expect(store.state.selectedTab == .orders)
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
    
    /// 建立可指定主檔欄位的最小訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - reconciliationStatus: 對帳狀態
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        orderSource: String = "",
        categories: [String] = [],
        paymentMethod: String = "",
        reconciliationStatus: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "同步測試", initials: "SY", tier: .new),
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
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 建立跨頁深連結用的最小訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - category: 商品類別
    ///   - customerName: 客戶名稱
    /// - Returns: 建立的測試訂單
    static func makeTestOrder(
        id: String,
        category: String,
        customerName: String
    ) -> LedgerOrder {
        makeTestOrder(id: id, categories: [category], customerName: customerName)
    }
    
    /// 建立供跨頁深連結測試使用的最小訂單，支援多類別與多開團歸屬
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - customerName: 客戶名稱
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
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
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 只替換 cascade 測試關心的欄位，保留訂單其餘狀態作為回歸基準
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - categories: 新的商品類別；未提供時保留原值
    ///   - campaignNames: 新的開團名稱；未提供時保留原值
    ///   - paymentReceiptStatus: 新的收據狀態；未提供時保留原值
    /// - Returns: 套用指定欄位後的訂單
    static func rebuildOrder(
        _ order: LedgerOrder,
        categories: [String]? = nil,
        campaignNames: [String]? = nil,
        paymentReceiptStatus: PaymentReceiptStatus? = nil
    ) -> LedgerOrder {
        LedgerOrder(
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
            categories: categories ?? order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: campaignNames ?? order.campaignNames,
            paymentReceiptStatus: paymentReceiptStatus ?? order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
    
    /// 建立 AI 功能關閉時的完整提示
    /// - Returns: AI 功能關閉時顯示的 alert
    static func aiDisabledAlert() -> AlertState<OrdersFeature.Action.Alert> {
        AlertState {
            TextState("AI 商品明細總結")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
            ButtonState(action: .goToAISettings) {
                TextState("前往開啟")
            }
        } message: {
            TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
        }
    }
}
