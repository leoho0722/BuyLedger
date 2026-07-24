//
//  Waiting.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 條件式等待，取代固定 sleep
///
/// UI 狀態轉換的時間不固定，睡死一段時間不是太早就是太慢；這些 helper 以 `XCTWaiter` 輪詢條件到成立或逾時

// MARK: - Internal Method

extension XCUIElement {

    /// 等元素出現且可點
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否達成
    @discardableResult
    func waitUntilHittable(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == true AND isHittable == true"), timeout: timeout)
    }

    /// 等元素從畫面消失
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否消失
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == false"), timeout: timeout)
    }

    /// 以述詞輪詢自身到成立或逾時
    /// - Parameters:
    ///   - predicate: 對元素求值的述詞
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前述詞是否成立
    @discardableResult
    func wait(for predicate: NSPredicate, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
