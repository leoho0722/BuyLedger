//
//  OrderFilterFeatureClearTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderFilterFeature` 的單元測試，涵蓋訂單分頁篩選面板的暫存清除、重設，以及套用後與清單的連動
@MainActor
struct OrderFilterFeatureClearTests {

    /// 驗證暫存中已有日期與付款方式時切換類別，日期與付款方式保留在暫存，已套用的條件不變
    @Test
    func filterPendingCategoryToggled_暫存已有日期與付款方式_保留其他暫存且不提交() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState(categories: ["beauty"])
        state.pendingFilterSelection.datePeriod = .thisMonth
        state.pendingFilterSelection.paymentMethod = "轉帳"
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoryToggled("beauty"))) {
            $0.pendingFilterSelection.categories = ["beauty"]
        }

        // Then
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(store.state.pendingFilterSelection.paymentMethod == "轉帳")
        #expect(store.state.committedFilterSelection.datePeriod == .all)
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.committedFilterSelection.paymentMethod == nil)
    }

    /// 驗證已套用條件非預設時按清除，只重設暫存的三欄，已套用值與搜尋文字、焦點、展開狀態都不變，且仍有未套用的變更
    @Test
    func filterClearTapped_已套用三欄非預設_只清除暫存且仍有未套用變更() async {
        // Given
        let committed = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["beauty", "books"],
            paymentMethod: "信用卡"
        )
        var state = OrderFilterFeatureTestSupport.makeState(
            categories: ["beauty", "books"],
            committedFilterSelection: committed
        )
        state.filterSheetSearchText = "食"
        state.isSearchFieldFocused = true
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterClearTapped)) {
            $0.pendingFilterSelection.datePeriod = .all
            $0.pendingFilterSelection.categories = []
            $0.pendingFilterSelection.paymentMethod = nil
        }

        // Then
        #expect(store.state.committedFilterSelection == committed)
        #expect(store.state.pendingFilterSelection.isActive == false)
        #expect(store.state.hasUnappliedFilterChanges == true)
        #expect(store.state.filterSheetSearchText == "食")
        #expect(store.state.isSearchFieldFocused == true)
        #expect(store.state.categoryGroupExpansion.expandedKinds == [.ongoing])
    }

    /// 驗證只有暫存三欄有變更時按清除，暫存回到預設，且不再有未套用的變更
    @Test
    func filterClearTapped_只有暫存三欄已變更_清除後不再有未套用變更() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["beauty", "books"],
            paymentMethod: "信用卡"
        )
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterClearTapped)) {
            $0.pendingFilterSelection.datePeriod = .all
            $0.pendingFilterSelection.categories = []
            $0.pendingFilterSelection.paymentMethod = nil
        }

        // Then
        #expect(store.state.pendingFilterSelection.isActive == false)
        #expect(store.state.hasUnappliedFilterChanges == false)
        #expect(store.state.committedFilterSelection.datePeriod == .all)
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.committedFilterSelection.paymentMethod == nil)
    }

    /// 驗證暫存已是預設時按清除，狀態維持未啟用且無未套用變更，供畫面衍生停用狀態
    @Test
    func filterClearTapped_暫存已是預設_維持停用與未變更() async {
        // Given
        let store = TestStore(initialState: OrderFilterFeatureTestSupport.makeState()) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterClearTapped))

        // Then
        #expect(store.state.pendingFilterSelection.isActive == false)
        #expect(store.state.hasUnappliedFilterChanges == false)
    }

    /// 驗證清除後套用時，預設條件提交到清單並關閉面板，摘要還原為「全部」，選取的訂單不變且不發出選取變更
    @Test
    func destination_清除後套用_提交預設並還原全部摘要() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "beauty", paymentMethod: "信用卡"),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "books", paymentMethod: "現金"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty", "books"]
        state.selectedPaymentMethod = "信用卡"
        state.selectedOrderID = "A"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: [],
                paymentMethod: nil
            )
        }
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterApplyTapped)))))

        // Then
        await store.receive(
            \.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
        ) {
            $0.selectedDatePeriod = .all
            $0.selectedCategories = []
            $0.selectedPaymentMethod = nil
            $0.destination = nil
        }
        #expect(store.state.filterSummary(language: .traditionalChinese) == "全部")
        #expect(store.state.selectedOrderID == "A")
        #expect(store.state.destination == nil)
    }

    /// 驗證三項暫存同時變更後套用，清單依新條件重選第一筆 beauty，只發出一次選取變更，摘要為「本月 · beauty · 轉帳」
    @Test
    func destination_三項暫存都變更_提交完整條件並重選一次() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(
                id: "snacks",
                category: "snacks",
                paymentMethod: "轉帳"
            ),
            OrdersFeatureTestSupport.makeOrder(
                id: "beauty",
                category: "beauty",
                paymentMethod: "轉帳"
            ),
            OrdersFeatureTestSupport.makeOrder(
                id: "card",
                category: "beauty",
                paymentMethod: "信用卡"
            ),
        ])
        state.selectedOrderID = "card"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        }
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterApplyTapped)))))

        // Then
        await store.receive(
            \.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        ) {
            $0.selectedDatePeriod = .thisMonth
            $0.selectedCategories = ["beauty"]
            $0.selectedPaymentMethod = "轉帳"
            $0.selectedOrderID = "beauty"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "beauty")
        #expect(store.state.filterSummary(language: .traditionalChinese) == "本月 · beauty · 轉帳")
        #expect(store.state.destination == nil)
    }

    /// 驗證暫存取消原類別後再選回，與已套用的集合相同，不再有未套用變更，也不跳出捨棄確認
    @Test
    func filterPendingCategoryToggled_暫存已取消原類別_選回後不再有未套用變更() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState(
            categories: ["beauty"],
            committedFilterSelection: OrderFilterSelection(categories: ["beauty"])
        )
        state.pendingFilterSelection.categories = []
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoryToggled("beauty"))) {
            $0.pendingFilterSelection.categories = ["beauty"]
        }

        // Then
        #expect(store.state.hasUnappliedFilterChanges == false)
        #expect(store.state.filterDiscardConfirmation == nil)
        #expect(store.state.committedFilterSelection.categories == ["beauty"])
    }
}
