//
//  XCUIApplication+Scrolling.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

/// 把離屏元素捲進可點位置的捲動 helper
@MainActor
extension XCUIApplication {

    /// 讓缺少有效框線的目標元素進入樹中，盡力向下捲到可點位置
    ///
    /// - Parameters:
    ///   - identifiers: 要確認存在的 accessibility identifier
    ///   - container: 可捲動的容器
    /// - Note: 只會向下捲動；未能捲到可點位置時由後續讀取捕捉
    func loadMissingElements(with identifiers: [String], within container: XCUIElement) {
        for identifier in identifiers {
            let element = descendants(matching: .any)[identifier].firstMatch
            guard element.snapshotFrame == nil else {
                continue
            }
            _ = scrollToHittable(element, within: container)
        }
    }

    /// 在捲動容器內垂直捲動直到目標可點
    ///
    /// - Parameters:
    ///   - element: 要捲到可點位置的目標元素
    ///   - container: 可捲動的容器
    ///   - maxSwipes: 最多捲動次數
    /// - Returns: 目標元素是否在捲動後可點
    @discardableResult
    func scrollToHittable(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int = 10
    ) -> Bool {
        scrollUntilHittable(element, within: container, maxSwipes: maxSwipes) { $0.swipeUp() }
    }

    /// 在捲動容器內水平捲動直到目標可點，供狀態 chip 列與照片縮圖列使用
    ///
    /// - Parameters:
    ///   - element: 要捲到可點位置的目標元素
    ///   - container: 可捲動的容器
    ///   - maxSwipes: 最多捲動次數
    /// - Returns: 目標元素是否在捲動後可點
    @discardableResult
    func scrollToHittableHorizontally(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int = 10
    ) -> Bool {
        scrollUntilHittable(element, within: container, maxSwipes: maxSwipes) { $0.swipeLeft() }
    }

    /// 取得捲動容器內與 App 視窗相交的內容位置簽章，供判斷捲動是否已到盡頭
    ///
    /// - Parameter container: 要觀察的捲動容器
    /// - Returns: 可見內容的識別資料與框線簽章；容器或內容尚未就緒時為 `nil`
    /// - Note: 只擷取一次容器階層，再走訪快照的子元素，不逐列要求遠端快照或查詢可點性
    func scrollPositionSignature(in container: XCUIElement) -> String? {
        let snapshot = try? container.firstMatch.snapshot() // 失敗可忽略，因為容器可能尚未建立
        guard let snapshot, let appFrame = snapshotFrame else {
            return nil
        }
        let containerFrame = snapshot.frame
        guard !containerFrame.isNull,
              !containerFrame.isInfinite,
              !containerFrame.isEmpty,
              containerFrame.minX.isFinite,
              containerFrame.minY.isFinite,
              containerFrame.maxX.isFinite,
              containerFrame.maxY.isFinite else {
            return nil
        }
        let visibleFrame = containerFrame.intersection(appFrame)
        guard !visibleFrame.isNull, !visibleFrame.isEmpty else {
            return nil
        }
        var pending = Array(snapshot.children.reversed())
        var signatures: [String] = []
        while let child = pending.popLast() {
            pending.append(contentsOf: child.children.reversed())
            let frame = child.frame
            guard !frame.isNull,
                  !frame.isInfinite,
                  !frame.isEmpty,
                  frame.minX.isFinite,
                  frame.minY.isFinite,
                  frame.maxX.isFinite,
                  frame.maxY.isFinite,
                  visibleFrame.intersects(frame) else {
                continue
            }
            signatures.append("\(child.identifier)|\(child.label)|\(frame)")
        }
        return signatures.isEmpty ? nil : signatures.joined(separator: "\n")
    }

    /// 以小幅、無慣性的拖曳把目標捲進可點位置
    ///
    /// - Parameters:
    ///   - element: 要捲到可點位置的目標元素
    ///   - container: 可捲動的容器
    ///   - maxDrags: 最多拖曳次數
    ///   - startY: 拖曳起點的正規化 Y 座標
    ///   - endY: 拖曳終點的正規化 Y 座標
    /// - Returns: 目標元素是否在拖曳後可點
    @discardableResult
    func scrollToHittableGently(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxDrags: Int = 12,
        startY: CGFloat = 0.7,
        endY: CGFloat = 0.5
    ) -> Bool {
        scrollGently(
            element,
            within: container,
            maxDrags: maxDrags,
            startY: startY,
            endY: endY
        ) { $0.isHittableOnScreen }
    }

