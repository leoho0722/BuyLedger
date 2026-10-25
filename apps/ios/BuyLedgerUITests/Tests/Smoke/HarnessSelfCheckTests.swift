//
//  HarnessSelfCheckTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// UI 測試地基的自我檢查 UI 測試，涵蓋資料、語言與固定時間的啟動參數注入
@MainActor
final class HarnessSelfCheckTests: BLUITestCase {

    // MARK: - Properties

    /// 固定參考時間：2026/6/15 00:00 UTC
    private static let referenceDate = Date(timeIntervalSince1970: 1_781_481_600)

    /// 驗證有資料的 App 終止後以空資料重新啟動，總覽顯示空狀態，不殘留第一次啟動的訂單
    func testRelaunch_有資料後改以空資料重啟_總覽顯示空狀態() {
        // Given
        let first = launch(LaunchOptions(seed: .fullOrders))
        let firstDashboard = DashboardScreen(app: first)
        if !firstDashboard.waitUntilReady() {
            failWithDiagnostics(in: first, "首次有資料啟動後總覽頁未就緒")
        }
        if firstDashboard.isEmptyStateShown {
            failWithDiagnostics(in: first, "首次有資料啟動卻顯示引導空狀態")
        }
        let seededOrder = firstDashboard.recentOrderRow(orderID: "BL-2604-018")
        if !seededOrder.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: first, "首次有資料啟動未找到預期訂單列 BL-2604-018")
        }

        // When
        first.terminate()
        let second = launch(LaunchOptions(seed: .empty))
        let secondDashboard = DashboardScreen(app: second)
        if !secondDashboard.waitUntilReady() {
            failWithDiagnostics(in: second, "重啟空資料後總覽頁未就緒")
        }

        // Then
        assertEmptyState(BLAccessibilityID.Dashboard.emptyState, in: second)
    }

    /// 驗證英文啟動後終止，不帶語言參數重新啟動時，語言不跨啟動外洩
    ///
    /// - Throws: 英文或預設語言的行動按鈕缺少或文字不符時丟出測試錯誤
    /// - Note: 預期不沿用英文，改顯示預設語言的中文
    /// - Note: 以空狀態行動按鈕的 `label` 分別比對固定英文與中文，確認語言沒有跨啟動外洩
    func testRelaunch_英文啟動後不指定語言重啟_不沿用英文且顯示中文() throws {
        // Given
        let english = launch(LaunchOptions(seed: .empty, language: .english))
        let englishDashboard = DashboardScreen(app: english)
        if !englishDashboard.waitUntilReady() {
            failWithDiagnostics(in: english, "英文啟動後總覽頁未就緒")
        }
        let englishButton = english.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.emptyStateActionButton
        ]
        if !englishButton.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: english, "英文啟動未找到空狀態行動按鈕")
        }
        let englishLabel = englishButton.label
        try requireCondition(
            englishLabel == "Create First Order",
            in: english,
            "英文啟動的行動按鈕應為「Create First Order」，實際為「\(englishLabel)」"
        )

        // When
        english.terminate()
        let fallback = launch(LaunchOptions(seed: .empty))
        let fallbackDashboard = DashboardScreen(app: fallback)
        if !fallbackDashboard.waitUntilReady() {
            failWithDiagnostics(in: fallback, "預設語言重啟後總覽頁未就緒")
        }
        let fallbackButton = fallback.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.emptyStateActionButton
        ]
        if !fallbackButton.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: fallback, "預設語言重啟未找到空狀態行動按鈕")
        }
        let fallbackLabel = fallbackButton.label

        // Then
        try requireCondition(
            fallbackLabel == "建立第一筆訂單",
            in: fallback,
            "預設語言重啟的行動按鈕應為「建立第一筆訂單」，實際為「\(fallbackLabel)」"
        )
    }

    /// 驗證指定固定參考時間啟動後，總覽的日期副標題符合該時間，且近期訂單列出種子中的最新訂單 BL-2604-018
    func testLaunch_指定固定參考時間_日期副標題符合該時間且列出種子訂單() {
        // Given
        var dateStyle = Date.FormatStyle.dateTime
        dateStyle.timeZone = TimeZone.gmt
        dateStyle.locale = Locale(identifier: "zh-Hant")
        dateStyle = dateStyle
            .month(.wide)
            .day(.defaultDigits)
            .weekday(.wide)
        let expectedSubtitle = Self.referenceDate.formatted(dateStyle)
        let options = LaunchOptions(
            seed: .fullOrders,
            referenceDate: Self.referenceDate,
            language: .traditionalChinese
        )

        // When
        let app = launch(options)

        // Then
        let dashboard = DashboardScreen(app: app)
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "固定時間有資料啟動後總覽頁未就緒")
        }
        let subtitle = app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.currentDateSubtitle
        ]
        if !subtitle.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "固定時間副標題 identifier 未出現")
        }
        if subtitle.label != expectedSubtitle {
            failWithDiagnostics(in: app, "固定時間副標題不符：\(subtitle.label) / \(expectedSubtitle)")
        }
        let topRow = dashboard.recentOrderRow(orderID: "BL-2604-018")
        if !topRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "固定時間下近期訂單未出現預期的最新訂單列 BL-2604-018")
        }
    }

    /// 驗證行事曆授權由替身授予、開團資料已載入後，儲存開團提醒可返回詳情頁，且不出現系統權限彈窗
    func testTapSave_行事曆替身授予權限_不出現系統權限彈窗() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders, calendarAccess: .granted))
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "行事曆替身驗收切到開團分頁後未就緒")
        }
        let campaigns = CampaignsScreen(app: app)
        if !campaigns.waitUntilReady() {
            failWithDiagnostics(in: app, "行事曆替身驗收開團列表未就緒")
        }
        let campaignID = "CMP-SAMPLE-KR-APR"
        if !campaigns.hasCampaign(campaignID: campaignID) {
            failWithDiagnostics(in: app, "行事曆替身驗收找不到開團「\(campaignID)」")
        }
        campaigns.tapCampaign(campaignID: campaignID)
        let detail = CampaignDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "行事曆替身驗收開團詳情未就緒")
        }
        detail.openMoreMenu()
        if !detail.tapEdit() {
            failWithDiagnostics(in: app, "行事曆替身驗收無法開啟開團編輯")
        }
        let edit = CampaignEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "行事曆替身驗收開團編輯表單未就緒")
        }
        edit.toggleReminder()

        // When
        edit.tapSave()

        // Then
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "儲存開團提醒後詳情頁未回到可用狀態")
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.count > 0 {
            failWithDiagnostics(in: app, "儲存提醒後出現系統權限彈窗，行事曆替身未接管授權")
        }
    }
}
