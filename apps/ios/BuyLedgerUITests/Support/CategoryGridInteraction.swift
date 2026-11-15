//
//  CategoryGridInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import XCTest

/// 篩選 sheet 與選擇器共用的類別格查詢及捲動互動
@MainActor
struct CategoryGridInteraction {

    // MARK: - Properties

    /// 類別格所在的受測 App
    private let app: XCUIApplication

    // MARK: - Init

    /// 保存類別格所在的受測 App
    ///
    /// - Parameter app: 受測 App
    init(app: XCUIApplication) {
        self.app = app
    }
}

// MARK: - Internal Method

extension CategoryGridInteraction {

    /// 取得篩選 sheet 或類別選擇器內組標題的元素
    ///
    /// - Parameter kindID: 組別種類的識別值 (`ongoing` 或 `closed`)
    /// - Returns: 對應組標題的元素
    func filterGroupHeader(_ kindID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryGroupHeader(kindID)]
    }

    /// 取篩選 sheet 或類別選擇器內指定類別的格子
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 對應格子的元素
    func filterCategoryCell(_ name: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryCell(name)]
    }

    /// 依序搜尋下方與上方內容，露出指定類別格
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - container: 格子所在的捲動容器
    ///   - maxSwipes: 每個方向最多捲動次數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 容器消失或找不到類別格時丟出測試錯誤
    func revealFilterCategory(
        _ name: String,
        within container: XCUIElement,
        maxSwipes: Int = 60,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try revealElement(
            filterCategoryCell(name),
            within: container,
            maxSwipes: maxSwipes,
            file: file,
            line: line
        )
    }

    /// 依位置簽章搜尋下方與上方內容，直到目標出現
    ///
    /// - Parameters:
    ///   - element: 要露出的元素
    ///   - container: 元素所在的捲動容器
    ///   - maxSwipes: 每個方向最多捲動次數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 容器消失或目標無法露出時丟出測試錯誤
    func revealElement(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int = 60,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try app.reveal(
            element,
            within: container,
            isSwipingUp: true,
            maxGestures: maxSwipes,
            oppositeStartY: 0.35,
            dragDistance: 0.3,
            gestureStyle: .swipe,
            oppositeGestureStyle: .slowDrag,
            holdDuration: 0.1,
            searchesBothDirections: true,
            requiresHittable: false,
            file: file,
            line: line
        )
    }

    /// 捲動容器把元素露到導覽列下方的可點範圍內，輕拖結束後等位置穩定才回傳
    ///
    /// - Parameters:
    ///   - element: 要捲到可點位置的元素
    ///   - container: 元素所在的 sheet
    ///   - maxDrags: 輕拖次數上限
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 元素無法穩定或未能露出可點範圍時丟出測試錯誤
    /// - Note: 導覽列遮住的部分不算可點，因此判斷範圍由導覽列下緣起算
    /// - Note: 慣性未停止前點擊只會停住捲動，因此輕拖後先等位置穩定再點擊
    func scrollToTappable(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxDrags: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        var drags = 0
        while true {
            if !waitUntilFrameStable(element) {
                try app.stopWithDiagnostics("元素位置未穩定，無法安全點擊", file: file, line: line)
            }
            if isInVisibleBand(element, within: container) {
                return
            }
            if drags >= maxDrags {
                try app.stopWithDiagnostics("輕拖上限內仍無法露出可點範圍，目標可能被導覽列遮住", file: file, line: line)
            }
            dragToward(element, within: container)
            drags += 1
        }
    }
}

// MARK: - Private Method

private extension CategoryGridInteraction {

    /// 輪詢元素的框線，連續兩次讀到相同且有效的框線即視為慣性已停止
    ///
    /// - Parameters:
    ///   - element: 要觀察的元素
    ///   - maxReads: 最多讀取框線的次數
    /// - Returns: 框線是否在上限內穩定
    /// - Note: 每次讀取框線都要查詢可及性樹，大清單下單次約數秒，因此以讀取次數而非牆鐘時間為上限
    func waitUntilFrameStable(_ element: XCUIElement, maxReads: Int = 10) -> Bool {
        var previous: CGRect?
        var stableReads = 0
        for _ in 0..<maxReads {
            if let current = element.snapshotFrame {
                if current == previous {
                    stableReads += 1
                    if stableReads >= 2 {
                        return true
                    }
                } else {
                    stableReads = 0
                }
                previous = current
            }
            Polling.pause(for: 0.1) // 固定取樣間隔，保留以讀取次數限制昂貴框線查詢的策略
        }
        return false
    }

    /// 判斷元素是否完整落在導覽列下緣與容器下緣之間
    ///
    /// - Parameters:
    ///   - element: 要判斷的元素
    ///   - container: 元素所在的 sheet
    /// - Returns: 元素是否在可點範圍內
    func isInVisibleBand(_ element: XCUIElement, within container: XCUIElement) -> Bool {
        guard let frame = element.snapshotFrame else {
            return false
        }
        guard let containerFrame = container.snapshotFrame else {
            return false
        }
        let top = visibleTopEdge(in: containerFrame)
        return frame.minY >= top && frame.maxY <= containerFrame.maxY
    }

    /// 取得容器內可點範圍的上緣，有位於容器上半部的導覽列時為其下緣，否則為容器上緣
    ///
    /// - Parameter containerFrame: 已通過 `isUsableFrame` 的容器框線
    /// - Returns: 可點範圍的上緣座標
    /// - Note: 導覽列不是容器的子孫，因此從 App 的導覽列中以位置挑選
    func visibleTopEdge(in containerFrame: CGRect) -> CGFloat {
        var top = containerFrame.minY
        for bar in app.navigationBars.allElementsBoundByIndex {
            guard let frame = bar.snapshotFrame else {
                continue
            }
            let isOverlapping = frame.minX < containerFrame.maxX && frame.maxX > containerFrame.minX
            let isInUpperHalf = frame.midY >= containerFrame.minY
                && frame.midY < containerFrame.midY
            if isOverlapping && isInUpperHalf {
                top = max(top, frame.maxY)
            }
        }
        return top
    }

    /// 輕拖容器一次，元素在可點範圍上方時向下拖，否則向上拖
    ///
    /// - Parameters:
    ///   - element: 要露出的元素
    ///   - container: 元素所在的 sheet
    func dragToward(_ element: XCUIElement, within container: XCUIElement) {
        guard let frame = element.snapshotFrame else {
            return
        }
        guard let containerFrame = container.snapshotFrame else {
            return
        }
        let isAboveBand = frame.minY < visibleTopEdge(in: containerFrame)
        let startY: CGFloat = isAboveBand ? 0.3 : 0.7
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
