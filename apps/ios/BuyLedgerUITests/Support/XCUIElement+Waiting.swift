//
//  XCUIElement+Waiting.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 元素框線狀態

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
        guard frame.isUsableFrame else {
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
        guard frame.isUsableFrame else {
            return false
        }
        return target.isHittable
    }
}

// MARK: - 元素等待

extension XCUIElement {

    /// 等待元素從畫面消失
    ///
    /// - Parameter timeout: 等待元素消失的秒數
    /// - Returns: 元素是否在逾時前消失
    func waitForDisappearance(timeout: TimeInterval = 10) -> Bool {
        wait(for: NSPredicate(format: "exists == false"), timeout: timeout)
    }

    /// 以述詞輪詢自身到成立或逾時
    ///
    /// - Parameters:
    ///   - predicate: 要等待成立的述詞
    ///   - timeout: 等待述詞成立的秒數
    /// - Returns: 述詞是否在逾時前成立
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
    /// - Note: 可點後再等框線連續三次取樣相同 (至少 0.4 秒)，逾時仍不穩時照樣點擊
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func tapAfterWaiting(
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        elementName: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireHittable(
            in: app,
            timeout: timeout,
            elementName: elementName,
            file: file,
            line: line
        )
        // 表單 sheet 升起時會整個上移，可點後等框線連續穩定
        // 框線逾時仍照常點擊
        _ = waitUntilStableAndHittable(
            timeout: 2,
            sampleInterval: 0.2,
            requiredSamples: 3
        )
        tap()
    }

    /// 確認元素在逾時內可點，否則附診斷並停止目前測試
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待元素可點的秒數
    ///   - elementName: 失敗訊息中的元素描述
    ///     未提供時使用元素的 `accessibilityIdentifier`
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 元素逾時仍不可點時丟出測試錯誤
    func requireHittable(
        in app: XCUIApplication,
        timeout: TimeInterval,
        elementName: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        if !waitUntilHittable(timeout: timeout) {
            let identifier = self.identifier
            let fallback = identifier.isEmpty ? "未命名元素" : identifier
            let description = elementName ?? fallback
            try app.stopWithDiagnostics("找不到或無法點擊 \(description)", file: file, line: line)
        }
    }

    /// 等待元素連續取得相同的有效框線且可點，避免點擊只停住尚未結束的捲動
    ///
    /// - Parameters:
    ///   - timeout: 等待框線穩定且可點的秒數
    ///   - sampleInterval: 兩次取樣之間的間隔秒數
    ///   - requiredSamples: 需要連續相同的取樣次數，包含第一次
    /// - Returns: 元素是否在逾時前連續取得相同框線且可點
    func waitUntilStableAndHittable(
        timeout: TimeInterval = 1,
        sampleInterval: TimeInterval = 0.1,
        requiredSamples: Int = 2
    ) -> Bool {
        let target = firstMatch
        var previous: CGRect?
        var streak = 0
        return Polling.wait(timeout: timeout, interval: sampleInterval) {
            if let current = target.snapshotFrame, target.isHittable {
                streak = current == previous ? streak + 1 : 1
                previous = current
                if streak >= requiredSamples {
                    return true
                }
            } else {
                previous = nil
                streak = 0
            }
            return false
        }
    }

    /// 等待元素出現且可點
    ///
    /// - Parameter timeout: 等待元素可點的秒數
    /// - Returns: 元素是否在逾時前可點
    func waitUntilHittable(timeout: TimeInterval = 10) -> Bool {
        // 不用 `isHittable` 述詞輪詢，避免元素還在畫面外時 XCTest 判斷可點性失敗
        return Polling.wait(timeout: timeout) {
            isHittableOnScreen
        }
    }
}
