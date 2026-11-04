//
//  XCUIApplication+NavigationBackInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

// MARK: - Internal Method

/// 導覽列原生 Back 按鈕的互動 helper
@MainActor
extension XCUIApplication {

    /// 查詢導覽列上唯一可見且可互動的原生 Back 按鈕並點擊
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 缺失或存在多個候選按鈕時丟出測試錯誤
    func tapUniqueNativeBackButton(file: StaticString = #filePath, line: UInt = #line) throws {
        let backButtons = navigationBars.buttons.matching(
            identifier: BLAccessibilityID.Common.backButton
        )
        let deadline = Date.now.addingTimeInterval(10)
        var hittableCandidates: [XCUIElement] = []
        while Date.now < deadline {
            hittableCandidates = backButtons.allElementsBoundByIndex.filter(\.isHittableOnScreen)
            if hittableCandidates.count == 1 {
                hittableCandidates[0].tap()
                return
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        }
        failWithDiagnostics(
            "原生 Back 按鈕候選數應為 1, 實際為 \(hittableCandidates.count)",
            file: file,
            line: line
        )
        throw NativeBackButtonError.candidateCountMismatch
    }
}

// MARK: - Nested Types

private extension XCUIApplication {

    /// 原生 Back 按鈕無法唯一定位時丟出的錯誤
    enum NativeBackButtonError: Error {

        /// 可互動的候選按鈕數不為 1
        case candidateCountMismatch
    }
}
