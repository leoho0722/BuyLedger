//
//  XCUIApplication+NavigationBarTitle.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import Foundation
import XCTest

// MARK: - 導覽列標題讀取

/// 依目前畫面顯示的標題查詢系統導覽列
@MainActor
extension XCUIApplication {

    /// 判斷任一導覽列中是否有指定標題可見
    ///
    /// - Parameter title: 要比對的標題文字
    /// - Returns: 導覽列內有 label 完全相符且可互動的 staticText 時為 `true`
    func isNavigationBarTitleVisible(_ title: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", title)
        return navigationBars.descendants(matching: .staticText)
            .matching(predicate)
            .allElementsBoundByIndex.contains(where: \.isHittableOnScreen)
    }

    /// 計算 App 中 label 完全相符的 staticText 數量
    ///
    /// - Parameter text: 要比對的完整文字
    /// - Returns: label 與文字相同的 staticText 數量
    func staticTextCount(_ text: String) -> Int {
        let predicate = NSPredicate(format: "label == %@", text)
        return descendants(matching: .staticText).matching(predicate).count
    }

    /// 計算所有導覽列中 label 完全相符的 staticText 數量
    ///
    /// - Parameter text: 要比對的完整文字
    /// - Returns: 導覽列內 label 與文字相同的 staticText 數量
    func navigationBarTextCount(_ text: String) -> Int {
        let predicate = NSPredicate(format: "label == %@", text)
        return navigationBars.descendants(matching: .staticText).matching(predicate).count
    }

    /// 等待顯示指定標題的導覽列出現
    ///
    /// - Parameters:
    ///   - title: 導覽列顯示的標題
    ///   - timeout: 等待導覽列出現的秒數
    /// - Returns: 導覽列是否在逾時前出現
    func waitForNavigationBarTitle(_ title: String, timeout: TimeInterval = 10) -> Bool {
        Polling.wait(timeout: timeout) {
            navigationBar(containingTitle: title).exists
        }
    }

    /// 取得含指定標題的導覽列查詢
    ///
    /// - Parameter title: 導覽列顯示的標題
    /// - Returns: 含該標題的導覽列；找不到時為不存在的導覽列查詢
    func navigationBar(containingTitle title: String) -> XCUIElement {
        let titlePredicate = NSPredicate(format: "label == %@", title)
        for navigationBar in navigationBars.allElementsBoundByIndex {
            if navigationBar.identifier == title
                || navigationBar.label == title
                || navigationBar.staticTexts.matching(titlePredicate).firstMatch.exists {
                return navigationBar
            }
        }
        let barPredicate = NSPredicate(format: "identifier == %@ OR label == %@", title, title)
        return navigationBars.matching(barPredicate).firstMatch
    }

    /// 取得導覽列上可見的標題文字
    ///
    /// - Parameter navigationBar: 要讀取的導覽列
    /// - Returns: 導覽列 identifier 對應的標題可見時回傳該文字，否則回傳 `nil`
    func visibleNavigationBarTitle(of navigationBar: XCUIElement) -> String? {
        let title = navigationBar.identifier
        guard !title.isEmpty, navigationBar.staticTexts[title].isHittableOnScreen else {
            return nil
        }
        return title
    }
}
