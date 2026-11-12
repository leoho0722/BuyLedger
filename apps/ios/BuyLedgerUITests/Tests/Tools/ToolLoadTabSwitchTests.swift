//
//  ToolLoadTabSwitchTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/11.
//

import XCTest

/// 更多分頁的匯率與報價工具，在讀取匯率期間切換分頁的載入狀態測試
@MainActor
final class ToolLoadTabSwitchTests: BLUITestCase {

    /// 驗證匯率頁在匯率延遲讀取期間切到總覽再切回更多，讀取完成後顯示失敗訊息與重試鍵且不回到載入中
    func testTabSwitch_匯率延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .exchangeRatesDelayed))
        _ = FxScreen.open(from: app)
        let tool = ToolLoadElements(
            app: app,
            name: "匯率頁",
            loadingIdentifier: BLAccessibilityID.Fx.loading,
            loadFailureIdentifier: BLAccessibilityID.Fx.loadFailure,
            retryButtonIdentifier: BLAccessibilityID.Fx.retryButton
        )

        // When
        guard switchTabAndReturnDuringRead(tool) else {
            return
        }

        // Then
        assertReadFailureShownAndRetryable(tool)
    }

    /// 驗證報價頁在匯率延遲讀取期間切到總覽再切回更多，讀取完成後顯示失敗訊息與重試鍵且不回到載入中
    func testTabSwitch_報價延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .exchangeRatesDelayed))
        _ = QuoteScreen.open(from: app)
        let tool = ToolLoadElements(
            app: app,
            name: "報價頁",
            loadingIdentifier: BLAccessibilityID.Quote.loading,
            loadFailureIdentifier: BLAccessibilityID.Quote.loadFailure,
            retryButtonIdentifier: BLAccessibilityID.Quote.retryButton
        )

        // When
        guard switchTabAndReturnDuringRead(tool) else {
            return
        }

        // Then
        assertReadFailureShownAndRetryable(tool)
    }
}

// MARK: - Nested Types

extension ToolLoadTabSwitchTests {

    /// 等待與取樣的秒數，皆為估計值
    private enum Timing {

        /// 開啟工具頁後等待載入中指示器出現的秒數
        static let loadingAppearance: TimeInterval = 5

        /// 切回更多分頁後等待載入中指示器仍在的秒數
        static let loadingAfterReturn: TimeInterval = 2

        /// 切回更多分頁後等待失敗訊息出現的秒數
        static let failureAfterReturn: TimeInterval = 10

        /// 點重試鍵後等待載入中指示器出現的秒數
        static let retryLoadingAppearance: TimeInterval = 3

        /// 點重試鍵後等待失敗訊息第一次出現的秒數
        static let retryFailureAppearance: TimeInterval = 12

        /// App 端匯率替身每次讀取先延遲的秒數，對齊 `BLUITestLoadFailure.exchangeRatesDelayed`
        static let readDelay: TimeInterval = 8
    }

    /// 工具頁狀態橫幅的載入中、失敗訊息與重試鍵
    @MainActor
    fileprivate struct ToolLoadElements {

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

        /// 載入中指示器
        var loading: XCUIElement {
            app.descendants(matching: .any)[loadingIdentifier]
        }

        /// 失敗訊息
        var loadFailure: XCUIElement {
            app.descendants(matching: .any)[loadFailureIdentifier]
        }

        /// 重試鍵
        var retryButton: XCUIElement {
            app.descendants(matching: .any)[retryButtonIdentifier]
        }
    }
}

// MARK: - Private Method

private extension ToolLoadTabSwitchTests {

    /// 等載入中出現後切到總覽再切回更多，並確認切回時原讀取仍在延遲內
    ///
    /// - Parameter tool: 受測工具頁的橫幅元素
    /// - Returns: 切回時載入中仍存在，且距第一次看到載入中不足讀取延遲秒數
    func switchTabAndReturnDuringRead(_ tool: ToolLoadElements) -> Bool {
        guard tool.loading.waitForExistence(timeout: Timing.loadingAppearance) else {
            let seconds = Int(Timing.loadingAppearance)
            failWithDiagnostics(
                in: tool.app,
                "\(tool.name)開啟後 \(seconds) 秒內未顯示載入中，匯率讀取已結束或未進行，時間窗不存在"
            )
            return false
        }
        let loadingSeenAt = Date()

        let navigator = AppNavigator(app: tool.app)
        navigator.selectTab(.dashboard)
        navigator.selectTab(.more)

        let isLoadingShown = tool.loading.waitForExistence(timeout: Timing.loadingAfterReturn)
        let elapsed = Date().timeIntervalSince(loadingSeenAt)
        let elapsedText = String(format: "%.1f", elapsed)
        guard isLoadingShown else {
            failWithDiagnostics(
                in: tool.app,
                "\(tool.name)切回更多後不在載入中，時間窗不存在，切回前原讀取可能已結束 (經過 \(elapsedText) 秒)"
            )
            return false
        }
        guard elapsed < Timing.readDelay else {
            failWithDiagnostics(
                in: tool.app,
                "\(tool.name)切回時已超過讀取延遲，時間窗不存在，切回前原讀取可能已結束 (經過 \(elapsedText) 秒)"
            )
            return false
        }
        return true
    }

    /// 確認切回後讀取完成時顯示失敗訊息與重試鍵，再點重試鍵確認會重新讀取並再次顯示失敗
    ///
    /// - Parameter tool: 受測工具頁的橫幅元素
    func assertReadFailureShownAndRetryable(_ tool: ToolLoadElements) {
        // Then
        guard tool.loadFailure.waitForExistence(timeout: Timing.failureAfterReturn) else {
            let seconds = Int(Timing.failureAfterReturn)
            let loadingState = tool.loading.exists ? "仍存在" : "已消失"
            failWithDiagnostics(
                in: tool.app,
                "\(tool.name)切回後 \(seconds) 秒內未顯示失敗訊息，載入中\(loadingState)"
            )
            return
        }
        guard assertLoadStateStaysStable(
            in: tool.app,
            waitingFor: tool.loadFailureIdentifier,
            present: [tool.retryButtonIdentifier],
            absent: [tool.loadingIdentifier],
            context: "\(tool.name)切回更多後"
        ) else {
            return
        }

        // When
        tool.retryButton.tapAfterWaiting(in: tool.app)

        // Then
        guard tool.loading.waitForExistence(timeout: Timing.retryLoadingAppearance) else {
            let seconds = Int(Timing.retryLoadingAppearance)
            failWithDiagnostics(
                in: tool.app,
                "\(tool.name)點重試鍵後 \(seconds) 秒內未顯示載入中"
            )
            return
        }
        assertLoadStateStaysStable(
            in: tool.app,
            waitingFor: tool.loadFailureIdentifier,
            present: [tool.retryButtonIdentifier],
            absent: [tool.loadingIdentifier],
            context: "\(tool.name)重試後",
            firstAppearanceTimeout: Timing.retryFailureAppearance
        )
    }
}
