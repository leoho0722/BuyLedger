//
//  OrderDetailMenuTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/7.
//

import XCTest

/// 訂單詳情更多選單的編輯、合併與刪除入口 UI 測試，涵蓋 iPhone 推入與 iPad 右欄
@MainActor
final class OrderDetailMenuTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中用來開啟詳情的訂單編號
    private static let baseOrderID = "UITEST-MRG-001"

    /// `mergeCandidates` 中可與詳情訂單合併的候選編號
    private static let candidateOrderID = "UITEST-MRG-002"

    /// 驗證從更多選單開啟編輯後未修改就取消，表單收回並回到原訂單詳情，營收仍為 $1,200
    func testOrderDetailMoreMenu_點編輯後取消_返回原訂單詳情() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let detail = openMergeableOrderDetail(in: app)
        let edit = OrderEditScreen(app: app)
        detail.openMoreMenu()
        if !detail.tapEdit() {
            failWithDiagnostics(in: app, "詳情更多選單的編輯入口未出現或不可點")
        }
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點編輯後訂單編輯表單未出現")
        }

        // When
        edit.tapCancel()

        // Then
        if !edit.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "取消編輯後表單未收回")
        }
        assertOriginalDetailIsDisplayed(detail, in: app)
    }

    /// 驗證從更多選單開啟合併候選，列出可合併訂單後取消，候選畫面收回並回到原訂單詳情，營收仍為 $1,200
    func testOrderDetailMoreMenu_點合併後取消_返回原訂單詳情() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let detail = openMergeableOrderDetail(in: app)
        let merge = MergeFlowScreen(app: app)
        detail.openMoreMenu()
        if !detail.tapMerge() {
            failWithDiagnostics(in: app, "詳情更多選單的合併入口未出現或不可點")
        }
        if !merge.waitUntilReady() {
            failWithDiagnostics(in: app, "點合併後第一步候選畫面未出現")
        }
        if !merge.hasCandidate(orderID: Self.candidateOrderID) {
            failWithDiagnostics(in: app, "合併候選畫面未列出可合併訂單")
        }

        // When
        merge.tapCancel()

        // Then
        if !merge.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "取消合併後候選畫面未收回")
        }
        assertOriginalDetailIsDisplayed(detail, in: app)
    }

    /// 驗證從更多選單點刪除後取消，確認 alert 收回，原訂單詳情仍保留且營收為 $1,200
    func testOrderDetailMoreMenu_點刪除後取消_保留原訂單詳情() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let detail = openMergeableOrderDetail(in: app)
        detail.openMoreMenu()
        if !detail.tapDelete() {
            failWithDiagnostics(in: app, "詳情更多選單的刪除入口未出現或不可點")
        }
        if !detail.deleteConfirmationExists() {
            failWithDiagnostics(in: app, "點刪除後確認 alert 未出現")
        }
        app.assertAlertMessage(contains: "後無法復原")

        // When
        detail.cancelDelete()

        // Then
        if !detail.deleteConfirmationDismissed() {
            failWithDiagnostics(in: app, "取消刪除後確認 alert 未收回")
        }
        assertOriginalDetailIsDisplayed(detail, in: app)
    }
}

// MARK: - Private Method

private extension OrderDetailMenuTests {

    /// 切到訂單分頁並點開可合併的種子訂單，iPhone 與 iPad 的版面差異由導覽 Page Object 處理
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已開啟的原訂單詳情
    func openMergeableOrderDetail(in app: XCUIApplication) -> OrderDetailScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒")
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "訂單清單未就緒")
        }
        orders.tapOrder(orderID: Self.baseOrderID)
        let detail = OrderDetailScreen(app: app)
        assertOriginalDetailIsDisplayed(detail, in: app)
        return detail
    }

    /// 確認原訂單詳情仍顯示，且營收與未編輯或合併前相同
    ///
    /// - Parameters:
    ///   - detail: 原訂單詳情的 Page Object
    ///   - app: 受測 App
    func assertOriginalDetailIsDisplayed(_ detail: OrderDetailScreen, in app: XCUIApplication) {
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "原訂單詳情未顯示")
        }
        if detail.summaryValue(.revenue) != "$1,200" {
            failWithDiagnostics(in: app, "原訂單詳情應保留營收 $1,200")
        }
    }
}
