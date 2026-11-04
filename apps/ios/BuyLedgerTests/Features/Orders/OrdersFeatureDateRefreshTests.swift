//
//  OrdersFeatureDateRefreshTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersFeature.State` 的單元測試，涵蓋日期脈絡刷新與深連結對目前詳情的影響
struct OrdersFeatureDateRefreshTests {

    // MARK: - Properties

    /// 詳情開啟時記錄的日期脈絡時間 (2026-04-29 00:00 UTC)
    private static let aprilTwentyNinth = Date(timeIntervalSince1970: 1_777_420_800)

    /// 同月內跨日的時間 (2026-04-30 00:00 UTC)
    private static let aprilThirtieth = Date(timeIntervalSince1970: 1_777_507_200)

    /// 跨入下月的時間 (2026-05-01 00:00 UTC)
    private static let mayFirst = Date(timeIntervalSince1970: 1_777_593_600)

    /// 驗證本月篩選跨到下月時，因刷新才被排除的目前詳情會清空且不改選其他訂單
    @Test
    func refreshDateContext_本月篩選跨到下月_清空目前詳情() {
        // Given
        var state = makeState(datePeriod: .thisMonth)

        // When
        state.refreshDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)

        // Then
        #expect(state.detail.path.isEmpty)
        #expect(state.selectedOrderID == nil)
    }

    /// 驗證本月篩選在同月內跨日時，目前詳情與路徑元素識別值都保留
    @Test
    func refreshDateContext_本月篩選同月跨日_保留目前詳情與識別值() {
        // Given
        var state = makeState(datePeriod: .thisMonth)
        let originalIDs = Array(state.detail.path.ids)

        // When
        state.refreshDateContext(now: Self.aprilThirtieth, calendar: TestDependencies.fixedCalendar)

        // Then
        #expect(state.selectedOrderID == "BL-2604-017")
        #expect(Array(state.detail.path.ids) == originalIDs)
    }

    /// 驗證全部時間篩選不以月份界定範圍，跨到下月時目前詳情仍符合篩選而保留
    @Test
    func refreshDateContext_全部時間跨到下月_保留目前詳情() {
        // Given
        var state = makeState(datePeriod: .all)

        // When
        state.refreshDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)

        // Then
        #expect(state.selectedOrderID == "BL-2604-017")
    }

    /// 驗證刷新前已被狀態篩選排除的詳情，不因回到前景的刷新而清空
    @Test
    func refreshDateContext_詳情已被狀態篩選排除_保留目前詳情() {
        // Given
        var state = makeState(datePeriod: .all)
        state.list.selectedStatus = .status(.arrived)

        // When
        state.refreshDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)

        // Then
        #expect(state.selectedOrderID == "BL-2604-017")
    }

    /// 驗證清單先自行更新日期脈絡後，容器刷新把詳情視為早已排除而保留
    @Test
    func refreshDateContext_清單已先更新日期_保留目前詳情() {
        // Given
        var state = makeState(datePeriod: .thisMonth)
        state.list.refreshDateContext(
            OrderDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)
        )

        // When
        state.refreshDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)

        // Then
        #expect(state.selectedOrderID == "BL-2604-017")
    }

    /// 驗證清單先自行更新日期脈絡且容器刷新保留詳情後，下一次搜尋仍排除該訂單時清空詳情
    @MainActor
    @Test
    func list_清單已先更新日期後搜尋仍排除_清空目前詳情() async {
        // Given
        var initial = makeState(datePeriod: .thisMonth)
        initial.list.refreshDateContext(
            OrderDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)
        )
        initial.refreshDateContext(now: Self.mayFirst, calendar: TestDependencies.fixedCalendar)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(Self.mayFirst)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.list(.view(.searchTextChanged("Mika 周")))) {
            $0.list.searchText = "Mika 周"
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證深連結先套新篩選再檢查，舊日期篩選已排除但新搜尋命中的詳情保留
    @Test
    func applyFilterNavigation_舊日期篩選已排除但新搜尋命中_保留目前詳情() {
        // Given
        var state = makeState(datePeriod: .thisMonth)

        // When
        state.applyFilterNavigation(
            searchText: "Mika 周",
            category: nil,
            now: Self.mayFirst,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(state.selectedOrderID == "BL-2604-017")
    }
}

// MARK: - Private Method

private extension OrdersFeatureDateRefreshTests {

    /// 建立已記錄 2026-04-29 日期脈絡、套用指定日期篩選並開著 BL-2604-017 詳情的狀態
    ///
    /// - Parameter datePeriod: 要套用的日期篩選
    /// - Returns: 含一筆 2026-04-24 訂單與其詳情路徑的 `OrdersFeature` 狀態
    func makeState(datePeriod: OrderDatePeriod) -> OrdersFeature.State {
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(
                id: "BL-2604-017",
                customer: LedgerCustomer(name: "Mika 周", initials: "MZ", tier: .regular),
                date: Date(timeIntervalSince1970: 1_776_988_800)
            ),
        ])
        state.refreshDateContext(
            now: Self.aprilTwentyNinth,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = datePeriod
        state.detail.showDetail(orderID: "BL-2604-017")
        return state
    }
}
