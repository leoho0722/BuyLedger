//
//  XCTestCase+HorizontalBounds.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

// MARK: - 框線查詢

@MainActor
extension XCTestCase {

    /// 等待容器存在後取得有限且非空的 frame，不要求可互動
    ///
    /// - Parameters:
    ///   - element: 要讀取範圍的容器
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已確認有限且非空的容器範圍
    /// - Throws: 容器不存在或範圍無效時丟出測試錯誤
    func requireValidFrame(
        of element: XCUIElement,
        in app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CGRect {
        let target = element.firstMatch
        try requireCondition(
            target.waitForExistence(timeout: 10),
            in: app,
            "找不到元素：\(context)",
            file: file,
            line: line
        )
        let frame = target.frame
        try requireCondition(
            frame.isUsableFrame,
            in: app,
            "元素 frame 無效：\(context)，frame = \(frame)",
            file: file,
            line: line
        )
        return frame
    }

    /// 等待元素可互動後取得有效的 frame
    ///
    /// - Parameters:
    ///   - element: 要讀取範圍的元素
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已確認可互動的元素範圍
    /// - Throws: 元素不存在、不可互動或範圍無效時丟出測試錯誤
    func requireHittableFrame(
        of element: XCUIElement,
        in app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CGRect {
        let target = element.firstMatch
        try requireCondition(
            target.waitUntilHittable(),
            in: app,
            "找不到元素或元素不可互動：\(context)",
            file: file,
            line: line
        )
        let frame = target.frame
        try requireCondition(
            frame.isUsableFrame,
            in: app,
            "元素 frame 無效：\(context)，frame = \(frame)",
            file: file,
            line: line
        )
        return frame
    }
}
