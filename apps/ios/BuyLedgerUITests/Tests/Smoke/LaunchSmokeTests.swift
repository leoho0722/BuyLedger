//
//  LaunchSmokeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 啟動與分頁切換的冒煙測試
final class LaunchSmokeTests: BLUITestCase {

    // MARK: - Tests

    /// 冷啟動應能進入前景
    @MainActor
    func testColdLaunchReachesForeground() {
        let app = launch()
        if app.state != .runningForeground {
            failWithDiagnostics(in: app, "冷啟動後 App 未停在前景，實際狀態代碼為 \(app.state.rawValue)")
        }
    }

    /// 啟動後預設停在總覽頁
    @MainActor
    func testDefaultTabIsDashboard() {
        let app = launch()
        let dashboard = DashboardScreen(app: app)
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "啟動後總覽頁根 identifier「\(dashboard.rootIdentifier)」逾時仍未出現")
        }
    }

    /// 依序切換五個分頁，每次等目的地畫面就緒
    @MainActor
    func testAllTabsSwitch() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        if !root.waitUntilReady() {
            failWithDiagnostics(in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        }

        // go* 已內建等待，這裡只驗證回傳值
        expectTabReady(root.goToDashboard(), "總覽", in: app)
        expectTabReady(root.goToOrders(), "訂單", in: app)
        expectTabReady(root.goToCampaigns(), "開團", in: app)
        expectTabReady(root.goToInsights(), "分析", in: app)
        expectTabReady(root.goToMore(), "更多", in: app)
    }

    /// 切到某分頁後，該分頁應回報選取態、其他分頁不應
    @MainActor
    func testSelectedTabReportsSelectionState() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        expectTabReady(root.goToMore(), "更多", in: app)

        if !root.isTabSelected(.more) {
            failWithDiagnostics(in: app, "切到更多分頁後，該分頁未回報選取態")
        }
        if root.isTabSelected(.dashboard) {
            failWithDiagnostics(in: app, "更多分頁選取時，總覽分頁不應同時回報選取態")
        }
    }
}

// MARK: - Private Method

private extension LaunchSmokeTests {

    /// 切換分頁後驗目的地是否就緒，未就緒即附診斷失敗
    /// - Parameters:
    ///   - isReady: 目的地畫面是否已就緒
    ///   - tabName: 分頁顯示名稱
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    func expectTabReady(
        _ isReady: Bool,
        _ tabName: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !isReady {
            failWithDiagnostics(in: app, "切換到「\(tabName)」分頁後畫面未就緒", file: file, line: line)
        }
    }
}
