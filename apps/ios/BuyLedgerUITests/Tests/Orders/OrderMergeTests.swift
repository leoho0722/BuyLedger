//
//  OrderMergeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單合併的進入、候選推進與取消流程測試
final class OrderMergeTests: BLUITestCase {

    // MARK: - Properties

    /// 發起合併的種子訂單編號 (自己不會出現在候選清單)
    private static let baseOrderID = "UITEST-MRG-001"

    /// 可合併的候選訂單編號 (推進合併時點選)
    private static let candidateOrderID = "UITEST-MRG-002"

    /// 另一筆可合併的候選訂單編號
    private static let otherCandidateOrderID = "UITEST-MRG-003"

    /// 合併確認的預填資料屬於初始草稿，未修改時可下滑關閉
    @MainActor
    func testMergeConfirmation_未修改時下滑_關閉表單並回到詳情() {
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
        if !app.dismissSheetBySwipe(edit.rootElement) {
            failWithDiagnostics(in: app, "未修改的合併確認表單無法下滑關閉")
            return
        }

        // Then
        if app.alerts.firstMatch.exists {
            failWithDiagnostics(in: app, "未修改的合併確認下滑後不應顯示捨棄確認")
            return
        }
        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "下滑關閉合併確認後未回到來源訂單詳情")
        }
    }

    /// 開啟合併流程並確認候選訂單
    @MainActor
    func testEnterMerge_發起合併_候選清單含其他訂單且排除自己() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))

        // When
        let merge = openMergeCandidates(app)

        // Then
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
    func testTapCandidate_點選候選訂單_進入合併確認表單() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let merge = openMergeCandidates(app)

        // When
        merge.tapCandidate(orderID: Self.candidateOrderID)

        // 點候選後可能進入照片挑選或合併表單，輪詢等待其中一個出現
        let edit = OrderEditScreen(app: app)
        let photoContinue = app.buttons[BLAccessibilityID.OrderMerge.photoContinueButton]
        let editRoot = app.descendants(matching: .any)[edit.rootIdentifier]
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline, !photoContinue.exists, !editRoot.exists {
            if photoContinue.waitForExistence(timeout: 0.3) {
                break
            }
        }
        if !photoContinue.exists, !editRoot.exists {
            failWithDiagnostics(in: app, "點候選後照片挑選步驟與合併確認表單皆未出現")
        }

        // 若進入照片挑選步驟，點繼續推進到合併確認表單
        if photoContinue.exists {
            merge.tapPhotoContinue()
        }

        // Then
        // 合併確認表單即 `OrderEditView` (標題「新訂單」)，以其根 `identifier` 就緒判定
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "推進合併後確認表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現")
        }
    }

    /// 取消合併：進候選 sheet → 取消 → sheet 收回、回到發起合併的訂單詳情
    @MainActor
    func testCancelMerge_候選畫面按取消_回到原訂單詳情() {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let merge = openMergeCandidates(app)

        // When
        merge.tapCancel()

        // Then
        // 取消後候選 sheet 應收回並回到訂單詳情
        if !merge.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "點取消後，合併候選 sheet 未收回")
        }

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消合併後訂單詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現")
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
