//
//  OrderMergeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單合併確認表單的關閉流程測試
final class OrderMergeTests: BLUITestCase {

    // MARK: - Properties

    /// 發起合併的種子訂單編號
    private static let baseOrderID = "UITEST-MRG-001"

    /// 可合併的候選訂單編號 (推進合併時點選)
    private static let candidateOrderID = "UITEST-MRG-002"

    /// 合併確認的預填資料屬於初始草稿，未修改時可下滑關閉
    @MainActor
    func testDismissSheetBySwipe_合併確認未修改_關閉表單並回到詳情() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let merge = openMergeCandidates(app)
        merge.tapCandidate(orderID: Self.candidateOrderID)
        let edit = OrderEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "無照片的合併確認表單未就緒")
            return
        }
        edit.submitCustomerName()

        // When
        let isDismissed = app.dismissSheetBySwipe(edit.rootElement)

        // Then
        if !isDismissed {
            failWithDiagnostics(in: app, "未修改的合併確認表單無法下滑關閉")
            return
        }
        if app.alerts.firstMatch.exists {
            failWithDiagnostics(in: app, "未修改的合併確認下滑後不應顯示捨棄確認")
            return
        }
        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "下滑關閉合併確認後未回到來源訂單詳情")
        }
    }
}

// MARK: - Private Method

private extension OrderMergeTests {

    /// 開啟合併候選流程並回傳 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的合併候選流程 Page Object
    @MainActor
    func openMergeCandidates(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MergeFlowScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到訂單分頁後畫面未就緒",
                file: file,
                line: line
            )
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        orders.tapOrder(orderID: Self.baseOrderID, file: file, line: line)

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點訂單「\(Self.baseOrderID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        detail.openMoreMenu(file: file, line: line)
        if !detail.tapMerge(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "更多選單的合併項目未出現或不可點",
                file: file,
                line: line
            )
        }

        let merge = MergeFlowScreen(app: app)
        if !merge.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點合併後候選 sheet 根 identifier「\(merge.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return merge
    }
}
