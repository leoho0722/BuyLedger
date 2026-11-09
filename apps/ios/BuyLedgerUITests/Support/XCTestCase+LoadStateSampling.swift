//
//  XCTestCase+LoadStateSampling.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

// MARK: - Nested Types

extension XCTestCase {

    /// 載入狀態穩定取樣的時間參數
    enum LoadStateSampling {

        /// 等待目標元素第一次出現的秒數
        static let firstAppearanceTimeout: TimeInterval = 10

        /// 第一次出現後的取樣次數，與 `interval` 合計約 3 秒
        static let sampleCount = 15

        /// 相鄰兩次取樣之間等待的秒數
        static let interval: TimeInterval = 0.2
    }
}

// MARK: - Load State Sampling

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
    /// - Returns: 第一次出現後的取樣是否全部符合
    /// - Note: 只等第一次出現無法抓到「失敗與載入中反覆互換」，取樣期間每次都以立即查詢確認，不等待
    @discardableResult
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
    ) -> Bool {
        let firstElement = app.descendants(matching: .any)[firstIdentifier]
        guard firstElement.waitForExistence(timeout: firstAppearanceTimeout) else {
            failWithDiagnostics(
                in: app,
                "\(context)：逾時，\(firstIdentifier) 在 \(firstAppearanceTimeout) 秒內未出現",
                file: file,
                line: line
            )
            return false
        }

        let requiredIdentifiers = [firstIdentifier] + presentIdentifiers
        for sampleIndex in 1...LoadStateSampling.sampleCount {
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: LoadStateSampling.interval)

            if let missing = requiredIdentifiers.first(where: {
                !app.descendants(matching: .any)[$0].exists
            }) {
                failWithDiagnostics(
                    in: app,
                    "\(context)：斷言失敗，第 \(sampleIndex) 次取樣時 \(missing) 不存在",
                    file: file,
                    line: line
                )
                return false
            }
            if let unexpected = absentIdentifiers.first(where: {
                app.descendants(matching: .any)[$0].exists
            }) {
                failWithDiagnostics(
                    in: app,
                    "\(context)：斷言失敗，第 \(sampleIndex) 次取樣時 \(unexpected) 出現",
                    file: file,
                    line: line
                )
                return false
            }
            if let unexpectedIndex = absentElements.firstIndex(where: \.exists) {
                failWithDiagnostics(
                    in: app,
                    "\(context)：斷言失敗，第 \(sampleIndex) 次取樣時 absentElements[\(unexpectedIndex)] 出現",
                    file: file,
                    line: line
                )
                return false
            }
        }
        return true
    }
}
