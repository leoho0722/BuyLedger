//
//  OrdersRegularColumnScopeUITestSupport.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import CoreGraphics
import XCTest

/// regular 訂單清單與詳情欄測試共用的範圍斷言
@MainActor
enum OrdersRegularColumnScopeUITestSupport {

    /// 版面不符時略過測試的原因與 compact 對應測試
    static let layoutScopeReason = """
    欄位歸屬只適用 regular 版面；compact 清單由 OrdersUITests 覆蓋
    compact 詳情由 OrderDetailUITests 與 OrderDetailMoreMenuUITests 覆蓋
    """

    /// 確認元素的左右緣都落在容器範圍內
    ///
    /// - Parameters:
    ///   - element: 要檢查的元素
    ///   - container: 提供水平範圍的容器
    ///   - app: 受測 App
    ///   - testCase: 目前的 UI 測試案例
    ///   - context: 失敗訊息中的檢查情境
    ///   - tolerance: 允許的點數誤差
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 元素無法取得或左右緣越界時丟出測試錯誤
    static func assertHorizontalBounds(
        of element: XCUIElement,
        within container: XCUIElement,
        in app: XCUIApplication,
        testCase: XCTestCase,
        context: String,
        tolerance: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let elementFrame = try testCase.requireHittableFrame(
            of: element,
            in: app,
            context: "\(context) 的待驗元素",
            file: file,
            line: line
        )
        let containerFrame = try testCase.requireHittableFrame(
            of: container,
            in: app,
            context: "\(context) 的範圍容器",
            file: file,
            line: line
        )
        try testCase.requireCondition(
            elementFrame.minX >= containerFrame.minX - tolerance
                && elementFrame.maxX <= containerFrame.maxX + tolerance,
            in: app,
            "位置越界：\(context)，元素 frame = \(elementFrame)，"
                + "容器 frame = \(containerFrame)",
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
    ///   - testCase: 目前的 UI 測試案例
    ///   - context: 失敗訊息中的檢查情境
    ///   - tolerance: 允許的點數誤差
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 元素無法取得或左右緣越界時丟出測試錯誤
    static func assertHorizontalBounds(
        of element: XCUIElement,
        between lowerBound: CGFloat,
        and upperBound: CGFloat,
        in app: XCUIApplication,
        testCase: XCTestCase,
        context: String,
        tolerance: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let elementFrame = try testCase.requireHittableFrame(
            of: element,
            in: app,
            context: "\(context) 的待驗元素",
            file: file,
            line: line
        )
        try testCase.requireCondition(
            elementFrame.minX >= lowerBound - tolerance
                && elementFrame.maxX <= upperBound + tolerance,
            in: app,
            "位置越界：\(context)，元素 frame = \(elementFrame)，"
                + "水平範圍 = [\(lowerBound), \(upperBound)]",
            file: file,
            line: line
        )
    }

    /// 確認清單有自己的導覽列，搜尋、筆數與一般操作都位於清單欄內
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - testCase: 目前的 UI 測試案例
    ///   - context: 方向或分頁切換階段
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要元素缺少或任一控制項越界時丟出測試錯誤
    static func assertListControls(
        _ orders: OrdersScreen,
        in app: XCUIApplication,
        testCase: XCTestCase,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let bounds = try listColumnBounds(
            in: app,
            orders: orders,
            testCase: testCase,
            context: context,
            file: file,
            line: line
        )
        let controls: [(XCUIElement, String)] = [
            (try app.hittableSearchField(), "搜尋欄"),
            (orders.orderCountLabel, "筆數"),
            (orders.addButton, "新增訂單"),
            (orders.batchMenuButton, "清單更多選單"),
        ]
        for (element, name) in controls {
            try assertHorizontalBounds(
                of: element,
                between: bounds.lowerBound,
                and: bounds.upperBound,
                in: app,
                testCase: testCase,
                context: "\(context)，\(name)",
                file: file,
                line: line
            )
        }
        let hasListNavigationBar = app.navigationBars.allElementsBoundByIndex
            .filter(\.isHittableOnScreen)
            .contains {
                $0.frame.minX >= bounds.lowerBound - 1
                    && $0.frame.maxX <= bounds.upperBound + 1
            }
        try testCase.requireCondition(
            hasListNavigationBar,
            in: app,
            "位置越界：清單欄沒有自己的導覽列",
            file: file,
            line: line
        )
    }

    /// 依方向及實際欄位邊界取得清單欄的水平範圍
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - orders: 訂單清單的 Page Object
    ///   - testCase: 目前的 UI 測試案例
    ///   - context: 方向或分頁切換階段
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 清單欄的左右界
    /// - Throws: 側邊欄欄界或清單根容器無法取得時丟出測試錯誤
    static func listColumnBounds(
        in app: XCUIApplication,
        orders: OrdersScreen,
        testCase: XCTestCase,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> (lowerBound: CGFloat, upperBound: CGFloat) {
        let windowFrame = try testCase.requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "\(context)，視窗左界",
            file: file,
            line: line
        )
        let sidebarNavigationBar = app.navigationBars
            .containing(.button, identifier: SystemAccessibilityID.sidebarToggleButton)
            .firstMatch
        var sidebarFrame: CGRect?
        if sidebarNavigationBar.exists {
            sidebarFrame = try testCase.requireValidFrame(
                of: sidebarNavigationBar,
                in: app,
                context: "\(context)，原生側邊欄導覽列",
                file: file,
                line: line
            )
        }
        let listFrame = try testCase.requireValidFrame(
            of: orders.rootElement,
            in: app,
            context: "\(context)，訂單清單根容器",
            file: file,
            line: line
        )
        let lowerBound: CGFloat
        if windowFrame.width > windowFrame.height {
            lowerBound = try testCase.requireValue(
                sidebarFrame?.maxX,
                in: app,
                "橫向找不到原生側邊欄欄位邊界",
                file: file,
                line: line
            )
        } else {
            lowerBound = sidebarFrame?.maxX ?? windowFrame.minX
        }
        try testCase.requireCondition(
            lowerBound < listFrame.maxX,
            in: app,
            "清單欄水平範圍無效：左界 \(lowerBound)，清單根容器 \(listFrame)",
            file: file,
            line: line
        )
        return (lowerBound, listFrame.maxX)
    }
}
