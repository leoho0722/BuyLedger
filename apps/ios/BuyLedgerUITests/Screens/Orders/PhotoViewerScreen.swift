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
        app.waitForNavigationBarTitle(text, timeout: timeout)
    }

    /// 對目前照片左滑換到下一張
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 照片逾時仍不可點時丟出 `UITestError.stopped`
    func swipeToNextPhoto(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let image = app.images[BLAccessibilityID.PhotoViewer.image].firstMatch
        try image.requireHittable(
            in: app,
            timeout: 5,
            file: file,
            line: line
        )
        image.swipeLeft()
    }

    /// 點唯一可互動的系統返回鍵，返回編輯表單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapBack(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapUniqueNativeBackButton(file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension PhotoViewerScreen: ScreenProtocol {

    /// 判定檢視器已推進呈現的根 identifier (檢視器容器)
    var rootIdentifier: String {
        BLAccessibilityID.PhotoViewer.root
    }
}
