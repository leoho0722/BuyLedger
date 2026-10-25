//
//  CampaignDetailScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情頁的 Page Object
struct CampaignDetailScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension CampaignDetailScreen {

    /// 等待已結團狀態膠囊出現
    ///
    /// - Parameter timeout: 等待狀態膠囊出現的秒數
    /// - Returns: 狀態膠囊是否在逾時前出現
    func hasSettledBadge(timeout: TimeInterval = 2) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.detailSettledBadge]
            .waitForExistence(timeout: timeout)
    }

    /// 沿用結算數值列的讀法取得已收金額
    ///
    /// - Returns: 已收金額的 accessibility value；數值列不存在時為 `nil`
    func receivedAmount() -> String? {
        summaryValue(.received)
    }

    /// 讀取指定結團結算數值列的 accessibility value
    ///
    /// - Parameter kind: 要讀取的結算數值種類
    /// - Returns: 該列的 accessibility value；元素不存在時為 `nil`
    func summaryValue(_ kind: BLAccessibilityID.Campaigns.DetailSummary) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Campaigns.detailSummary(kind)
        ]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 將已收數值列捲回畫面，等待收款操作更新金額
    ///
    /// - Parameters:
    ///   - amount: 預期的已收金額顯示值
    ///   - timeout: 等待數值更新的秒數
    /// - Returns: 已收金額是否在逾時前符合預期
    func waitForReceivedAmount(_ amount: String, timeout: TimeInterval = 10) -> Bool {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Campaigns.detailSummary(.received)
        ]
        guard revealElement(element, isSwipingUp: false) else {
            return false
        }
        return element.wait(for: NSPredicate(format: "value == %@", amount), timeout: timeout)
    }

    /// 捲到指定客戶的分貨列，確認該列存在且可互動
    ///
    /// - Parameter customerName: 要尋找的客戶名稱
    /// - Returns: 是否找到該客戶的可互動分貨列
    func hasDistributionRow(customerName: String) -> Bool {
        revealElement(distributionRow(customerName: customerName), isSwipingUp: true)
    }

    /// 將客戶分貨列捲往畫面中段，點整列中央並等待指定訂單的收款鍵
    ///
    /// - Parameters:
    ///   - customerName: 要展開的客戶名稱
    ///   - orderID: 該客戶所屬訂單的識別值，供確認分貨列已展開
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 指定訂單的收款鍵是否在展開後出現
    @discardableResult
    func expandDistributionRow(
        customerName: String,
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let row = distributionRow(customerName: customerName)
        if !revealElementInMiddle(row, isSwipingUp: true) {
            app.failWithDiagnostics("找不到客戶「\(customerName)」的可展開分貨列", file: file, line: line)
            return false
        }
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let receipt = app.buttons[BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: orderID)]
        // 展開後的新訂單列也可能尚未建立，必要時先捲入可及性樹
        if !receipt.waitForExistence(timeout: 2) && !revealElement(receipt, isSwipingUp: true) {
            app.failWithDiagnostics(
                "展開客戶「\(customerName)」後找不到訂單「\(orderID)」的收款鍵",
                file: file,
                line: line
            )
            return false
        }
        return receipt.waitForExistence(timeout: 10)
    }

    /// 依客戶名稱取得可展開的分貨列
    ///
    /// - Parameter customerName: 要展開的客戶名稱
    /// - Returns: 對應客戶的分貨列標題
    func distributionRow(customerName: String) -> XCUIElement {
        app.buttons[BLAccessibilityID.Campaigns.detailDistributionRow(customerName: customerName)]
    }

    /// 將指定訂單的收款鍵捲往畫面中段，切換已收款與未收款
    ///
    /// - Parameters:
    ///   - orderID: 已展開分貨列中的訂單識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapReceiptToggle(orderID: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: orderID)]
        if !revealElementInMiddle(button, isSwipingUp: true) {
            app.failWithDiagnostics("找不到訂單「\(orderID)」的收款鍵", file: file, line: line)
            return
        }
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 將只看未收款捲到可互動的位置，再點內層原生開關
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func toggleUnpaidOnly(file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        if !revealElement(toggle, isSwipingUp: false) {
            app.failWithDiagnostics("找不到只看未收款開關", file: file, line: line)
            return
        }
        let control = toggle.switches.firstMatch
        if !revealElement(control, isSwipingUp: false) {
            app.failWithDiagnostics("找不到只看未收款的內層開關", file: file, line: line)
            return
        }
        control.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待只看未收款開關變成開啟
    ///
    /// - Parameter timeout: 等待開關值更新的秒數
    /// - Returns: 開關是否在逾時前變成開啟狀態
    func waitForUnpaidOnlyEnabled(timeout: TimeInterval = 10) -> Bool {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        guard revealElement(toggle, isSwipingUp: false) else {
            return false
        }
        return toggle.wait(for: NSPredicate(format: "value == %@", "1"), timeout: timeout)
    }

    /// 讀取只看未收款開關的目前值
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 開關是否開啟；找不到開關時附診斷並回傳 `false`
    func isUnpaidOnlyEnabled(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        if !revealElement(toggle, isSwipingUp: false) {
            app.failWithDiagnostics("找不到只看未收款開關，無法讀取開關值", file: file, line: line)
            return false
        }
        return toggle.value as? String == "1"
    }

    /// 開啟「更多」操作選單 (編輯／結團／刪除)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openMoreMenu(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailMoreButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點更多選單的編輯開團
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapEdit(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailEditButton, file: file, line: line)
    }

    /// 點更多選單的結團結算 (不可逆)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapSettle(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailSettleButton, file: file, line: line)
    }

    /// 點更多選單的刪除開團 (破壞性)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapDelete(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailDeleteButton, file: file, line: line)
    }

    /// 等待結團確認 alert 呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func isSettleConfirmationPresented(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點結團確認 alert 的結團按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func confirmSettle(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "結團", file: file, line: line)
    }

    /// 點結團確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func cancelSettle(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "取消", file: file, line: line)
    }

    /// 等待刪除確認 alert 呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func isDeleteConfirmationPresented(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點刪除確認 alert 的破壞性刪除按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func confirmDelete(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "刪除", file: file, line: line)
    }

    /// 點刪除確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func cancelDelete(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "取消", file: file, line: line)
    }

    /// 等待 alert 消失
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    @discardableResult
    func isConfirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }

    /// 從詳情的導覽列返回開團列表，避免點到 iPad 側邊欄的返回鍵
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapBack(file: StaticString = #filePath, line: UInt = #line) {
        let detailBar = app.navigationBars
            .containing(.button, identifier: BLAccessibilityID.Campaigns.detailMoreButton)
            .firstMatch
        let back = detailBar.buttons[BLAccessibilityID.Common.backButton]
        back.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension CampaignDetailScreen: Screen {

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.detailRoot
    }
}

