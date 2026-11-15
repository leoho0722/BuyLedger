//
//  PhotoViewerUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/21.
//

import XCTest

/// 照片檢視器換頁後返回編輯表單的 UI 測試
@MainActor
final class PhotoViewerUITests: BLUITestCase {

    // MARK: - Properties

    /// 帶滿張照片的種子訂單編號 (`photos` profile 的唯一訂單)
    private static let photoOrderID = "UITEST-PHT-001"

    /// 驗證照片檢視器從 1/5 左滑至 2/5 後，仍能返回原編輯表單
    ///
    /// - Throws: 必要的 UI 操作或第一張照片前置不成立時丟出 UITestError.stopped
    func testSwipeToNextPhoto_檢視器顯示第一張_換到第二張後可返回編輯表單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .photos))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: Self.photoOrderID).openEdit()
        let viewer = try edit.tapPhotoThumbnail(index: 0)
        try requireCondition(viewer.hasPageCount("1/5"), in: app, "檢視器推進後導覽列未顯示計數 1/5")

        // When
        try viewer.swipeToNextPhoto()
        let hasSecondPage = viewer.hasPageCount("2/5")
        try viewer.tapBack()

        // Then
        XCTAssertTrue(hasSecondPage, "檢視器內左滑後導覽列未換頁至 2/5")
        XCTAssertTrue(viewer.rootElement.waitForDisappearance(), "點 Back 後檢視器未關閉")
        XCTAssertTrue(edit.waitUntilReady(), "Back 後未返回編輯表單")
    }
}
