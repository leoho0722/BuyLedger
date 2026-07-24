//
//  PhotoViewerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 照片檢視器 (BLPhotoViewer) 的 Page Object
///
/// 檢視器由編輯表單以 push 呈現，就緒以檢視器容器根 identifier 判定；換頁計數併入導覽列標題、掛不上 identifier，
/// 由本 Page Object 以計數文字於 `navigationBars` 定位。橫向換頁對目前照片施加左滑手勢，返回走宿主堆疊的 Back
struct PhotoViewerScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定檢視器已推進呈現的根 identifier (檢視器容器)
    var rootIdentifier: String {
        BLAccessibilityID.PhotoViewer.root
    }
}

// MARK: - Internal Method

@MainActor
extension PhotoViewerScreen {

    /// 導覽列是否顯示指定的換頁計數
    ///
    /// 計數 (如「1/5」) 併入導覽列標題、掛不上 identifier，故以計數文字於 `navigationBars` 定位
    /// - Parameters:
    ///   - text: 預期的計數文字 (目前頁/總數)
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前是否出現
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
    ///
    /// iPad 有側邊欄／清單／詳情多條導覽列，全域第一個 Button 會落在側邊欄而非檢視器返回鍵;
    /// 檢視器導覽列的標題是換頁計數 (全 App 唯一含 `/` 者)，先鎖定它再點其系統返回鍵
    func tapBack() {
        let viewerBar = app.navigationBars
            .matching(NSPredicate(format: "identifier CONTAINS '/'"))
            .firstMatch
        let back = viewerBar.buttons[BLAccessibilityID.Common.backButton]
        _ = back.waitForExistence(timeout: 5)
        back.tap()
    }
}
