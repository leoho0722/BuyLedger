//
//  CampaignDetailScreen+Content.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/3.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension CampaignDetailScreen {

    /// 是否在逾時前看到已結團狀態
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
        guard revealElement(element, swipingUp: false) else {
            return false
        }
        return element.wait(for: NSPredicate(format: "value == %@", amount), timeout: timeout)
    }

    /// 捲到指定客戶的分貨列，確認該列存在且可互動
    ///
    /// - Parameter customerName: 要尋找的客戶名稱
    /// - Returns: 是否找到該客戶的可互動分貨列
    func hasDistributionRow(customerName: String) -> Bool {
        revealElement(distributionRow(customerName: customerName), swipingUp: true)
    }

    /// 依客戶名稱取得可展開的分貨列
    ///
    /// - Parameter customerName: 要展開的客戶名稱
    /// - Returns: 對應客戶的分貨列標題
    func distributionRow(customerName: String) -> XCUIElement {
        app.buttons[BLAccessibilityID.Campaigns.detailDistributionRow(customerName: customerName)]
    }

    /// 將客戶分貨列捲往畫面中段，點整列中央並等待指定訂單的收款鍵
    ///
    /// - Parameters:
    ///   - customerName: 要展開的客戶名稱
    ///   - orderID: 該客戶所屬訂單的識別值，用來確認分貨列已展開
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
        if !revealElementInMiddle(row, swipingUp: true) {
            app.failWithDiagnostics("找不到客戶「\(customerName)」的可展開分貨列", file: file, line: line)
            return false
        }
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let receipt = app.buttons[BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: orderID)]
        // 展開後的新訂單列也可能尚未建立，必要時先捲入可及性樹
        if !receipt.waitForExistence(timeout: 2) && !revealElement(receipt, swipingUp: true) {
            app.failWithDiagnostics(
                "展開客戶「\(customerName)」後找不到訂單「\(orderID)」的收款鍵",
                file: file,
                line: line
            )
            return false
        }
        return receipt.waitForExistence(timeout: 10)
    }

    /// 將指定訂單的收款鍵捲往畫面中段，切換已收款與未收款
    ///
    /// - Parameters:
    ///   - orderID: 已展開分貨列中的訂單識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapReceiptToggle(orderID: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: orderID)]
        if !revealElementInMiddle(button, swipingUp: true) {
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
        if !revealElement(toggle, swipingUp: false) {
            app.failWithDiagnostics("找不到只看未收款開關", file: file, line: line)
            return
        }
        let control = toggle.switches.firstMatch
        if !revealElement(control, swipingUp: false) {
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
        guard revealElement(toggle, swipingUp: false) else {
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
        if !revealElement(toggle, swipingUp: false) {
            app.failWithDiagnostics("找不到只看未收款開關，無法讀取開關值", file: file, line: line)
            return false
        }
        return toggle.value as? String == "1"
    }
}

// MARK: - Private Method

@MainActor
private extension CampaignDetailScreen {

    /// 小幅捲動詳情直到目標列出現，再用共用的捲動方法捲到可互動的位置
    ///
    /// - Parameters:
    ///   - element: 要捲進畫面的詳情元素
    ///   - swipingUp: 是否先向上滑動以尋找畫面下方的元素
    /// - Returns: 是否找到可互動的元素
    func revealElement(_ element: XCUIElement, swipingUp: Bool) -> Bool {
        let container = rootElement
        guard container.waitForExistence(timeout: 10) else {
            return false
        }
        // 收款與篩選後可能保留不同捲動位置，第一個方向找不到時再往回找
        for isSwipingUp in [swipingUp, !swipingUp] {
            let startY: CGFloat = isSwipingUp ? 0.7 : 0.3
            let endY: CGFloat = 0.5
            for _ in 0..<12 {
                if element.exists {
                    if app.scrollToHittableGently(
                        element,
                        within: container,
                        maxDrags: 1,
                        startY: startY,
                        endY: endY
                    ) {
                        return true
                    }
                } else {
                    // 未建立的清單列只查 exists，避免查詢無效的外框
                    let start = container.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: startY)
                    )
                    let end = container.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: endY)
                    )
                    start.press(forDuration: 0.1, thenDragTo: end)
                }
            }
        }
        return element.exists && element.isHittable
    }

    /// 將目標捲往可見內容中段，確認完整外框避開導覽列與浮動分頁列
    ///
    /// - Parameters:
    ///   - element: 要安全點擊的分貨列或收款鍵
    ///   - swipingUp: 是否先向上滑動以尋找畫面下方的元素
    /// - Returns: 目標是否完整露出且可互動
    func revealElementInMiddle(_ element: XCUIElement, swipingUp: Bool) -> Bool {
        guard revealElement(element, swipingUp: swipingUp) else {
            return false
        }
        let container = rootElement
        for _ in 0..<6 {
            guard element.exists else {
                return false
            }
            let frame = element.frame
            let visibleFrame = visibleContentFrame()
            let safeFrame = visibleFrame.insetBy(dx: 0, dy: 16)
            if abs(frame.midY - visibleFrame.midY) <= visibleFrame.height * 0.15,
               safeFrame.contains(frame),
               element.isHittable {
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
            if element.exists && abs(element.frame.midY - frame.midY) < 1 {
                break
            }
        }
        // 清單底端可能無法再移到正中央，仍須完整避開浮動分頁列才可點擊
        return element.exists
            && visibleContentFrame().insetBy(dx: 0, dy: 16).contains(element.frame)
            && element.isHittable
    }

    /// 取得詳情容器中未被導覽列與底部分頁列覆蓋的範圍
    ///
    /// - Returns: 可以安全定位分貨列與收款鍵的可見內容範圍
    func visibleContentFrame() -> CGRect {
        var frame = rootElement.frame.intersection(app.frame)
        let detailBar = app.navigationBars
            .containing(.button, identifier: BLAccessibilityID.Campaigns.detailMoreButton)
            .firstMatch
        if detailBar.exists {
            let top = max(frame.minY, detailBar.frame.maxY)
            frame = CGRect(
                x: frame.minX,
                y: top,
                width: frame.width,
                height: max(0, frame.maxY - top)
            )
        }
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists && tabBar.frame.minY > frame.midY {
            frame.size.height = max(0, min(frame.maxY, tabBar.frame.minY) - frame.minY)
        }
        return frame
    }
}
