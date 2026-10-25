//
//  OrdersContainerPlanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// `OrdersContainerPlan` 的單元測試，涵蓋請求所需的表單識別值與日期脈絡
struct OrdersContainerPlanTests {

    /// 驗證各種請求是否需要表單識別值，新增與有效編輯需要，合併、刪除、查看詳情與狀態變更等都不需要
    ///
    /// - Parameter scenario: 操作請求與預期是否需要表單識別值的案例
    @Test(arguments: FormIDCase.allCases)
    func requiresFormID_請求種類_依規則決定是否需要表單識別值(scenario: FormIDCase) {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let isRequired = OrdersContainerPlan.requiresFormID(scenario.request, state: state)

        // Then
        #expect(isRequired == scenario.isFormIDRequired)
    }

    /// 驗證各種請求是否需要日期脈絡，新增與有效編輯需要，合併只在可合併且清單尚未記錄日期時需要，其餘都不需要
    ///
    /// - Parameter scenario: 操作請求與預期是否需要由 reducer 解析日期脈絡的案例
    @Test(arguments: DateContextCase.allCases)
    func requiresDateContext_請求種類_依規則決定是否需要日期脈絡(scenario: DateContextCase) {
        // Given
        let state = OrdersContainerPlanTestSupport.makeRuleState()

        // When
        let isRequired = OrdersContainerPlan.requiresDateContext(scenario.request, state: state)

        // Then
        #expect(isRequired == scenario.isDateContextRequired)
    }

    /// 驗證清單已記錄日期脈絡時，合併不需要 reducer 再解析時間與行事曆
    @Test
    func requiresDateContext_清單已有日期脈絡_合併不需要() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeRuleState()
        state.list.dateContext = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let isRequired = OrdersContainerPlan.requiresDateContext(.merge("A"), state: state)

        // Then
        #expect(isRequired == false)
    }
}

// MARK: - Nested Types

extension OrdersContainerPlanTests {

    /// 操作請求與預期是否需要表單識別值的測試案例
    struct FormIDCase: Sendable {

        /// 新增與編輯存在的訂單需要表單識別值，其餘請求不需要的案例
        static let allCases = [
            Self(request: .create, isFormIDRequired: true),
            Self(request: .edit("A"), isFormIDRequired: true),
            Self(request: .edit("missing"), isFormIDRequired: false),
            Self(request: .merge("A"), isFormIDRequired: false),
            Self(request: .delete("A"), isFormIDRequired: false),
            Self(request: .showDetail("A"), isFormIDRequired: false),
            Self(
                request: .batchStatusChange([LedgerOrder.fixture(id: "A")]),
                isFormIDRequired: false
            ),
            Self(request: .changeStatus(id: "A", status: .shipping), isFormIDRequired: false),
            Self(request: .aiSummary, isFormIDRequired: false),
        ]

        /// 清單或詳情的操作請求
        let request: OrderRequest

        /// 是否需要表單識別值
        let isFormIDRequired: Bool
    }

    /// 操作請求與預期是否需要日期脈絡的測試案例
    struct DateContextCase: Sendable {

        /// 新增、有效編輯與可合併訂單的合併需要日期脈絡，其餘請求不需要的案例
        static let allCases = [
            Self(request: .create, isDateContextRequired: true),
            Self(request: .edit("A"), isDateContextRequired: true),
            Self(request: .edit("missing"), isDateContextRequired: false),
            Self(request: .merge("A"), isDateContextRequired: true),
            Self(request: .merge("M"), isDateContextRequired: false),
            Self(request: .merge("X"), isDateContextRequired: false),
            Self(request: .merge("missing"), isDateContextRequired: false),
            Self(request: .delete("A"), isDateContextRequired: false),
            Self(request: .showDetail("A"), isDateContextRequired: false),
            Self(
                request: .batchStatusChange([LedgerOrder.fixture(id: "A")]),
                isDateContextRequired: false
            ),
            Self(request: .changeStatus(id: "A", status: .shipping), isDateContextRequired: false),
            Self(request: .aiSummary, isDateContextRequired: false),
        ]

        /// 清單或詳情的操作請求
        let request: OrderRequest

        /// 是否需要由 reducer 解析日期脈絡
        let isDateContextRequired: Bool
    }
}
