//
//  OrdersSeedFixture.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

/// 多個資料夾共用的訂單 UI 測試種子識別值
enum OrdersSeedFixture {

    // MARK: - Properties

    /// 發起合併的種子訂單編號
    static let mergeOrderID = "UITEST-MRG-001"

    /// 可合併的候選訂單編號
    static let mergeCandidateOrderID = "UITEST-MRG-002"

    /// 大量類別種子中開團中的首個類別
    static let ongoingCategory = "類別 001"

    /// 大量類別種子中已收單的末個類別
    static let lastClosedCategory = "類別 300"

    /// 大量類別種子選取首尾類別後的訂單編號
    static let largeFilteredOrderIDs: Set<String> = [
        "UITEST-CFL-001",
        "UITEST-CFL-300",
    ]

    /// 本月、信用卡、類別美妝與書籍的篩選結果訂單編號
    static let filteredOrderIDs: Set<String> = [
        "UITEST-CF-001",
        "UITEST-CF-004",
        "UITEST-CF-007",
        "UITEST-CF-010",
    ]

    /// 一般類別篩選種子的全部訂單編號
    static let allOrderIDs: Set<String> = [
        "UITEST-CF-001",
        "UITEST-CF-002",
        "UITEST-CF-003",
        "UITEST-CF-004",
        "UITEST-CF-005",
        "UITEST-CF-006",
        "UITEST-CF-007",
        "UITEST-CF-008",
        "UITEST-CF-009",
        "UITEST-CF-010",
    ]
}
