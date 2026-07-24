//
//  LaunchSmokeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 啟動與分頁切換的冒煙測試
///
/// 只驗最基本的「能起來、停在對的頁、五個分頁都切得動」，用來守住地基本身；
/// 一律以畫面根 identifier 判定就緒，找不到 App 元素即附診斷失敗、不 skip
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

        // RootNavigationScreen 的 go* 已內建就緒等待 (有根 identifier 者等根、其餘等分頁選取)，逐一驗回傳值
        expectTabReady(root.goToDashboard(), "總覽", in: app)
        expectTabReady(root.goToOrders(), "訂單", in: app)
        expectTabReady(root.goToCampaigns(), "開團", in: app)
        expectTabReady(root.goToInsights(), "分析", in: app)
        expectTabReady(root.goToMore(), "更多", in: app)
    }

    /// 切到某分頁後，該分頁應回報選取態、其他分頁不應
    ///
    /// 側邊欄版面讀 `isSelected` trait (選取原本只以配色表達)，分頁列版面以目的地畫面是否呈現間接判定
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
    ///   - isReady: 切換方法回傳的就緒結果
    ///   - tabName: 分頁名稱，僅供失敗訊息辨識
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
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
