//
//  PhotoViewerPagingTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/21.
//

import XCTest

/// 照片檢視器推進呈現與換頁的回歸測試
final class PhotoViewerPagingTests: BLUITestCase {

    // MARK: - Static Properties

    /// 帶滿張照片的種子訂單編號 (`photos` profile 的唯一訂單)
    private static let photoOrderID = "UITEST-PHT-001"

    // MARK: - Tests

    /// 驗證照片檢視器可換頁並返回編輯表單
    @MainActor
    func testPushedViewerPagesBetweenPhotosAndPopsBack() {
        let app = launch(LaunchOptions(seed: .photos))
        let edit = openEditFormOfPhotoOrder(app)

        edit.tapPhotoThumbnail(index: 0)

        // 關鍵斷言一：檢視器成功推進 (容器根 identifier 出現、置中計數標題為 1/5)
        let viewer = PhotoViewerScreen(app: app)
        if !viewer.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點縮圖後檢視器根 identifier「\(viewer.rootIdentifier)」逾時仍未推進呈現"
            )
        }
        if !viewer.hasPageCount("1/5") {
            failWithDiagnostics(in: app, "檢視器推進後導覽列未顯示計數 1/5")
        }

        // 關鍵斷言二：橫向左滑換到第二張 (計數變為 2/5)
        viewer.swipeToNextPhoto()
        if !viewer.hasPageCount("2/5") {
            failWithDiagnostics(in: app, "檢視器內左滑後導覽列未換頁至 2/5")
        }

        // 關鍵斷言三：宿主堆疊的 Back 返回編輯表單
        viewer.tapBack()
        let viewerRoot = app.descendants(matching: .any)[BLAccessibilityID.PhotoViewer.root]
        if !viewerRoot.waitForDisappearance() {
            failWithDiagnostics(in: app, "點 Back 後檢視器未關閉")
        }
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "Back 後未返回編輯表單，根 identifier 逾時仍未出現")
        }
    }
}

// MARK: - Private Method

private extension PhotoViewerPagingTests {

    /// 切到訂單分頁、點帶照片訂單進詳情、再從更多選單進編輯表單並等就緒
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單編輯表單 Page Object
    @MainActor
    func openEditFormOfPhotoOrder(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderEditScreen {
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

        orders.tapOrder(orderID: Self.photoOrderID)

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點訂單「\(Self.photoOrderID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        detail.openMoreMenu()
        if !detail.tapEdit() {
            failWithDiagnostics(in: app, "更多選單的編輯項目未出現或不可點", file: file, line: line)
        }

        let edit = OrderEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "進編輯後表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return edit
    }
}
