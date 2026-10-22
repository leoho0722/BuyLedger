//
//  HarnessSelfCheckTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// UI 測試地基的自我檢查
final class HarnessSelfCheckTests: BLUITestCase {

    // MARK: - Properties

    /// 固定參考時間：2026/6/15 00:00 UTC
    private static let referenceDate = Date(timeIntervalSince1970: 1_781_481_600)

    /// 資料不跨啟動殘留：有資料 → 終止 → 空資料重啟，仍為空
    @MainActor
    func testRelaunch_有資料後改以空資料重啟_總覽顯示空狀態() {
        // Given：第一次啟動有完整資料
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

        // When：終止 App 後用空資料重新啟動
        first.terminate()
        let second = launch(LaunchOptions(seed: .empty))
        let secondDashboard = DashboardScreen(app: second)
        if !secondDashboard.waitUntilReady() {
            failWithDiagnostics(in: second, "重啟空資料後總覽頁未就緒")
        }

        // Then：第二次啟動不應殘留第一次的訂單
        assertEmptyState(BLAccessibilityID.Dashboard.emptyState, in: second)
    }

    /// 語言不跨啟動外洩：英文 → 終止 → 不帶 `language` 重啟
    ///
    /// - Throws: 英文啟動的語言指紋不成立時拋出測試錯誤
    /// - Note: 預期不沿用英文，改顯示預設語言的中文
    @MainActor
    func testRelaunch_英文啟動後不指定語言重啟_不沿用英文且顯示中文() throws(any Error) {
        // Given：英文啟動，以空狀態行動按鈕的 label 作為語言指紋，避免以特定字面值當唯一依據
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
        try requireCondition(
            !englishLabel.isEmpty && !containsHan(englishLabel),
            in: english,
            "英文啟動的行動按鈕 label「\(englishLabel)」不像英文"
        )

        // When：終止 App 後不帶 `language` 重新啟動
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

        // Then：與英文不同 (證明英文未殘留)，且含漢字 (證明改顯示中文)
        if fallbackLabel == englishLabel {
            failWithDiagnostics(in: fallback, "重啟後 label 仍與英文相同「\(fallbackLabel)」，語言疑似外洩")
        }
        if !containsHan(fallbackLabel) {
            failWithDiagnostics(in: fallback, "重啟後 label「\(fallbackLabel)」不含中文，未回到預設語言")
        }
    }

    /// 固定參考時間，讓日期分組可重現
    @MainActor
    func testLaunch_指定固定參考時間_日期副標題符合該時間且列出種子訂單() {
        // Given：以固定 UTC 參考時間準備完整資料的啟動選項
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

        // When：以固定時間啟動
        let app = launch(options)

        // Then：日期副標題與固定時間一致，且列出種子中的最新訂單
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

    /// 行事曆授權走替身，儲存提醒時不應被系統權限彈窗攔住
    @MainActor
    func testTapSave_行事曆替身授予權限_不出現系統權限彈窗() {
        // Given：行事曆授權由替身授予，且開團資料已載入
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

        // When：儲存提醒設定
        edit.tapSave()

        // Then：畫面可返回且 SpringBoard 沒有殘留的系統權限 alert
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "儲存開團提醒後詳情頁未回到可用狀態")
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.count > 0 {
            failWithDiagnostics(in: app, "儲存提醒後出現系統權限彈窗，行事曆替身未接管授權")
        }
    }
}

// MARK: - Private Method

private extension HarnessSelfCheckTests {

    /// 判斷字串是否含 CJK 字元
    ///
    /// - Parameter text: 要檢查的字串
    /// - Returns: 字串是否包含 CJK 字元
    func containsHan(_ text: String) -> Bool {
        text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
    }
}
