//
//  OrdersFilterOperationsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證 OrdersFilterOperations 的狀態變化
struct OrdersFilterOperationsTests {
    
    // MARK: - Tests
    
    @Test func statusFilterSelectedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", status: .quoting), makeOrder(id: "B", status: .delivered),
        ]
        
        OrdersFilterOperations.statusFilterSelected(
            .status(.delivered),
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedStatus == .status(.delivered))
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func datePeriodSelectedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", date: Self.date(year: 2026, month: 3, day: 15)),
            makeOrder(id: "B", date: TestDependencies.fixedNow),
        ]
        
        OrdersFilterOperations.datePeriodSelected(
            .thisMonth,
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedDatePeriod == .thisMonth)
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func categoryFilterSelectedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A", category: "美妝"), makeOrder(id: "B", category: "服飾")]
        
        OrdersFilterOperations.categoryFilterSelected(
            "服飾",
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedCategory == "服飾")
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func paymentMethodFilterSelectedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", paymentMethod: "信用卡"), makeOrder(id: "B", paymentMethod: "現金"),
        ]
        
        OrdersFilterOperations.paymentMethodFilterSelected(
            "現金",
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedPaymentMethod == "現金")
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func campaignFilterSelectedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", campaignNames: ["A團"]), makeOrder(id: "B", campaignNames: ["B團"]),
        ]
        
        OrdersFilterOperations.campaignFilterSelected(
            "B團",
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedCampaign == "B團")
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func campaignStatusFilterSelectedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", campaignNames: ["A團"]), makeOrder(id: "B", campaignNames: ["B團"]),
        ]
        state.campaigns = [
            Campaign(
                id: "1",
                name: "A團",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "2",
                name: "B團",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .closed,
                settledDate: nil,
                notes: ""
            ),
        ]
        
        OrdersFilterOperations.campaignStatusFilterSelected(
            .closed,
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedCampaignStatus == .closed)
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func categoryPickerTappedShowsPicker() {
        var state = OrdersFeature.State()
        OrdersFilterOperations.categoryPickerTapped(state: &state)
        #expect(state.showsCategoryPicker == true)
    }
    
    @Test func paymentMethodPickerTappedShowsPicker() {
        var state = OrdersFeature.State()
        OrdersFilterOperations.paymentMethodPickerTapped(state: &state)
        #expect(state.showsPaymentMethodPicker == true)
    }
    
    @Test func filterSheetTappedSeedsPendingSelectionAndClearsSearch() {
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .thisWeek
        state.selectedCategory = "美妝"
        state.filterSheetSearchText = "殘留文字"
        
        OrdersFilterOperations.filterSheetTapped(state: &state)
        
        #expect(state.pendingFilterSelection == state.committedFilterSelection)
        #expect(state.pendingFilterSelection.datePeriod == .thisWeek)
        #expect(state.pendingFilterSelection.category == "美妝")
        #expect(state.filterSheetSearchText == "")
        #expect(state.showsFilterSheet == true)
    }

    @Test func pendingFilterSelectionIsActiveMatchesEachNonDefaultValue() {
        let cases: [(OrdersFeature.State.PendingFilterSelection, Bool)] = [
            (.init(), false),
            (.init(datePeriod: .thisWeek), true),
            (.init(category: "美妝"), true),
            (.init(paymentMethod: "信用卡"), true),
        ]

        for (selection, expected) in cases {
            #expect(selection.isActive == expected)
        }
    }
    
    @Test func filterPendingSelectionsOnlyUpdatePendingNotCommitted() {
        var state = OrdersFeature.State()
        
        OrdersFilterOperations.filterPendingDatePeriodSelected(.thisMonth, state: &state)
        #expect(state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(state.selectedDatePeriod == .all)
        
        OrdersFilterOperations.filterPendingCategorySelected("美妝", state: &state)
        #expect(state.pendingFilterSelection.category == "美妝")
        #expect(state.selectedCategory == nil)
        
        OrdersFilterOperations.filterPendingPaymentMethodSelected("信用卡", state: &state)
        #expect(state.pendingFilterSelection.paymentMethod == "信用卡")
        #expect(state.selectedPaymentMethod == nil)
    }
    
    @Test func filterApplyTappedCommitsChangesAndRecomputesSelection() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A", category: "美妝"), makeOrder(id: "B", category: "服飾")]
        state.pendingFilterSelection.category = "服飾"
        state.showsFilterSheet = true
        
        OrdersFilterOperations.filterApplyTapped(
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedCategory == "服飾")
        #expect(state.selectedOrderID == "B")
        #expect(state.showsFilterSheet == false)
    }
    
    @Test func filterApplyTappedWithoutChangesStillClosesSheet() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A", category: "美妝")]
        state.selectedOrderID = "A"
        state.pendingFilterSelection = state.committedFilterSelection
        state.showsFilterSheet = true
        
        OrdersFilterOperations.filterApplyTapped(
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.selectedOrderID == "A")
        #expect(state.showsFilterSheet == false)
    }
    
    @Test func filterCancelTappedWithoutUnappliedChangesClosesDirectly() {
        var state = OrdersFeature.State()
        state.showsFilterSheet = true
        state.pendingFilterSelection = state.committedFilterSelection
        
        OrdersFilterOperations.filterCancelTapped(state: &state)
        
        #expect(state.showsFilterSheet == false)
        #expect(state.filterDiscardConfirmation == nil)
    }
    
    @Test func filterCancelTappedWithUnappliedChangesPresentsDiscardConfirmation() {
        var state = OrdersFeature.State()
        state.showsFilterSheet = true
        state.pendingFilterSelection.category = "美妝"
        
        OrdersFilterOperations.filterCancelTapped(state: &state)
        
        #expect(state.showsFilterSheet == true)
        #expect(state.filterDiscardConfirmation != nil)
    }
    
    @Test func filterDiscardConfirmedRevertsPendingSelectionAndClosesSheet() {
        var state = OrdersFeature.State()
        state.showsFilterSheet = true
        state.pendingFilterSelection.category = "美妝"
        
        OrdersFilterOperations.filterDiscardConfirmed(state: &state)
        
        #expect(state.pendingFilterSelection == state.committedFilterSelection)
        #expect(state.showsFilterSheet == false)
    }
    
    @Test func searchTextChangedUpdatesSelectionAndSelectsFirstFilteredOrder() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A"), makeOrder(id: "B")]
        
        OrdersFilterOperations.searchTextChanged(
            "B",
            state: &state,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(state.searchText == "B")
        #expect(state.selectedOrderID == "B")
    }
    
    @Test func orderSelectedUpdatesSelectedOrderID() {
        var state = OrdersFeature.State()
        OrdersFilterOperations.orderSelected("A", state: &state)
        #expect(state.selectedOrderID == "A")
        
        OrdersFilterOperations.orderSelected(nil, state: &state)
        #expect(state.selectedOrderID == nil)
    }
    
    // MARK: Filter Equivalence
    
    /// 每種篩選條件都符合預期訂單序列
    @Test func filteredOrdersMatchesHardcodedSequenceForEachFilterCondition() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(
                id: "O1", status: .quoting, date: TestDependencies.fixedNow, category: "美妝",
                paymentMethod: "信用卡", campaignNames: ["A"]),
            makeOrder(
                id: "O2", status: .confirmed, date: Self.date(year: 2026, month: 3, day: 1),
                category: "服飾", paymentMethod: "現金", campaignNames: []),
            makeOrder(
                id: "O3", status: .quoting, date: TestDependencies.fixedNow, category: "美妝",
                paymentMethod: "現金", campaignNames: ["B"]),
            makeOrder(
                id: "O4", status: .delivered, date: TestDependencies.fixedNow, category: "服飾",
                paymentMethod: "信用卡", campaignNames: ["A"]),
        ]
        // 同名開團：兩筆皆名為「A」，狀態不同；保留先出現者 (.ongoing)
        state.campaigns = [
            Campaign(
                id: "A-1",
                name: "A",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "A-2",
                name: "A",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .closed,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "B-1", name: "B", openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow, status: .closed, settledDate: nil, notes: ""),
        ]
        
        /// 依目前 state 的篩選條件回傳訂單識別值
        /// - Returns: 符合目前篩選條件的訂單識別值
        func filtered() -> [String] {
            state.filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            ).map(\.id)
        }
        
        state.selectedStatus = .status(.quoting)
        #expect(filtered() == ["O1", "O3"])
        state.selectedStatus = .all
        
        state.selectedDatePeriod = .thisMonth
        #expect(filtered() == ["O1", "O3", "O4"])
        state.selectedDatePeriod = .all
        
        state.selectedCategory = "美妝"
        #expect(filtered() == ["O1", "O3"])
        state.selectedCategory = nil
        
        state.selectedPaymentMethod = "信用卡"
        #expect(filtered() == ["O1", "O4"])
        state.selectedPaymentMethod = nil
        
        state.selectedCampaign = "A"
        #expect(filtered() == ["O1", "O4"])
        state.selectedCampaign = nil
        
        // 同名開團取先出現者，篩選應依其狀態判斷
        state.selectedCampaignStatus = .ongoing
        #expect(filtered() == ["O1", "O4"])
        state.selectedCampaignStatus = nil
    }
}

// MARK: - Private Method

private extension OrdersFilterOperationsTests {
    
    /// 建立僅供篩選測試使用的最小訂單；非相關欄位以零值/佔位填入
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - category: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    func makeOrder(
        id: String,
        status: OrderStatus = .quoting,
        date: Date = TestDependencies.fixedNow,
        category: String = "類別",
        paymentMethod: String = "付款",
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶\(id)", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: date,
            items: [LedgerOrderItem(id: UUID(), name: "商品", quantity: 1, unitPrice: 100)],
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
            orderSource: "來源",
            categories: [category],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 依 UTC gregorian 曆法建立指定年月日的日期
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    static func date(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = TestDependencies.fixedCalendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }
}
