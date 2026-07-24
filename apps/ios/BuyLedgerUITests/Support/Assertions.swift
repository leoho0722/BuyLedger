//
//  Assertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest
import CoreGraphics

// MARK: - Internal Method

/// 跨畫面共用的語意斷言
///
/// 一律以 accessibility identifier 定位；失敗時以 `failWithDiagnostics` 附上截圖與可及性樹，
/// 讓斷言在測試檔裡讀起來是語意，而非查詢細節
extension XCTestCase {

    /// 確認已停在指定畫面
    ///
    /// 導覽列本身不掛 identifier (見專案決議)，改以畫面根容器就緒判定；
    /// 命名沿用「導覽標題」的語意，實作等的是該畫面根 identifier 出現
    /// - Parameters:
    ///   - screen: 目標畫面的 Page Object
    ///   - timeout: 逾時秒數
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    func assertNavigationTitle(
        for screen: Screen,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !screen.waitUntilReady(timeout: timeout) {
            failWithDiagnostics(
                in: screen.app,
                "畫面未就緒，根 identifier「\(screen.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
    }

    /// 確認空狀態容器存在
    /// - Parameters:
    ///   - identifier: 空狀態容器的 identifier
    ///   - app: 受測 App
    ///   - timeout: 逾時秒數
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    func assertEmptyState(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let container = app.descendants(matching: .any)[identifier]
        if !container.waitForExistence(timeout: timeout) {
            failWithDiagnostics(
                in: app,
                "空狀態容器「\(identifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
    }

    /// 確認元素命中區至少 44x44 point
    ///
    /// Apple HIG 的最小可點尺寸；量的是元素 frame 而非視覺尺寸，命中區靠 `contentShape` 撐開時才驗得準
    /// - Parameters:
    ///   - element: 待驗元素
    ///   - minimum: 最小邊長 (point)，預設 44
    ///   - app: 受測 App，供失敗診斷附件使用
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    func assertMinimumHitTarget(
        _ element: XCUIElement,
        minimum: CGFloat = 44,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard element.exists else {
            failWithDiagnostics(in: app, "待驗命中區的元素不存在", file: file, line: line)
            return
        }
        let frame = element.frame
        if frame.width < minimum || frame.height < minimum {
            failWithDiagnostics(
                in: app,
                "命中區 \(frame.width)x\(frame.height) 小於最小值 \(minimum)x\(minimum) point",
                file: file,
                line: line
            )
        }
    }

    /// 確認進度列的標題與尾值成對出現
    ///
    /// 進度列以前導標題搭配尾端數值呈現，缺一即視為版面缺漏；
    /// 兩個 identifier 由呼叫端提供，只驗兩者同時存在、不讀顯示文字
    /// - Parameters:
    ///   - titleIdentifier: 標題元素的 identifier
    ///   - valueIdentifier: 尾值元素的 identifier
    ///   - app: 受測 App
    ///   - timeout: 逾時秒數
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    func assertProgressPairing(
        titleIdentifier: String,
        valueIdentifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let title = app.descendants(matching: .any)[titleIdentifier]
        let value = app.descendants(matching: .any)[valueIdentifier]
        if !title.waitForExistence(timeout: timeout) {
            failWithDiagnostics(
                in: app,
                "進度列標題「\(titleIdentifier)」未出現，與尾值未成對",
                file: file,
                line: line
            )
        }
        if !value.waitForExistence(timeout: timeout) {
            failWithDiagnostics(
                in: app,
                "進度列尾值「\(valueIdentifier)」未出現，與標題未成對",
                file: file,
                line: line
            )
        }
    }
}
