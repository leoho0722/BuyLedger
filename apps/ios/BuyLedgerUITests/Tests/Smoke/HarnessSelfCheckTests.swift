//
//  HarnessSelfCheckTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// UI 測試地基的自我檢查
final class HarnessSelfCheckTests: BLUITestCase {

    // MARK: - Tests

    /// 空 profile 啟動應顯示引導空狀態
    @MainActor
    func testEmptyProfileShowsEmptyState() {
        let app = launch(LaunchOptions(seed: .empty))
        let dashboard = DashboardScreen(app: app)
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "空資料啟動後總覽頁未就緒")
        }
        assertEmptyState(BLAccessibilityID.Dashboard.emptyState, in: app)
    }

    /// 有資料的 profile 啟動應顯示內容，且 KPI 卡帶值、不落空狀態
    @MainActor
    func testPopulatedProfileShowsContent() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let dashboard = DashboardScreen(app: app)
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "有資料啟動後總覽頁未就緒")
        }
        if dashboard.isEmptyStateShown {
            failWithDiagnostics(in: app, "有資料時總覽頁仍顯示引導空狀態")
        }
        // KPI 卡合併朗讀，主要數值在 accessibilityValue。
        if dashboard.kpiValue(.netProfit).isEmpty {
            failWithDiagnostics(in: app, "淨獲利 hero 卡沒有 accessibility value")
        }
        if dashboard.kpiValue(.revenue).isEmpty {
            failWithDiagnostics(in: app, "營業額 KPI 卡沒有 accessibility value")
        }
    }

    /// 資料不跨啟動殘留：空 → 終止 → 再空，仍為空
    @MainActor
    func testDataDoesNotSurviveRelaunch() {
        let first = launch(LaunchOptions(seed: .empty))
        let firstDashboard = DashboardScreen(app: first)
        if !firstDashboard.waitUntilReady() {
            failWithDiagnostics(in: first, "首次空資料啟動後總覽頁未就緒")
        }
        assertEmptyState(BLAccessibilityID.Dashboard.emptyState, in: first)

        first.terminate()

        let second = launch(LaunchOptions(seed: .empty))
        let secondDashboard = DashboardScreen(app: second)
        if !secondDashboard.waitUntilReady() {
            failWithDiagnostics(in: second, "重啟空資料後總覽頁未就緒")
        }
        // 仍為空即證明前次啟動未在下次啟動殘留任何資料
        assertEmptyState(BLAccessibilityID.Dashboard.emptyState, in: second)
    }

    /// 語言不跨啟動外洩：英文 → 終止 → 不帶 language 重啟，應回到預設語言
    @MainActor
    func testLanguageDoesNotLeak() {
        // 以空狀態行動按鈕的 label 作為語言指紋，避免以特定字面值當唯一依據
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
        // 英文語言下按鈕文字不應含漢字
        if englishLabel.isEmpty || containsHan(englishLabel) {
            failWithDiagnostics(in: english, "英文啟動的行動按鈕 label「\(englishLabel)」不像英文")
        }

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
        // 與英文不同 (證明英文未殘留)，且含漢字 (證明回到正體中文預設)
        if fallbackLabel == englishLabel {
            failWithDiagnostics(in: fallback, "重啟後 label 仍與英文相同「\(fallbackLabel)」，語言疑似外洩")
        }
        if !containsHan(fallbackLabel) {
            failWithDiagnostics(in: fallback, "重啟後 label「\(fallbackLabel)」未回到預設的正體中文")
        }
    }

    /// 固定參考時間，讓日期分組可重現
    @MainActor
    func testFixedNowGivesStableDateGrouping() {
        // fullOrders 依日期位移建立，最新訂單位移最小
        let referenceDate = Self.utcDate(year: 2026, month: 4, day: 30)
        let app = launch(LaunchOptions(seed: .fullOrders, referenceDate: referenceDate))
        let dashboard = DashboardScreen(app: app)
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "固定時間有資料啟動後總覽頁未就緒")
        }
        let topRow = dashboard.recentOrderRow(orderID: "BL-2604-018")
        if !topRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "固定時間下近期訂單未出現預期的最新訂單列 BL-2604-018")
        }
    }

    /// 載入失敗注入應呈現可用 identifier 定位的失敗容器與重試鈕
    @MainActor
    func testLoadFailureInjectionShowsFailureView() {
        // .orders 讓 repository 讀取失敗；總覽頁顯示可定位的失敗容器。
        let app = launch(LaunchOptions(seed: .fullOrders, loadFailure: .orders))

        let failureContainer = app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.loadFailure
        ]
        if !failureContainer.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "注入訂單載入失敗後，總覽頁未出現載入失敗容器")
        }
        let retryButton = app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.loadFailureRetryButton
        ]
        if !retryButton.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "載入失敗容器未出現重試按鈕")
        }
    }

    /// 行事曆授權走替身，啟動不應被系統權限彈窗攔住
    @MainActor
    func testCalendarStubDoesNotPrompt() {
        let app = launch(LaunchOptions(seed: .fullOrders, calendarAccess: .granted))
        let dashboard = DashboardScreen(app: app)
        // 總覽頁能就緒即代表沒有系統彈窗蓋在畫面上把互動擋掉
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "行事曆替身下總覽頁未能就緒，疑似被系統權限彈窗攔截")
        }
        // 進一步確認 SpringBoard 上沒有殘留的系統權限 alert
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.count > 0 {
            failWithDiagnostics(in: app, "啟動後出現系統權限彈窗，行事曆替身未接管授權")
        }
    }
}

// MARK: - Private Method

private extension HarnessSelfCheckTests {

    /// 判斷字串是否含 CJK 字元
    /// - Parameter text: 要檢查的字串
    /// - Returns: 字串是否包含 CJK 字元
    func containsHan(_ text: String) -> Bool {
        text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
    }

    /// 以格里曆 UTC 組出指定年月日的當日零時，供固定參考時間使用
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    static func utcDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