// MARK: - Private Method

@MainActor
private extension CampaignDetailScreen {

    /// 小幅捲動詳情直到目標穩定且可互動，內容不再移動時改向尋找
    ///
    /// - Parameters:
    ///   - element: 要捲進畫面的詳情元素
    ///   - isSwipingUp: 是否先向上滑動以尋找畫面下方的元素
    /// - Returns: 是否找到穩定且可互動的元素
    func revealElement(_ element: XCUIElement, isSwipingUp: Bool) -> Bool {
        let container = rootElement
        guard container.waitForExistence(timeout: 10) else {
            return false
        }
        // 收款與篩選後可能保留不同捲動位置，第一個方向到盡頭時再往回找
        for shouldSwipeUp in [isSwipingUp, !isSwipingUp] {
            let startY: CGFloat = shouldSwipeUp ? 0.7 : 0.3
            let endY: CGFloat = 0.5
            var previous = app.scrollPositionSignature(in: container)
            for _ in 0..<12 {
                if element.exists {
                    if app.scrollToHittableGently(
                        element,
                        within: container,
                        maxDrags: 1,
                        startY: startY,
                        endY: endY
                    ), element.waitUntilStableAndHittable(timeout: 1) {
                        return true
                    }
                } else {
                    // 未建立的清單列只查 `exists`，避免查詢無效的外框
                    let start = container.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: startY)
                    )
                    let end = container.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: endY)
                    )
                    start.press(forDuration: 0.1, thenDragTo: end)
                }
                let current = app.scrollPositionSignature(in: container)
                if let current, current == previous {
                    break
                }
                previous = current
            }
        }
        return element.waitUntilStableAndHittable(timeout: 1)
    }

    /// 將目標捲往可見內容中段，確認完整外框避開導覽列與浮動分頁列
    ///
    /// - Parameters:
    ///   - element: 要安全點擊的分貨列或收款鍵
    ///   - isSwipingUp: 是否先向上滑動以尋找畫面下方的元素
    /// - Returns: 目標是否完整露出且可互動
    func revealElementInMiddle(_ element: XCUIElement, isSwipingUp: Bool) -> Bool {
        guard revealElement(element, isSwipingUp: isSwipingUp) else {
            return false
        }
        let container = rootElement
        for _ in 0..<6 {
            guard let frame = element.snapshotFrame else {
                return false
            }
            let visibleFrame = visibleContentFrame()
            let safeFrame = visibleFrame.insetBy(dx: 0, dy: 16)
            if abs(frame.midY - visibleFrame.midY) <= visibleFrame.height * 0.15,
               safeFrame.contains(frame),
               element.waitUntilStableAndHittable(timeout: 1) {
                return true
            }
            let isDraggingUp = frame.midY > visibleFrame.midY
            let start = container.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: isDraggingUp ? 0.65 : 0.35)
            )
            let end = container.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: isDraggingUp ? 0.45 : 0.55)
            )
            start.press(forDuration: 0.1, thenDragTo: end)
            if let current = element.snapshotFrame, abs(current.midY - frame.midY) < 1 {
                break
            }
        }
        // 清單底端可能無法再移到正中央，仍須完整避開浮動分頁列才可點擊
        guard let frame = element.snapshotFrame else {
            return false
        }
        return visibleContentFrame().insetBy(dx: 0, dy: 16).contains(frame)
            && element.waitUntilStableAndHittable(timeout: 1)
    }

    /// 取得詳情容器中未被導覽列與底部分頁列覆蓋的範圍
    ///
    /// - Returns: 可以安全定位分貨列與收款鍵的可見內容範圍
    func visibleContentFrame() -> CGRect {
        guard let rootFrame = rootElement.snapshotFrame, let appFrame = app.snapshotFrame else {
            return .zero
        }
        var frame = rootFrame.intersection(appFrame)
        let detailBar = app.navigationBars
            .containing(.button, identifier: BLAccessibilityID.Campaigns.detailMoreButton)
            .firstMatch
        if let detailBarFrame = detailBar.snapshotFrame {
            let top = max(frame.minY, detailBarFrame.maxY)
            frame = CGRect(
                x: frame.minX,
                y: top,
                width: frame.width,
                height: max(0, frame.maxY - top)
            )
        }
        let tabBar = app.tabBars.firstMatch
        if let tabBarFrame = tabBar.snapshotFrame, tabBarFrame.minY > frame.midY {
            frame.size.height = max(0, min(frame.maxY, tabBarFrame.minY) - frame.minY)
        }
        return frame
    }
}
