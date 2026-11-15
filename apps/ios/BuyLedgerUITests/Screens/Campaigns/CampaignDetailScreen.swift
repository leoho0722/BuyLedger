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

// MARK: - Computed Properties

@MainActor
extension CampaignDetailScreen {

    /// 只看未收款開關目前是否為開啟狀態；開關不存在時為 `false`
    var isUnpaidOnlyEnabled: Bool {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        return toggle.exists && (toggle.value as? String) == "1"
    }
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
        let element = summaryElement(kind)
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 等待已收數值列更新為指定金額
    ///
    /// - Parameters:
    ///   - amount: 預期的已收金額顯示值
    ///   - timeout: 等待數值更新的秒數
    /// - Returns: 已收金額是否在逾時前符合預期；數值列不存在時為 `false`
    /// - Note: 不捲動；數值列在畫面外時由呼叫端先呼叫 `revealReceivedAmount`
    func waitForReceivedAmount(_ amount: String, timeout: TimeInterval = 10) -> Bool {
        let element = summaryElement(.received)
        guard element.exists else {
            return false
        }
        return element.wait(for: NSPredicate(format: "value == %@", amount), timeout: timeout)
    }

    /// 將已收數值列捲回畫面
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 已收數值列無法捲入可互動範圍時丟出測試錯誤
    func revealReceivedAmount(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard revealElement(summaryElement(.received), isSwipingUp: false) else {
            try app.stopWithDiagnostics("找不到可互動的已收金額數值列", file: file, line: line)
        }
    }

    /// 判斷指定客戶的分貨列目前是否存在且可互動
    ///
    /// - Parameter customerName: 要尋找的客戶名稱
    /// - Returns: 該客戶的分貨列是否存在且可互動
    /// - Note: 不捲動；列在畫面外時由呼叫端先呼叫 `revealDistributionRow`
    func hasDistributionRow(customerName: String) -> Bool {
        let row = distributionRow(customerName: customerName)
        return row.exists && row.isHittableOnScreen
    }

    /// 捲到指定客戶的分貨列，確認該列存在且可互動
    ///
    /// - Parameters:
    ///   - customerName: 要尋找的客戶名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到該客戶的可互動分貨列時丟出測試錯誤
    func revealDistributionRow(
        customerName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = distributionRow(customerName: customerName)
        guard revealElement(row, isSwipingUp: true) else {
            try app.stopWithDiagnostics("找不到客戶「\(customerName)」的分貨列", file: file, line: line)
        }
    }

    /// 捲到篩選前已收款與未收款客戶的分貨列，讓之後的消失斷言有正向對照
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 任一客戶的分貨列無法捲到可互動時丟出測試錯誤
    func revealDistributionRowsBeforeFilter(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        for customerName in CampaignSeedFixture.paidCustomerNames {
            try revealDistributionRow(customerName: customerName, file: file, line: line)
        }
        try revealDistributionRow(
            customerName: CampaignSeedFixture.unpaidCustomerName,
            file: file,
            line: line
        )
    }

    /// 將客戶分貨列捲往畫面中段，點整列中央並等待指定訂單的收款鍵
    ///
    /// - Parameters:
    ///   - customerName: 要展開的客戶名稱
    ///   - orderID: 該客戶所屬訂單的識別值，供確認分貨列已展開
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 分貨列或收款鍵未出現時丟出測試錯誤
    func expandDistributionRow(
        customerName: String,
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = distributionRow(customerName: customerName)
        if !revealElementInMiddle(row, isSwipingUp: true) {
            try app.stopWithDiagnostics("找不到客戶「\(customerName)」的可展開分貨列", file: file, line: line)
        }
        try row.tapAfterWaiting(in: app, file: file, line: line)
        let receipt = app.buttons[BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: orderID)]
        // 展開後的新訂單列也可能尚未建立，必要時先捲入可及性樹
        if !receipt.waitForExistence(timeout: 2),
           !revealElement(receipt, isSwipingUp: true) {
            try app.stopWithDiagnostics(
                "展開客戶「\(customerName)」後找不到訂單「\(orderID)」的收款鍵",
                file: file,
                line: line
            )
        }
        guard receipt.waitForExistence(timeout: 10) else {
            try app.stopWithDiagnostics(
                "展開客戶「\(customerName)」後找不到訂單「\(orderID)」的收款鍵",
                file: file,
                line: line
            )
        }
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapReceiptToggle(
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: orderID)]
        guard revealElementInMiddle(button, isSwipingUp: true) else {
            try app.stopWithDiagnostics("找不到訂單「\(orderID)」的收款鍵", file: file, line: line)
        }
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 將只看未收款開關捲入可互動範圍
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 開關無法捲入可互動範圍時丟出測試錯誤
    func revealUnpaidOnlyToggle(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        guard revealElement(toggle, isSwipingUp: false) else {
            try app.stopWithDiagnostics("找不到可互動的只看未收款開關", file: file, line: line)
        }
    }

    /// 點只看未收款開關
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func toggleUnpaidOnly(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        try revealUnpaidOnlyToggle(file: file, line: line)
        let control = toggle.switches.firstMatch
        guard revealElement(control, isSwipingUp: false) else {
            try app.stopWithDiagnostics("找不到只看未收款的內層開關", file: file, line: line)
        }
        try control.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待只看未收款開關變成開啟
    ///
    /// - Parameter timeout: 等待開關值更新的秒數
    /// - Returns: 開關是否在逾時前變成開啟狀態；開關不存在時為 `false`
    /// - Note: 不捲動；開關在畫面外時由呼叫端先呼叫 `revealUnpaidOnlyToggle`
    func waitForUnpaidOnlyEnabled(timeout: TimeInterval = 10) -> Bool {
        let toggle = app.switches[BLAccessibilityID.Campaigns.detailUnpaidToggle]
        guard toggle.exists else {
            return false
        }
        return toggle.wait(for: NSPredicate(format: "value == %@", "1"), timeout: timeout)
    }

    /// 開啟「更多」操作選單 (編輯／結團／刪除)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func openMoreMenu(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailMoreButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點更多選單的編輯開團，等待編輯表單就緒
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的開團編輯表單
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapEdit(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CampaignEditScreen {
        try app.tapMenuItem(BLAccessibilityID.Campaigns.detailEditButton, file: file, line: line)
        let edit = CampaignEditScreen(app: app)
        try edit.requireReady(file: file, line: line)
        return edit
    }

    /// 點更多選單的結團結算 (不可逆)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapSettle(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapMenuItem(BLAccessibilityID.Campaigns.detailSettleButton, file: file, line: line)
    }

    /// 點更多選單的刪除開團 (破壞性)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapDelete(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapMenuItem(BLAccessibilityID.Campaigns.detailDeleteButton, file: file, line: line)
        guard waitForDeleteConfirmation() else {
            try app.stopWithDiagnostics("刪除確認 alert 未出現", file: file, line: line)
        }
    }

    /// 等待結團確認 alert 呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    func waitForSettleConfirmation(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點結團確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func cancelSettle(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapAlertButton(label: "取消", file: file, line: line)
    }

    /// 等待刪除確認 alert 呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    func waitForDeleteConfirmation(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 等待刪除確認 alert 收回
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    func waitForDeleteConfirmationDismissal(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }

    /// 點刪除確認 alert 的破壞性刪除按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func confirmDelete(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapAlertButton(label: "刪除", file: file, line: line)
    }

    /// 點刪除確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func cancelDelete(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapAlertButton(label: "取消", file: file, line: line)
    }

    /// 等待 alert 消失
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    func waitForConfirmationDismissal(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }

    /// 從詳情的導覽列返回開團列表，避免點到 iPad 側邊欄的返回鍵
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapBack(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapBackButton(
            inNavigationBarContaining: BLAccessibilityID.Campaigns.detailMoreButton,
            file: file,
            line: line
        )
    }
}

