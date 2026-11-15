//
//  OrdersSelectionUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 訂單清單多選模式在寬版與收合版的已選筆數與批次鈕位置 UI 測試
///
/// - Note: 版面不適用時以版面條件宣告略過
@MainActor
final class OrdersSelectionUITests: BLUITestCase {

    /// 驗證寬版訂單多選已選取一筆訂單時，批次鈕與清單欄的已選筆數下緣都位於視窗上半部
    ///
    /// - Throws: 版面不是並排、多選無法進入、框線無法取得或位置超出上半部時丟出測試錯誤
    /// - Note: 模擬器無法真實拖曳視窗，這裡以上半部的框線作為替代證據，真實拖曳記為未驗證
    /// - Note: 只在寬版並排的訂單版面執行，收合版會略過
    func testBatchStatusMenuButton_寬版多選已選取訂單_批次鈕與筆數位於視窗上半部() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders, language: .traditionalChinese))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .regular, "批次鈕與清單欄筆數的上半部位置只在寬版並排的訂單版面適用")
        try orders.enterSelectionMode()
        // 多選列的 identifier 同時落在按鈕與內層摘要，取第一個點擊
        try orders.orderRow(orderID: "BL-2604-018").firstMatch.tapAfterWaiting(in: app)
        let summary = orders.selectionSummary
        try requireCondition(
            summary.wait(for: NSPredicate(format: "label == %@", "已選 1 筆"), timeout: 5),
            in: app,
            "選取一筆後清單欄的已選筆數未顯示為「已選 1 筆」"
        )

        // When
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗")
        let batchButton = orders.batchStatusMenuButton
        let batchFrame = try requireValidFrame(of: batchButton, in: app, context: "多選批次狀態選單")
        let summaryFrame = try requireValidFrame(of: summary, in: app, context: "寬版清單欄的已選筆數")

        // Then
        try requireCondition(
            window.contains(batchFrame)
                && window.contains(summaryFrame)
                && batchFrame.maxY <= window.midY
                && summaryFrame.maxY <= window.midY
                && batchButton.isHittableOnScreen,
            in: app,
            """
            位置越界或不可操作：批次鈕或已選筆數不在視窗上半部，或批次鈕不可點
            批次鈕 frame = \(batchFrame)，已選筆數 frame = \(summaryFrame)，視窗 frame = \(window)
            """
        )
    }

    /// 驗證收合版訂單多選選取兩筆後，已選筆數只出現在導覽列標題，沒有移到詳情工具列或其他位置
    ///
    /// - Throws: 版面不是收合、多選無法進入、標題未顯示或筆數出現在導覽列框線之外時丟出測試錯誤
    /// - Note: 導覽列標題在可及性樹上可能同時有導覽列與文字兩個節點，兩者都位於導覽列框線內，視為同一處顯示
    /// - Note: 只在收合導覽的訂單版面執行，寬版並排的筆數位於清單欄頂部，另由寬版測試守
    func testOrderSelectionToggled_收合版多選選取兩筆_筆數只在導覽列標題出現一次() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders, language: .traditionalChinese))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "已選筆數只出現在收合導覽的標題，並排版面的筆數位於清單欄頂部")
        try orders.enterSelectionMode()

        // When
        // 多選列的 identifier 同時落在按鈕與內層摘要，取第一個點擊
        try orders.orderRow(orderID: "BL-2604-018").firstMatch.tapAfterWaiting(in: app)
        try orders.orderRow(orderID: "BL-2604-017").firstMatch.tapAfterWaiting(in: app)

        // Then
        try requireCondition(
            app.waitForNavigationBarTitle("已選 2 筆", timeout: 5),
            in: app,
            "選取兩筆後導覽列未顯示「已選 2 筆」"
        )
        let countTexts = app.staticTextCount("已選 2 筆")
        let navigationCountTexts = app.navigationBarTextCount("已選 2 筆")
        try requireCondition(
            countTexts == 1 && navigationCountTexts == 1,
            in: app,
            """
            已選筆數未只在導覽列標題出現一次
            全畫面 \(countTexts) 處，導覽列內 \(navigationCountTexts) 處
            """
        )
    }
}
