//
//  PhotoViewerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 照片檢視器 (BLPhotoViewer) 的 Page Object
struct PhotoViewerScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定檢視器已推進呈現的根 identifier (檢視器容器)
    /// - Returns: 檢視器根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.PhotoViewer.root
    }
}

// MARK: - Internal Method

@MainActor
extension PhotoViewerScreen {

    /// 導覽列是否顯示指定的換頁計數
    /// - Parameters:
    ///   - text: 預期顯示的換頁計數文字
    ///   - timeout: 等待文字出現的秒數
    /// - Returns: 換頁計數是否在逾時前出現
    @discardableResult
    func hasPageCount(_ text: String, timeout: TimeInterval = 5) -> Bool {
        app.navigationBars.staticTexts[text].waitForExistence(timeout: timeout)
    }

    /// 對目前照片左滑換到下一張
    func swipeToNextPhoto() {
        let image = app.images[BLAccessibilityID.PhotoViewer.image].firstMatch
        _ = image.waitForExistence(timeout: 5)
        image.swipeLeft()
    }

    /// 走宿主堆疊的 Back 返回編輯表單
    func tapBack() {
        let viewerBar = app.navigationBars
            .matching(NSPredicate(format: "identifier CONTAINS '/'"))
            .firstMatch
        let back = viewerBar.buttons[BLAccessibilityID.Common.backButton]
        _ = back.waitForExistence(timeout: 5)
        back.tap()
    }
}
