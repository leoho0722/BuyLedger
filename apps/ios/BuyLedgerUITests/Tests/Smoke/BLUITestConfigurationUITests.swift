//
//  BLUITestConfigurationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// UI 測試啟動設定，涵蓋啟動參數組成、資料、語言、固定時間及
/// 行事曆替身
@MainActor
final class BLUITestConfigurationUITests: BLUITestCase {

    // MARK: - Properties

    /// 固定參考時間：2026/6/15 00:00 UTC
    private static let referenceDate = Date(timeIntervalSince1970: 1_781_481_600)

    /// 驗證訂單延遲失敗情境序列化預設讀取延遲秒數
    func testLaunchArguments_訂單延遲失敗預設秒數_帶延遲情境與8秒() {
        // Given
        let options = LaunchOptions(seed: .minimalOrders, loadFailure: .ordersDelayed)

        // When
        let arguments = options.launchArguments

        // Then
        assertArgument("ordersDelayed", follows: "-BLUITestLoadFailure", in: arguments)
        assertArgument("8", follows: "-BLUITestReadDelaySeconds", in: arguments)
    }

    /// 驗證匯率延遲失敗情境序列化指定讀取延遲秒數
    func testLaunchArguments_匯率延遲失敗指定12秒_帶延遲情境與12秒() {
        // Given
        var options = LaunchOptions(seed: .minimalOrders, loadFailure: .exchangeRatesDelayed)
        options.readDelaySeconds = 12

        // When
        let arguments = options.launchArguments

        // Then
        assertArgument("exchangeRatesDelayed", follows: "-BLUITestLoadFailure", in: arguments)
        assertArgument("12", follows: "-BLUITestReadDelaySeconds", in: arguments)
    }

    /// 驗證沒有讀取失敗情境時不序列化讀取延遲秒數旗標
    func testLaunchArguments_沒有讀取失敗_不帶延遲秒數參數() {
        // Given
        let options = LaunchOptions(seed: .minimalOrders)

        // When
        let arguments = options.launchArguments

        // Then
        XCTAssertFalse(arguments.contains("-BLUITestReadDelaySeconds"), "沒有讀取失敗情境時不應帶讀取延遲秒數旗標")
    }

    /// 驗證有資料的 App 終止後以空資料重新啟動，總覽顯示空狀態，不殘留第一次啟動的訂單
    ///
    /// - Throws: 兩次啟動的總覽未就緒、首次啟動缺少預期資料或重啟後空狀態未出現時丟出測試錯誤
    func testLaunch_有資料後改以空資料重啟_總覽顯示空狀態() throws {
        // Given
        let first = try launch(LaunchOptions(seed: .fullOrders))
        let firstDashboard = DashboardScreen(app: first)
        try requireCondition(firstDashboard.waitUntilReady(), in: first, "首次有資料啟動後總覽頁未就緒")
        try requireCondition(!firstDashboard.isEmptyStateShown, in: first, "首次有資料啟動卻顯示引導空狀態")
        let seededOrder = firstDashboard.recentOrderRow(orderID: "BL-2604-018")
        try requireCondition(
            seededOrder.waitForExistence(timeout: 10),
            in: first,
            "首次有資料啟動未找到預期訂單列 BL-2604-018"
        )

        // When
        first.terminate()
        let second = try launch(LaunchOptions(seed: .empty))
        let secondDashboard = DashboardScreen(app: second)
        try requireCondition(secondDashboard.waitUntilReady(), in: second, "重啟空資料後總覽頁未就緒")

        // Then
        try assertEmptyState(BLAccessibilityID.Dashboard.emptyState, in: second)
    }

