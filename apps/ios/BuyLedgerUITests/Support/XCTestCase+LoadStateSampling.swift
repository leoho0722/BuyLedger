//
//  XCTestCase+LoadStateSampling.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

// MARK: - 載入狀態取樣參數

extension XCTestCase {

    /// 載入狀態穩定取樣的時間參數
    private enum LoadStateSampling {

        /// 等待目標元素第一次出現的秒數
        static let firstAppearanceTimeout: TimeInterval = 10

        /// 第一次出現後的取樣次數，與 `interval` 合計約 3 秒
        static let sampleCount = 15

        /// 相鄰兩次取樣之間等待的秒數
        static let interval: TimeInterval = 0.2
    }
}

// MARK: - 載入狀態穩定判定

@MainActor
extension XCTestCase {

    /// 等指定元素第一次出現後持續取樣，確認畫面穩定停在同一個載入狀態
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - firstIdentifier: 先等待第一次出現的元素 identifier
    ///   - presentIdentifiers: 每次取樣都必須存在的元素 identifier (含 `firstIdentifier` 以外的重試鍵等)
    ///   - absentIdentifiers: 每次取樣都不得存在的元素 identifier (如載入中指示器、空狀態)
    ///   - absentElements: 每次取樣都不得存在、沒有 identifier 的元素 (如 scoped `progressIndicators`)
    ///   - context: 失敗訊息開頭描述的畫面
    ///   - firstAppearanceTimeout: 等待第一次出現的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 目標未出現或取樣期間狀態不符時丟出測試錯誤
    /// - Note: 只等第一次出現無法抓到「失敗與載入中反覆互換」，取樣期間每次都以立即查詢確認，不等待
    func assertLoadStateStaysStable(
        in app: XCUIApplication,
        waitingFor firstIdentifier: String,
        present presentIdentifiers: [String],
        absent absentIdentifiers: [String],
        absentElements: [XCUIElement] = [],
        context: String,
        firstAppearanceTimeout: TimeInterval = LoadStateSampling.firstAppearanceTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let firstElement = app.descendants(matching: .any)[firstIdentifier]
        guard firstElement.waitForExistence(timeout: firstAppearanceTimeout) else {
            try app.stopWithDiagnostics(
                "\(context)：逾時，\(firstIdentifier) 在 \(firstAppearanceTimeout) 秒內未出現",
                file: file,
                line: line
            )
        }

        let requiredIdentifiers = [firstIdentifier] + presentIdentifiers
        for sampleIndex in 1...LoadStateSampling.sampleCount {
            // 確保每次狀態取樣彼此分隔，避免只驗到瞬間畫面
            Polling.pause(for: LoadStateSampling.interval)

            if let missing = requiredIdentifiers.first(where: {
                !app.descendants(matching: .any)[$0].exists
            }) {
                try app.stopWithDiagnostics(
                    "\(context)：斷言失敗，第 \(sampleIndex) 次取樣時 \(missing) 不存在",
                    file: file,
                    line: line
                )
            }
            if let unexpected = absentIdentifiers.first(where: {
                app.descendants(matching: .any)[$0].exists
            }) {
                try app.stopWithDiagnostics(
                    "\(context)：斷言失敗，第 \(sampleIndex) 次取樣時 \(unexpected) 出現",
                    file: file,
                    line: line
                )
            }
            if let unexpectedIndex = absentElements.firstIndex(where: \.exists) {
                try app.stopWithDiagnostics(
                    "\(context)：斷言失敗，第 \(sampleIndex) 次取樣時 absentElements[\(unexpectedIndex)] 出現",
                    file: file,
                    line: line
                )
            }
        }
    }
}
