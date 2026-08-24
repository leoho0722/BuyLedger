//
//  OrderMergeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單合併的進入、候選推進與取消流程測試
final class OrderMergeTests: BLUITestCase {

    // MARK: - Static Properties

    /// 發起合併的種子訂單編號 (自己不會出現在候選清單)
    private static let baseOrderID = "UITEST-MRG-001"

    /// 可合併的候選訂單編號 (推進合併時點選)
    private static let candidateOrderID = "UITEST-MRG-002"

    /// 另一筆可合併的候選訂單編號
    private static let otherCandidateOrderID = "UITEST-MRG-003"

    // MARK: - Tests

    /// 開啟合併流程並確認候選訂單
    @MainActor
    func testEnterMergeShowsCandidatesExcludingSelf() {
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let merge = openMergeCandidates(app)

        // 候選清單應含另兩筆可合併訂單
        if !merge.hasCandidate(orderID: Self.candidateOrderID) {
            failWithDiagnostics(in: app, "候選清單未含可合併訂單「\(Self.candidateOrderID)」")
        }
        if !merge.hasCandidate(orderID: Self.otherCandidateOrderID) {
            failWithDiagnostics(in: app, "候選清單未含可合併訂單「\(Self.otherCandidateOrderID)」")
        }

        // 發起合併的訂單自己不應出現在候選清單
        if merge.candidateRow(orderID: Self.baseOrderID).exists {
            failWithDiagnostics(in: app, "發起合併的訂單「\(Self.baseOrderID)」不應出現在候選清單")
        }
    }

    /// 選候選推進：點候選 → 依有無照片步驟分支，最終抵達合併確認表單
    @MainActor
    func testTapCandidateReachesMergeConfirmationForm() {
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let merge = openMergeCandidates(app)

        merge.tapCandidate(orderID: Self.candidateOrderID)

        // 點候選後可能進入照片挑選或合併表單，輪詢等待其中一個出現。
        let edit = OrderEditScreen(app: app)
        let photoContinue = app.buttons[BLAccessibilityID.OrderMerge.photoContinueButton]
        let editRoot = app.descendants(matching: .any)[edit.rootIdentifier]
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline, !photoContinue.exists, !editRoot.exists {
            _ = photoContinue.waitForExistence(timeout: 0.3)
        }
        if !photoContinue.exists, !editRoot.exists {
            failWithDiagnostics(in: app, "點候選後照片挑選步驟與合併確認表單皆未出現")
        }

        // 若進入照片挑選步驟，點繼續推進到合併確認表單
        if photoContinue.exists {
            merge.tapPhotoContinue()
        }

        // 合併確認表單即 OrderEditView (標題「新訂單」)，以其根 identifier 就緒判定
        if !edit.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "推進合併後確認表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現"
            )
        }
    }

    /// 取消合併：進候選 sheet → 取消 → sheet 收回、回到發起合併的訂單詳情
    @MainActor
    func testCancelMergeReturnsToOrders() {
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let merge = openMergeCandidates(app)

        merge.tapCancel()

        // 取消後候選 sheet 應收回並回到訂單詳情。
        if !merge.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "點取消後,合併候選 sheet 未收回")
        }

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "取消合併後訂單詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現"
            )
        }
    }
}

// MARK: - Private Method

private extension OrderMergeTests {

    /// 開啟合併候選流程並回傳 page object
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
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒", file: file, line: line)
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

        orders.tapOrder(orderID: Self.baseOrderID)

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點訂單「\(Self.baseOrderID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        detail.openMoreMenu()
        if !detail.tapMerge() {
            failWithDiagnostics(in: app, "更多選單的合併項目未出現或不可點", file: file, line: line)
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
