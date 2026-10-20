//
//  OrdersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單清單頁的 Page Object
struct OrdersScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Nested Types

private extension OrdersScreen {

    /// 必要互動元素無法取得時的測試錯誤
    enum InteractionError: Error {

        /// 畫面缺少必要元素或元素尚未能互動
        case elementUnavailable
    }
}

// MARK: - Computed Properties

extension OrdersScreen {

    /// 判定訂單清單已就緒的根 identifier (清單捲動容器)
    ///
    /// - Returns: 訂單清單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.listRoot
    }

    /// 是否正顯示沒有符合條件訂單的空狀態
    ///
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listEmptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension OrdersScreen {

    /// 取得目前畫面上可互動的訂單搜尋欄
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 目前可互動的系統搜尋欄
    /// - Throws: 找不到可互動搜尋欄時拋出測試錯誤
    func hittableSearchField(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> XCUIElement {
        let deadline = Date.now.addingTimeInterval(10)
        repeat {
            if let field = app.searchFields.allElementsBoundByIndex.first(
                where: \.isHittableOnScreen
            ) {
                return field
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        } while Date.now < deadline
        app.failWithDiagnostics("找不到元素：可互動的訂單搜尋欄", file: file, line: line)
        throw InteractionError.elementUnavailable
    }

    /// 從清單更多選單進入多選並等到完成鈕可互動
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要選單或完成鈕無法互動時拋出測試錯誤
    func enterSelectionMode(file: StaticString = #filePath, line: UInt = #line) throws {
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton].firstMatch
        guard menu.waitUntilHittableOrFail(
            in: app,
            timeout: 10,
            elementName: "訂單清單更多選單",
            file: file,
            line: line
        ) else {
            throw InteractionError.elementUnavailable
        }
        menu.tap()
        guard app.tapMenuItem(
            BLAccessibilityID.Orders.selectionModeButton,
            file: file,
            line: line
        ) else {
            throw InteractionError.elementUnavailable
        }
        let done = app.buttons[BLAccessibilityID.Orders.selectionDoneButton].firstMatch
        guard done.waitUntilHittableOrFail(
            in: app,
            timeout: 10,
            elementName: "訂單多選完成鈕",
            file: file,
            line: line
        ) else {
            throw InteractionError.elementUnavailable
        }
    }

    /// 點工具列的新增訂單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAddOrder(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.addButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 選取指定狀態瀏覽膠囊
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選的 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectStatusChip(filterID: String, file: StaticString = #filePath, line: UInt = #line) {
        let chip = app.buttons[BLAccessibilityID.Orders.statusChip(filterID)]
        chip.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 在系統搜尋欄輸入關鍵字
    ///
    /// - Parameters:
    ///   - text: 要輸入的搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func search(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.searchFields.firstMatch
        field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 取指定訂單編號的清單列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的訂單列元素
    func orderRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.row(orderID: orderID)]
    }

    /// 點指定訂單編號的清單列進入詳情
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapOrder(orderID: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = orderRow(orderID: orderID)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 清單是否含指定訂單編號的列
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - timeout: 等待訂單列出現的秒數
    /// - Returns: 訂單列是否在逾時前出現
    func hasOrder(orderID: String, timeout: TimeInterval = 5) -> Bool {
        orderRow(orderID: orderID).waitForExistence(timeout: timeout)
    }

    /// 開啟整合篩選 sheet (compact 版面工具列入口)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openFilterSheet(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.filterButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的 AI 商品明細總結入口
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到 AI 商品明細總結項目
    @discardableResult
    func tapAiSummary(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        // AI 總結是「更多操作」選單內的項目，先開選單再點該項
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton]
        menu.tapAfterWaiting(in: app, file: file, line: line)
        return app.tapMenuItem(BLAccessibilityID.Orders.aiSummaryButton, file: file, line: line)
    }
}
