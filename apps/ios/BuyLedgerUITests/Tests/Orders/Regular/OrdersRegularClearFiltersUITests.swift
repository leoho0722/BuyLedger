//
//  OrdersRegularClearFiltersUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面清除篩選的 UI 流程測試，涵蓋預設值、狀態保留與按鈕停用
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilter`
@MainActor
final class OrdersRegularClearFiltersUITests: BLUITestCase {

    /// 已確認狀態篩選的 `filterID`
    private static let confirmedFilterID = "confirmed"

    /// 驗證清除篩選後付款方式、類別與日期回到預設，狀態仍維持已確認
    ///
    /// - Throws: 版面不符或篩選結果不符時丟出測試錯誤
    func testClearFiltersTapped_有篩選條件_三項回到預設且狀態維持() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "清除篩選按鈕只存在於 regular 版面，"
                + "compact 版面由篩選 sheet 測試覆蓋"
        )
        try orders.selectStatusChip(filterID: Self.confirmedFilterID)
        try orders.selectPaymentMethodInRegularLayout("信用卡")
        try orders.selectRegularDateChip("thisMonth")
        let picker = try orders.openCategoryPicker()
        try picker.tapPickerCategory("3C")
        try picker.tapPickerCategory("美妝")
        try picker.tapPickerDone()
        try requireCondition(
            orders.isRegularClearFiltersEnabled,
            in: app,
            "前提不成立：有篩選條件時清除篩選應可點"
        )
        try requireCondition(
            orders.isRegularDateChipSelected("thisMonth")
                && !orders.isRegularDateChipSelected("all"),
            in: app,
            "前提不成立：日期應已選本月"
        )
        let paymentMethodLabel = orders.paymentMethodTriggerLabel()
        try requireCondition(
            paymentMethodLabel.contains("付款方式：信用卡"),
            in: app,
            "前提不成立：付款方式應為信用卡，實際為「\(paymentMethodLabel)」"
        )
        let categoryLabel = orders.categoryTriggerLabel()
        try requireCondition(
            categoryLabel.contains("類別：2 項"),
            in: app,
            "前提不成立：類別應為兩項，實際為「\(categoryLabel)」"
        )
        try requireCondition(
            orders.isRegularStatusChipSelected(Self.confirmedFilterID),
            in: app,
            "前提不成立：狀態篩選應為已確認"
        )

        // When
        try orders.tapRegularClearFilters()

        // Then
        let clearedPaymentMethodLabel = orders.paymentMethodTriggerLabel()
        try requireCondition(
            clearedPaymentMethodLabel.contains("付款方式：全部"),
            in: app,
            "清除後付款方式應為全部，實際為「\(clearedPaymentMethodLabel)」"
        )
        let clearedCategoryLabel = orders.categoryTriggerLabel()
        try requireCondition(
            clearedCategoryLabel.contains("類別：全部"),
            in: app,
            "清除後類別應為全部，實際為「\(clearedCategoryLabel)」"
        )
        try requireCondition(
            orders.isRegularDateChipSelected("all")
                && !orders.isRegularDateChipSelected("thisMonth"),
            in: app,
            "清除後日期應回到全部時間"
        )
        try requireCondition(
            orders.isRegularStatusChipSelected(Self.confirmedFilterID),
            in: app,
            "清除後狀態篩選應維持已確認"
        )
        try requireCondition(
            !orders.isRegularClearFiltersEnabled,
            in: app,
            "清除後無篩選條件，清除篩選按鈕應停用"
        )
        try assertListedOrderIDs(OrdersSeedFixture.allOrderIDs, orders)
    }

    /// 驗證沒有篩選條件時清除按鈕停用，且「全部」狀態預設選中
    ///
    /// - Throws: 版面不符或預設篩選狀態不符時丟出測試錯誤
    func testIsRegularClearFiltersEnabled_無篩選條件_按鈕停用() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "清除篩選按鈕只存在於 regular 版面，"
                + "compact 版面由篩選 sheet 測試覆蓋"
        )

        // When
        let isClearButtonEnabled = orders.isRegularClearFiltersEnabled

        // Then
        try requireCondition(
            !isClearButtonEnabled,
            in: app,
            "無篩選條件時清除篩選按鈕應停用"
        )
        try requireCondition(
            orders.isRegularStatusChipSelected("all"),
            in: app,
            "預設狀態篩選應為全部並選中"
        )
    }
}
