//
//  OrdersScreen+RegularFilters.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

// MARK: - Computed Properties

@MainActor
extension OrdersScreen {

    /// regular 版面的清除篩選按鈕是否可互動；無篩選條件時停用
    var isRegularClearFiltersEnabled: Bool {
        let identifier = BLAccessibilityID.Orders.clearFiltersButton
        return app.buttons[identifier].firstMatch.isEnabled
    }
}

// MARK: - Internal Method

@MainActor
extension OrdersScreen {

    /// 點 regular 版面的日期膠囊選取指定期間
    ///
    /// - Parameters:
    ///   - periodID: 日期期間識別值 (`all`、`thisWeek`、`thisMonth`、`lastMonth`)
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectRegularDateChip(
        _ periodID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let identifier = BLAccessibilityID.Orders.dateChip(periodID)
        app.descendants(matching: .any)[identifier].tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判斷 regular 版面的日期膠囊是否處於選中狀態
    ///
    /// - Parameter periodID: 日期期間識別值
    /// - Returns: 膠囊是否存在且選中
    func isRegularDateChipSelected(_ periodID: String) -> Bool {
        let identifier = BLAccessibilityID.Orders.dateChip(periodID)
        return app.descendants(matching: .any)[identifier].isSelected
    }

    /// 判斷 regular 版面的狀態膠囊是否處於選中狀態
    ///
    /// - Parameter filterID: 狀態篩選識別值 (`all` 或狀態 `rawValue`)
    /// - Returns: 膠囊是否存在且選中
    func isRegularStatusChipSelected(_ filterID: String) -> Bool {
        let identifier = BLAccessibilityID.Orders.statusChip(filterID)
        return app.descendants(matching: .any)[identifier].isSelected
    }

    /// 判斷 regular 版面的付款方式 Menu 是否處於選中狀態
    ///
    /// - Returns: 付款方式 Menu 是否存在且選中
    func isRegularPaymentMethodMenuSelected() -> Bool {
        let identifier = BLAccessibilityID.Orders.paymentMethodMenuButton
        return app.descendants(matching: .any)[identifier].isSelected
    }

    /// 點 regular 版面的清除篩選按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRegularClearFilters(file: StaticString = #filePath, line: UInt = #line) {
        let identifier = BLAccessibilityID.Orders.clearFiltersButton
        app.buttons[identifier].firstMatch.tapAfterWaiting(in: app, file: file, line: line)
    }
}