    /// 以小幅、無慣性的拖曳把目標捲到垂直方向完整落在容器可見範圍內且可點
    ///
    /// - Parameters:
    ///   - element: 要捲到完整可見位置的目標元素
    ///   - container: 可捲動的容器，其框線即可見範圍
    ///   - maxDrags: 最多拖曳次數
    ///   - startY: 拖曳起點的正規化 Y 座標
    ///   - endY: 拖曳終點的正規化 Y 座標
    /// - Returns: 目標元素是否在拖曳後完整可見且可點
    /// - Note: 只露出底緣的元素仍可能 hittable，因此停止條件另要求垂直區間完整包含於容器
    /// - Note: 只處理自下方捲入的目標，目標位於容器上方時向上拖曳無法回捲
    @discardableResult
    func scrollToFullyVisibleGently(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxDrags: Int = 12,
        startY: CGFloat = 0.7,
        endY: CGFloat = 0.5
    ) -> Bool {
        scrollGently(
            element,
            within: container,
            maxDrags: maxDrags,
            startY: startY,
            endY: endY
        ) { target in
            guard target.isHittableOnScreen,
                  let frame = target.snapshotFrame,
                  let containerFrame = container.snapshotFrame else {
                return false
            }
            return frame.minY >= containerFrame.minY && frame.maxY <= containerFrame.maxY
        }
    }
}

// MARK: - Private Method

@MainActor
private extension XCUIApplication {

    /// 反覆對容器施加捲動手勢，每次捲動後等待目標穩定且可點，內容不再移動時停止
    ///
    /// - Parameters:
    ///   - element: 要捲到可點位置的目標元素
    ///   - container: 可捲動的容器
    ///   - maxSwipes: 最多捲動次數
    ///   - swipe: 要對容器執行的捲動手勢
    /// - Returns: 目標元素是否在捲動後穩定且可點
    func scrollUntilHittable(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int,
        swipe: (XCUIElement) -> Void
    ) -> Bool {
        guard container.waitForExistence(timeout: 5) else {
            return false
        }
        if element.snapshotFrame != nil, element.waitUntilStableAndHittable(timeout: 1) {
            return true
        }
        var previous = scrollPositionSignature(in: container)
        for _ in 0..<max(maxSwipes, 0) {
            swipe(container)
            if element.waitUntilStableAndHittable(timeout: 1) {
                return true
            }
            let current = scrollPositionSignature(in: container)
            if let current, current == previous {
                return false
            }
            previous = current
        }
        return element.waitUntilStableAndHittable(timeout: 1)
    }

    /// 以小幅、無慣性的拖曳重複嘗試，直到 `isReady` 成立；容器位置簽章不再變化或達拖曳上限時停止
    ///
    /// - Parameters:
    ///   - element: 要捲到就緒位置的目標元素
    ///   - container: 可捲動的容器
    ///   - maxDrags: 最多拖曳次數
    ///   - startY: 拖曳起點的正規化 Y 座標
    ///   - endY: 拖曳終點的正規化 Y 座標
    ///   - isReady: 判斷目標是否已就緒的條件
    /// - Returns: 目標元素是否在拖曳後符合 `isReady`
    func scrollGently(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxDrags: Int,
        startY: CGFloat,
        endY: CGFloat,
        isReady: (XCUIElement) -> Bool
    ) -> Bool {
        guard container.waitForExistence(timeout: 5), element.waitForExistence(timeout: 5) else {
            return false
        }
        var drags = 0
        var previous = scrollPositionSignature(in: container)
        while drags < maxDrags {
            if isReady(element) {
                return true
            }
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
            let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY))
            start.press(forDuration: 0.1, thenDragTo: end)
            drags += 1
            let current = scrollPositionSignature(in: container)
            if let current, current == previous {
                return isReady(element)
            }
            previous = current
        }
        return isReady(element)
    }
}