// MARK: - ScreenProtocol

extension CampaignDetailScreen: ScreenProtocol {

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.detailRoot
    }
}

// MARK: - Private Method

@MainActor
private extension CampaignDetailScreen {

    /// 取指定結團結算數值列的元素
    ///
    /// - Parameter kind: 結算數值種類
    /// - Returns: 對應的結算數值列元素
    func summaryElement(_ kind: BLAccessibilityID.Campaigns.DetailSummary) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.detailSummary(kind)]
    }

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
        // 收款與篩選後可能保留不同位置，到盡頭時再往回找
        for shouldSwipeUp in [isSwipingUp, !isSwipingUp] {
            let startY: CGFloat = shouldSwipeUp ? 0.7 : 0.3
            let endY: CGFloat = 0.5
            var previous = app.scrollPositionSignature(in: container)
            for _ in 0..<12 {
                if element.exists {
                    if app.waitUntilHittableByGentleDrag(
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
            guard let frame = element.snapshotFrame, frame.isUsableFrame else {
                return false
            }
            let visibleFrame = visibleContentFrame()
            guard visibleFrame.isUsableFrame else {
                return false
            }
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
            if let current = element.snapshotFrame,
               current.isUsableFrame,
               abs(current.midY - frame.midY) < 1 {
                break
            }
        }
        // 清單底端可能無法置中，仍須避開浮動分頁列才可點擊
        guard let frame = element.snapshotFrame, frame.isUsableFrame else {
            return false
        }
        let visibleFrame = visibleContentFrame()
        return visibleFrame.isUsableFrame
            && visibleFrame.insetBy(dx: 0, dy: 16).contains(frame)
            && element.waitUntilStableAndHittable(timeout: 1)
    }

    /// 取得詳情容器中未被導覽列與底部分頁列覆蓋的範圍
    ///
    /// - Returns: 可以安全定位分貨列與收款鍵的可見內容範圍
    func visibleContentFrame() -> CGRect {
        guard let rootFrame = rootElement.snapshotFrame,
              rootFrame.isUsableFrame,
              let appFrame = app.snapshotFrame,
              appFrame.isUsableFrame else {
            return .zero
        }
        var frame = rootFrame.intersection(appFrame)
        guard frame.isUsableFrame else {
            return .zero
        }
        let detailBar = app.navigationBars
            .containing(.button, identifier: BLAccessibilityID.Campaigns.detailMoreButton)
            .firstMatch
        if let detailBarFrame = detailBar.snapshotFrame, detailBarFrame.isUsableFrame {
            let top = max(frame.minY, detailBarFrame.maxY)
            frame = CGRect(
                x: frame.minX,
                y: top,
                width: frame.width,
                height: max(0, frame.maxY - top)
            )
        }
        let tabBar = app.tabBars.firstMatch
        if let tabBarFrame = tabBar.snapshotFrame,
           tabBarFrame.isUsableFrame,
           tabBarFrame.minY > frame.midY {
            frame.size.height = max(0, min(frame.maxY, tabBarFrame.minY) - frame.minY)
        }
        return frame.isUsableFrame ? frame : .zero
    }
}
