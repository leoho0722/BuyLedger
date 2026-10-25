//
//  PhotoViewerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 照片檢視器 (`BLPhotoViewer`) 的 Page Object
struct PhotoViewerScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension PhotoViewerScreen {

    /// 等待導覽列出現指定的換頁計數
    ///
    /// - Parameters:
    ///   - text: 預期顯示的換頁計數文字
    ///   - timeout: 等待文字出現的秒數
    /// - Returns: 換頁計數是否在逾時前出現
    func hasPageCount(_ text: String, timeout: TimeInterval = 5) -> Bool {
        app.navigationBars.staticTexts[text].waitForExistence(timeout: timeout)
    }

    /// 對目前照片左滑換到下一張
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func swipeToNextPhoto(file: StaticString = #filePath, line: UInt = #line) {
        let image = app.images[BLAccessibilityID.PhotoViewer.image].firstMatch
        guard image.waitUntilHittableOrFail(
            in: app,
            timeout: 5,
            file: file,
            line: line
        ) else {
            return
        }
        image.swipeLeft()
    }

    /// 點識別碼含斜線的導覽列 Back 鍵，返回編輯表單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapBack(file: StaticString = #filePath, line: UInt = #line) {
        let viewerBar = app.navigationBars
            .matching(NSPredicate(format: "identifier CONTAINS '/'"))
            .firstMatch
        let back = viewerBar.buttons[BLAccessibilityID.Common.backButton]
        back.tapAfterWaiting(
            in: app,
            timeout: 5,
            file: file,
            line: line
        )
    }
}

// MARK: - Screen

extension PhotoViewerScreen: Screen {

    /// 判定檢視器已推進呈現的根 identifier (檢視器容器)
    var rootIdentifier: String {
        BLAccessibilityID.PhotoViewer.root
    }
}
