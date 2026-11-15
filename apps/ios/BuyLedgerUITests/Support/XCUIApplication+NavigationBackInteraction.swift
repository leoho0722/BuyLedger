//
//  XCUIApplication+NavigationBackInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

// MARK: - 導覽返回互動

/// 導覽列原生 Back 按鈕的互動 helper
@MainActor
extension XCUIApplication {

    /// 查詢導覽列上唯一可見且可互動的原生 Back 按鈕並點擊
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 缺失或存在多個候選按鈕時丟出測試錯誤
    func tapUniqueNativeBackButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let backButtons = navigationBars.buttons.matching(
            identifier: SystemAccessibilityID.backButton
        )
        var hittableCandidates: [XCUIElement] = []
        let hasUniqueCandidate = Polling.wait(timeout: 10, interval: 0.2) {
            hittableCandidates = backButtons.allElementsBoundByIndex.filter(\.isHittableOnScreen)
            return hittableCandidates.count == 1
        }
        guard hasUniqueCandidate else {
            try stopWithDiagnostics(
                "原生 Back 按鈕候選數應為 1, 實際為 \(hittableCandidates.count)",
                file: file,
                line: line
            )
        }
        hittableCandidates[0].tap()
    }

    /// 點擊含指定 identifier 元素的導覽列上的系統返回鍵
    ///
    /// - Parameters:
    ///   - identifier: 導覽列內作為定位錨點的元素 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 導覽列或返回鍵不存在、逾時仍不可點時丟出 `UITestError.stopped`
    func tapBackButton(
        inNavigationBarContaining identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let matchingNavigationBars = navigationBars.containing(.any, identifier: identifier)
        let hasUniqueNavigationBar = Polling.wait(timeout: 10) {
            matchingNavigationBars.count == 1
        }
        guard hasUniqueNavigationBar else {
            try stopWithDiagnostics(
                "含 identifier「\(identifier)」的導覽列數量應為 1，實際為 \(matchingNavigationBars.count)",
                file: file,
                line: line
            )
        }

        let navigationBar = matchingNavigationBars.firstMatch
        let backButton = navigationBar.buttons[SystemAccessibilityID.backButton].firstMatch
        guard backButton.waitUntilHittable(timeout: 10) else {
            try stopWithDiagnostics(
                "含 identifier「\(identifier)」的導覽列返回鍵不存在或不可點",
                file: file,
                line: line
            )
        }
        backButton.tap()
    }
}
