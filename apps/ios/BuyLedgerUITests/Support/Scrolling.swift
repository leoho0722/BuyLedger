//
//  Scrolling.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 把離屏元素捲進可點位置的捲動 helper

// MARK: - Internal Method

extension XCUIApplication {

    /// 在捲動容器內垂直捲動直到目標可點
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

    /// 以小幅、無慣性的拖曳把目標捲進可點位置
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
        guard container.waitForExistence(timeout: 5), element.waitForExistence(timeout: 5) else {
            return false
        }
        var drags = 0
        while drags < maxDrags {
            let elementFrame = element.frame
            if !elementFrame.isEmpty && container.frame.intersects(elementFrame) {
                return true
            }
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
            let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY))
            start.press(forDuration: 0.1, thenDragTo: end)
            drags += 1
        }
        let elementFrame = element.frame
        return !elementFrame.isEmpty && container.frame.intersects(elementFrame)
    }
}

// MARK: - Private Method

private extension XCUIApplication {

    /// 反覆對容器施加捲動手勢，每次後以短輪詢等目標可點
    /// - Parameters:
    ///   - element: 要捲到可點位置的目標元素
    ///   - container: 可捲動的容器
    ///   - maxSwipes: 最多捲動次數
    ///   - swipe: 要對容器執行的捲動手勢
    /// - Returns: 目標元素是否在捲動後可點
    func scrollUntilHittable(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int,
        swipe: (XCUIElement) -> Void
    ) -> Bool {
        guard container.waitForExistence(timeout: 5) else {
            return false
        }
        if element.isHittable {
            return true
        }
        for _ in 0..<max(maxSwipes, 0) {
            swipe(container)
            if element.waitUntilHittable(timeout: 1) {
                return true
            }
        }
        return element.isHittable
    }
}
