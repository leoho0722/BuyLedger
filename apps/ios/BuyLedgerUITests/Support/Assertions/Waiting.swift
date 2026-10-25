//
//  Waiting.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Computed Properties

extension XCUIElement {

    /// 第一個相符元素的有效快照框線，尚未建立或框線不可用時為 `nil`
    ///
    /// - Note: 單次快照避免先查 `exists` 再讀 `frame` 之間，惰性列已被回收
    var snapshotFrame: CGRect? {
        let snapshot = try? firstMatch.snapshot() // 失敗可忽略，因為尚未建立的列可能暫時沒有快照
        guard let snapshot else {
            return nil
        }
        let frame = snapshot.frame
        guard !frame.isNull, !frame.isInfinite, !frame.isEmpty,
              frame.minX.isFinite, frame.minY.isFinite,
              frame.maxX.isFinite, frame.maxY.isFinite else {
            return nil
        }
        return frame
    }

    /// 元素是否已排版在畫面上且可點
    ///
    /// - Note: 尚未建立的 cell 其 `frame` 為無限大，直接讀 `isHittable` 會讓 XCTest 記錄失敗，故先排除
    /// - Note: 查詢對到多個元素時讀 `frame` 同樣會記錄失敗，所以以第一個相符元素判斷
    var isHittableOnScreen: Bool {
        let target = firstMatch
        guard target.exists else {
            return false
        }
        let frame = target.frame
        guard frame.origin.x.isFinite, frame.origin.y.isFinite, !frame.isEmpty else {
            return false
        }
        return target.isHittable
    }
}

// MARK: - Internal Method

extension XCUIElement {

    /// 等待元素從畫面消失
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

    /// 等待元素可點後點擊；逾時時直接附診斷失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待元素可點的秒數
    ///   - elementName: 失敗訊息中的元素描述
    ///     未提供時使用元素的 `accessibilityIdentifier`
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

    /// 等待元素可點；逾時時直接附診斷失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待元素可點的秒數
    ///   - elementName: 失敗訊息中的元素描述
    ///     未提供時使用元素的 `accessibilityIdentifier`
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
            app.failWithDiagnostics("找不到或無法點擊 \(description)", file: file, line: line)
            return false
        }
        return true
    }

    /// 等待元素連續兩次取得相同的有效框線且可點，避免點擊只停住尚未結束的捲動
    ///
    /// - Parameter timeout: 等待框線穩定且可點的秒數
    /// - Returns: 元素是否在逾時前連續兩次穩定且可點
    func waitUntilStableAndHittable(timeout: TimeInterval = 1) -> Bool {
        let target = firstMatch
        let deadline = Date.now.addingTimeInterval(timeout)
        var previous: CGRect?
        while true {
            if let current = target.snapshotFrame, target.isHittable {
                if current == previous {
                    return true
                }
                previous = current
            } else {
                previous = nil
            }
            guard Date.now < deadline else {
                return false
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
    }

    /// 等待元素出現且可點
    ///
    /// - Parameter timeout: 等待元素可點的秒數
    /// - Returns: 元素是否在逾時前可點
    func waitUntilHittable(timeout: TimeInterval = 10) -> Bool {
        // 不用 `isHittable` 述詞輪詢，避免元素還在畫面外時 XCTest 判斷可點性失敗
        let deadline = Date.now.addingTimeInterval(timeout)
        while !isHittableOnScreen {
            guard Date.now < deadline else {
                return false
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        }
        return true
    }
}
