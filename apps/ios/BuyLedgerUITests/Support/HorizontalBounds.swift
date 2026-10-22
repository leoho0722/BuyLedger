//
//  HorizontalBounds.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

// MARK: - Internal Method

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
    /// - Throws: 容器不存在或範圍無效時拋出測試錯誤
    func requireValidFrame(
        of element: XCUIElement,
        in app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> CGRect {
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
            frame.origin.x.isFinite && frame.origin.y.isFinite
                && frame.width.isFinite && frame.height.isFinite && !frame.isEmpty,
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
    /// - Throws: 元素不存在、不可互動或範圍無效時拋出測試錯誤
    func requireHittableFrame(
        of element: XCUIElement,
        in app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> CGRect {
        let target = element.firstMatch
        try requireCondition(
            target.waitUntilHittable(),
            in: app,
            "找不到元素或元素不可互動：\(context)",
            file: file,
            line: line
        )
        return target.frame
    }

    /// 確認元素的左右緣都落在容器範圍內
    ///
    /// - Parameters:
    ///   - element: 要檢查的元素
    ///   - container: 提供水平範圍的容器
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    ///   - tolerance: 允許的點數誤差
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 元素無法取得或左右緣越界時拋出測試錯誤
    func assertHorizontalBounds(
        of element: XCUIElement,
        within container: XCUIElement,
        in app: XCUIApplication,
        context: String,
        tolerance: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let elementFrame = try requireHittableFrame(
            of: element,
            in: app,
            context: "\(context) 的待驗元素",
            file: file,
            line: line
        )
        let containerFrame = try requireHittableFrame(
            of: container,
            in: app,
            context: "\(context) 的範圍容器",
            file: file,
            line: line
        )
        try requireCondition(
            elementFrame.minX >= containerFrame.minX - tolerance
                && elementFrame.maxX <= containerFrame.maxX + tolerance,
            in: app,
            "位置越界：\(context)，元素 frame = \(elementFrame)，容器 frame = \(containerFrame)",
            file: file,
            line: line
        )
    }

    /// 確認可互動元素的左右緣都落在指定水平界線內
    ///
    /// - Parameters:
    ///   - element: 要檢查的可互動元素
    ///   - lowerBound: 水平範圍的左界
    ///   - upperBound: 水平範圍的右界
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    ///   - tolerance: 允許的點數誤差
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 元素無法取得或左右緣越界時拋出測試錯誤
    func assertHorizontalBounds(
        of element: XCUIElement,
        between lowerBound: CGFloat,
        and upperBound: CGFloat,
        in app: XCUIApplication,
        context: String,
        tolerance: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let elementFrame = try requireHittableFrame(
            of: element,
            in: app,
            context: "\(context) 的待驗元素",
            file: file,
            line: line
        )
        try requireCondition(
            elementFrame.minX >= lowerBound - tolerance
                && elementFrame.maxX <= upperBound + tolerance,
            in: app,
            "位置越界：\(context)，元素 frame = \(elementFrame)，水平範圍 = [\(lowerBound), \(upperBound)]",
            file: file,
            line: line
        )
    }

    /// 確認內容覆蓋左側元素右緣並延伸至視窗右緣
    ///
    /// - Parameters:
    ///   - content: 要檢查的內容容器
    ///   - leading: 內容左側的元素
    ///   - window: 提供右側邊界的視窗
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    ///   - tolerance: 允許的點數誤差
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 容器無法取得、左側出現空隙或右緣未貼齊時拋出測試錯誤
    func assertHorizontalFill(
        of content: XCUIElement,
        after leading: XCUIElement,
        to window: XCUIElement,
        in app: XCUIApplication,
        context: String,
        tolerance: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let contentFrame = try requireValidFrame(
            of: content,
            in: app,
            context: "\(context) 的內容容器",
            file: file,
            line: line
        )
        let leadingFrame = try requireValidFrame(
            of: leading,
            in: app,
            context: "\(context) 的左側元素",
            file: file,
            line: line
        )
        let windowFrame = try requireValidFrame(
            of: window,
            in: app,
            context: "\(context) 的視窗",
            file: file,
            line: line
        )
        try requireCondition(
            contentFrame.minX <= leadingFrame.maxX + tolerance
                && abs(contentFrame.maxX - windowFrame.maxX) <= tolerance,
            in: app,
            """
            位置越界：\(context)
            內容 frame = \(contentFrame)，左側 frame = \(leadingFrame)，視窗 frame = \(windowFrame)
            """,
            file: file,
            line: line
        )
    }
}
