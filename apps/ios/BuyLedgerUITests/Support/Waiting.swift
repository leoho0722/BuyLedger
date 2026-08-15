//
//  Waiting.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 等待條件成立或逾時

// MARK: - Internal Method

extension XCUIElement {

    /// 等元素出現且可點
    /// - Parameter timeout: 等待元素可點的秒數
    /// - Returns: 元素是否在逾時前可點
    @discardableResult
    func waitUntilHittable(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == true AND isHittable == true"), timeout: timeout)
    }

    /// 等元素從畫面消失
    /// - Parameter timeout: 等待元素消失的秒數
    /// - Returns: 元素是否在逾時前消失
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == false"), timeout: timeout)
    }

    /// 以述詞輪詢自身到成立或逾時
    /// - Parameters:
    ///   - predicate: 要等待成立的述詞
    ///   - timeout: 等待述詞成立的秒數
    /// - Returns: 述詞是否在逾時前成立
    @discardableResult
    func wait(for predicate: NSPredicate, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