    /// 驗證英文啟動後終止，不帶語言參數重新啟動時，語言不跨啟動外洩
    ///
    /// - Throws: 英文或預設語言的行動按鈕缺少或文字不符時丟出測試錯誤
    /// - Note: 預期不沿用英文，改顯示預設語言的中文
    /// - Note: 以空狀態行動按鈕的 `label` 分別比對固定英文與中文，確認語言沒有跨啟動外洩
    func testLaunch_英文啟動後不指定語言重啟_不沿用英文且顯示中文() throws {
        // Given
        let english = try launch(LaunchOptions(seed: .empty, language: .english))
        let englishDashboard = DashboardScreen(app: english)
        try requireCondition(englishDashboard.waitUntilReady(), in: english, "英文啟動後總覽頁未就緒")
        let englishLabel = try requireValue(
            englishDashboard.emptyStateActionLabel(),
            in: english,
            "英文啟動未找到空狀態行動按鈕"
        )
        try requireCondition(
            englishLabel == "Create First Order",
            in: english,
            "英文啟動的行動按鈕應為「Create First Order」，實際為「\(englishLabel)」"
        )

        // When
        english.terminate()
        let fallback = try launch(LaunchOptions(seed: .empty))
        let fallbackDashboard = DashboardScreen(app: fallback)
        try requireCondition(fallbackDashboard.waitUntilReady(), in: fallback, "預設語言重啟後總覽頁未就緒")
        let fallbackLabel = try requireValue(
            fallbackDashboard.emptyStateActionLabel(),
            in: fallback,
            "預設語言重啟未找到空狀態行動按鈕"
        )

        // Then
        try requireCondition(
            fallbackLabel == "建立第一筆訂單",
            in: fallback,
            "預設語言重啟的行動按鈕應為「建立第一筆訂單」，實際為「\(fallbackLabel)」"
        )
    }

    /// 驗證指定固定參考時間啟動後，總覽的日期副標題符合該時間，且近期訂單列出種子中的最新訂單 BL-2604-018
    ///
    /// - Throws: 總覽未就緒、日期副標題缺少或不符，或最新訂單列未出現時丟出測試錯誤
    func testLaunch_指定固定參考時間_日期副標題符合該時間且列出種子訂單() throws {
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
        let app = try launch(options)

        // Then
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "固定時間有資料啟動後總覽頁未就緒")
        let subtitle = try requireValue(
            dashboard.currentDateSubtitle(),
            in: app,
            "固定時間副標題 identifier 未出現"
        )
        try requireCondition(
            subtitle == expectedSubtitle,
            in: app,
            "固定時間副標題不符：\(subtitle) / \(expectedSubtitle)"
        )
        let topRow = dashboard.recentOrderRow(orderID: "BL-2604-018")
        try requireCondition(
            topRow.waitForExistence(timeout: 10),
            in: app,
            "固定時間下近期訂單未出現預期的最新訂單列 BL-2604-018"
        )
    }

    /// 驗證行事曆授權由替身授予、開團資料已載入後，儲存開團提醒可返回詳情頁，且不出現系統權限彈窗
    ///
    /// - Throws: 開團、詳情或編輯表單未就緒，或儲存後詳情未回到可用狀態、出現系統彈窗時丟出測試錯誤
    func testSaveButtonTapped_行事曆替身授予權限_不出現系統權限彈窗() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders, calendarAccess: .granted))
        let campaigns = try CampaignsScreen.open(in: app)
        let campaignID = CampaignSeedFixture.koreaCampaignID
        try requireCondition(
            campaigns.hasCampaign(campaignID: campaignID),
            in: app,
            "行事曆替身驗收找不到開團「\(campaignID)」"
        )
        let detail = try campaigns.openDetail(campaignID: campaignID)
        try detail.openMoreMenu()
        let edit = try detail.tapEdit()
        try edit.toggleReminder()

        // When
        try edit.tapSave()

        // Then
        try requireCondition(detail.waitUntilReady(), in: app, "儲存開團提醒後詳情頁未回到可用狀態")
        try BLUITestConfigurationUITestSupport.assertNoSystemPrompt(in: app)
    }
}

// MARK: - Private Method

private extension BLUITestConfigurationUITests {

    /// 斷言指定啟動參數旗標後的值
    ///
    /// - Parameters:
    ///   - expected: 預期的旗標值
    ///   - flag: 要定位的啟動參數旗標
    ///   - arguments: 序列化後的啟動參數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertArgument(
        _ expected: String,
        follows flag: String,
        in arguments: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let index = arguments.firstIndex(of: flag) else {
            XCTFail("啟動參數缺少旗標 \(flag)", file: file, line: line)
            return
        }
        guard arguments.indices.contains(index + 1) else {
            XCTFail("啟動參數旗標 \(flag) 後缺少值", file: file, line: line)
            return
        }
        XCTAssertEqual(
            arguments[index + 1],
            expected,
            "啟動參數旗標 \(flag) 後的值不符",
            file: file,
            line: line
        )
    }
}
