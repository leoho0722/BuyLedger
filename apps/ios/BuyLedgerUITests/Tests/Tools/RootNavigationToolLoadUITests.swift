//
//  RootNavigationToolLoadUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/11.
//

import XCTest

/// 工具頁延遲讀取時切換根分頁與重試的 UI 旅程測試
@MainActor
final class RootNavigationToolLoadUITests: BLUITestCase {

    /// 驗證匯率頁延遲讀取期間切分頁後仍完成失敗，重試再次至少等待啟動選項指定的延遲
    ///
    /// - Throws: 導覽、讀取時間窗或重試操作失敗時丟出 UITestError.stopped
    func testTabSelected_匯率延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試() throws {
        // Given
        let options = LaunchOptions(loadFailure: .exchangeRatesDelayed)
        let app = try launch(options)
        let tool = ToolLoadElements(
            app: app,
            name: "匯率頁",
            loadingIdentifier: BLAccessibilityID.Fx.loading,
            loadFailureIdentifier: BLAccessibilityID.Fx.loadFailure,
            retryButtonIdentifier: BLAccessibilityID.Fx.retryButton
        )
        let readStartedAt = Date.now
        let screen = try FxScreen.open(in: app)

        // When
        try switchTabAndReturnDuringRead(
            tool,
            readDelaySeconds: options.readDelaySeconds,
            waitForLoading: { screen.waitForLoading(timeout: $0) }
        )

        // Then
        let hasInitialFailure = screen.waitForLoadFailure(
            timeout: options.delayedReadFailureTimeout
        )
        let initialElapsed = Date.now.timeIntervalSince(readStartedAt)
        XCTAssertTrue(hasInitialFailure, "匯率頁切回後未在逾時內顯示失敗訊息")
        XCTAssertGreaterThanOrEqual(
            initialElapsed,
            TimeInterval(options.readDelaySeconds),
            "匯率頁初次讀取失敗前的間隔不應短於啟動選項指定的延遲"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: tool.loadFailureIdentifier,
            present: [tool.retryButtonIdentifier],
            absent: [tool.loadingIdentifier],
            context: "匯率頁切回更多後",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )

        // When
        let retryStartedAt = Date.now
        try screen.tapRetry()

        // Then
        XCTAssertTrue(
            screen.waitForLoading(timeout: Timing.retryLoadingAppearance),
            "匯率頁點重試鍵後未顯示載入中"
        )
        let hasRetryFailure = screen.waitForLoadFailure(timeout: options.delayedReadFailureTimeout)
        let retryElapsed = Date.now.timeIntervalSince(retryStartedAt)
        XCTAssertTrue(hasRetryFailure, "匯率頁重試後未在逾時內顯示失敗訊息")
        XCTAssertGreaterThanOrEqual(
            retryElapsed,
            TimeInterval(options.readDelaySeconds),
            "匯率頁重試失敗前的間隔不應短於啟動選項指定的延遲"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: tool.loadFailureIdentifier,
            present: [tool.retryButtonIdentifier],
            absent: [tool.loadingIdentifier],
            context: "匯率頁重試後",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }

    /// 驗證報價頁延遲讀取期間切分頁後仍完成失敗，重試再次至少等待啟動選項指定的延遲
    ///
    /// - Throws: 導覽、讀取時間窗或重試操作失敗時丟出 UITestError.stopped
    func testTabSelected_報價延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試() throws {
        // Given
        let options = LaunchOptions(loadFailure: .exchangeRatesDelayed)
        let app = try launch(options)
        let tool = ToolLoadElements(
            app: app,
            name: "報價頁",
            loadingIdentifier: BLAccessibilityID.Quote.loading,
            loadFailureIdentifier: BLAccessibilityID.Quote.loadFailure,
            retryButtonIdentifier: BLAccessibilityID.Quote.retryButton
        )
        let readStartedAt = Date.now
        let screen = try QuoteScreen.open(in: app)

        // When
        try switchTabAndReturnDuringRead(
            tool,
            readDelaySeconds: options.readDelaySeconds,
            waitForLoading: { screen.waitForLoading(timeout: $0) }
        )

        // Then
        let hasInitialFailure = screen.waitForLoadFailure(
            timeout: options.delayedReadFailureTimeout
        )
        let initialElapsed = Date.now.timeIntervalSince(readStartedAt)
        XCTAssertTrue(hasInitialFailure, "報價頁切回後未在逾時內顯示失敗訊息")
        XCTAssertGreaterThanOrEqual(
            initialElapsed,
            TimeInterval(options.readDelaySeconds),
            "報價頁初次讀取失敗前的間隔不應短於啟動選項指定的延遲"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: tool.loadFailureIdentifier,
            present: [tool.retryButtonIdentifier],
            absent: [tool.loadingIdentifier],
            context: "報價頁切回更多後",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )

        // When
        let retryStartedAt = Date.now
        try screen.tapRetry()

        // Then
        XCTAssertTrue(
            screen.waitForLoading(timeout: Timing.retryLoadingAppearance),
            "報價頁點重試鍵後未顯示載入中"
        )
        let hasRetryFailure = screen.waitForLoadFailure(timeout: options.delayedReadFailureTimeout)
        let retryElapsed = Date.now.timeIntervalSince(retryStartedAt)
        XCTAssertTrue(hasRetryFailure, "報價頁重試後未在逾時內顯示失敗訊息")
        XCTAssertGreaterThanOrEqual(
            retryElapsed,
            TimeInterval(options.readDelaySeconds),
            "報價頁重試失敗前的間隔不應短於啟動選項指定的延遲"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: tool.loadFailureIdentifier,
            present: [tool.retryButtonIdentifier],
            absent: [tool.loadingIdentifier],
            context: "報價頁重試後",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }
}

// MARK: - Nested Types

private extension RootNavigationToolLoadUITests {

    /// 載入中指示器出現的觀察時間窗，失敗逾時由啟動選項推導
    enum Timing {

        /// 開啟工具頁後等待載入中指示器出現的秒數
        static let loadingAppearance: TimeInterval = 5

        /// 切回更多分頁後等待載入中指示器仍在的秒數
        static let loadingAfterReturn: TimeInterval = 2

        /// 點重試鍵後等待載入中指示器出現的秒數
        static let retryLoadingAppearance: TimeInterval = 3
    }

    /// 工具頁的診斷名稱與共用穩定性斷言參數，不直接查詢元素
    struct ToolLoadElements {

        /// 受測 App
        let app: XCUIApplication

        /// 失敗訊息中的工具頁名稱
        let name: String

        /// 載入中指示器的 identifier
        let loadingIdentifier: String

        /// 失敗訊息的 identifier
        let loadFailureIdentifier: String

        /// 重試鍵的 identifier
        let retryButtonIdentifier: String
    }
}

// MARK: - Private Method

private extension RootNavigationToolLoadUITests {

    /// 等載入中出現後切到總覽再切回更多，確認切回時仍在原讀取時間窗內
    ///
    /// - Parameters:
    ///   - tool: 受測工具頁的診斷與斷言參數
    ///   - readDelaySeconds: 同一組啟動選項指定的讀取延遲
    ///   - waitForLoading: 由工具頁 Page Object 提供的載入中等待
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 載入時間窗不存在或切換分頁失敗時丟出 UITestError.stopped
    func switchTabAndReturnDuringRead(
        _ tool: ToolLoadElements,
        readDelaySeconds: Int,
        waitForLoading: (TimeInterval) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireCondition(
            waitForLoading(Timing.loadingAppearance),
            in: tool.app,
            "\(tool.name)開啟後未顯示載入中，匯率讀取已結束或未進行，時間窗不存在",
            file: file,
            line: line
        )
        // 只用於切頁往返的原有時間窗檢查；失敗下限在測試本體從觸發讀取前計時
        let loadingSeenAt = Date.now
        let navigator = AppNavigator(app: tool.app)
        try navigator.selectTab(.dashboard, file: file, line: line)
        try navigator.selectTab(.more, file: file, line: line)

        let isLoadingShown = waitForLoading(Timing.loadingAfterReturn)
        let elapsed = Date.now.timeIntervalSince(loadingSeenAt)
        let elapsedText = String(format: "%.1f", elapsed)
        try requireCondition(
            isLoadingShown,
            in: tool.app,
            "\(tool.name)切回更多後不在載入中，時間窗不存在 (經過 \(elapsedText) 秒)",
            file: file,
            line: line
        )
        try requireCondition(
            elapsed < TimeInterval(readDelaySeconds),
            in: tool.app,
            "\(tool.name)切回時已超過讀取延遲，時間窗不存在 (經過 \(elapsedText) 秒)",
            file: file,
            line: line
        )
    }
}
