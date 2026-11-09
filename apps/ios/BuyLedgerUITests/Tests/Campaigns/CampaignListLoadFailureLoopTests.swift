//
//  CampaignListLoadFailureLoopTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

/// 開團持續載入失敗時，往返其他分頁後失敗畫面是否穩定的 UI 測試
@MainActor
final class CampaignListLoadFailureLoopTests: BLUITestCase {

    /// 驗證開團每次載入失敗時，首次進入與往返總覽、訂單後持續顯示失敗訊息與重試鍵且不再載入
    func testTabSwitch_開團每次載入皆失敗_返回清單仍穩定顯示失敗畫面() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders, loadFailure: .campaigns))
        let navigator = AppNavigator(app: app)
        let campaignsRoot = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.Common.selectedItem(.campaigns))
            .firstMatch
        // 開團根容器涵蓋載入中與失敗分支，避免只查成功清單而漏掉指示器
        let loading = campaignsRoot.progressIndicators.firstMatch

        // When
        navigator.selectTab(.campaigns)

        // Then
        guard campaignsRoot.waitForExistence(timeout: 10) else {
            failWithDiagnostics(in: app, "開團分頁的根容器未出現，無法縮限載入指示器的查詢範圍")
            return
        }
        guard assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Campaigns.listLoadFailure,
            present: [BLAccessibilityID.Campaigns.listLoadFailureRetryButton],
            absent: [],
            absentElements: [loading],
            context: "首次進入開團清單"
        ) else {
            return
        }

        // When
        navigator.selectTab(.dashboard)
        navigator.selectTab(.campaigns)

        // Then
        guard assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Campaigns.listLoadFailure,
            present: [BLAccessibilityID.Campaigns.listLoadFailureRetryButton],
            absent: [],
            absentElements: [loading],
            context: "切換總覽再返回開團清單"
        ) else {
            return
        }

        // When
        navigator.selectTab(.orders)
        navigator.selectTab(.campaigns)

        // Then
        guard assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Campaigns.listLoadFailure,
            present: [BLAccessibilityID.Campaigns.listLoadFailureRetryButton],
            absent: [],
            absentElements: [loading],
            context: "切換訂單再返回開團清單"
        ) else {
            return
        }
    }
}
