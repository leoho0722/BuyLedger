//
//  Waiting.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

extension XCUIElement {

    /// 等元素出現且可點
    ///
    /// - Parameter timeout: 等待元素可點的秒數
    /// - Returns: 元素是否在逾時前可點
    func waitUntilHittable(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == true AND isHittable == true"), timeout: timeout)
    }

    /// 等元素從畫面消失
    ///
    /// - Parameter timeout: 等待元素消失的秒數
    /// - Returns: 元素是否在逾時前消失
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == false"), timeout: timeout)
    }

    /// 以述詞輪詢自身到成立或逾時
    ///
    /// - Parameters:
    ///   - predicate: 要等待成立的述詞
    ///   - timeout: 等待述詞成立的秒數
    /// - Returns: 述詞是否在逾時前成立
    @discardableResult
    func wait(for predicate: NSPredicate, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// 等待元素可點；逾時時直接附診斷失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待元素可點的秒數
    ///   - elementName: 失敗訊息中的元素描述
    ///     未提供時使用 accessibility identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 元素是否已可點
    func waitUntilHittableOrFail(
        in app: XCUIApplication,
        timeout: TimeInterval,
        elementName: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        if !waitUntilHittable(timeout: timeout) {
            let identifier = self.identifier
            let fallback = identifier.isEmpty ? "未命名元素" : identifier
            let description = elementName ?? fallback
            app.failWithDiagnostics(
                "找不到或無法點擊 \(description)",
                file: file,
                line: line
            )
            return false
        }
        return true
    }

    /// 等待元素可點後點擊；逾時時直接附診斷失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待元素可點的秒數
    ///   - elementName: 失敗訊息中的元素描述
    ///     未提供時使用 accessibility identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAfterWaiting(
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        elementName: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard waitUntilHittableOrFail(
            in: app,
            timeout: timeout,
            elementName: elementName,
            file: file,
            line: line
        ) else {
            return
        }
        tap()
    }
}
