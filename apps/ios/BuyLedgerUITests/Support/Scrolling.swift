//
//  Scrolling.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 把離屏元素捲進可點位置的捲動 helper
///
/// `Form` / `List` / `ScrollView` 的離屏列不在 accessibility 樹，直接查詢會落空；
/// 這些 helper 在指定容器內反覆捲動並以短輪詢等元素就緒，取代固定 sleep。
/// 達上限仍不可點時回傳 `false`，由呼叫端 `failWithDiagnostics`

// MARK: - Internal Method

extension XCUIApplication {

    /// 在捲動容器內垂直捲動直到目標可點
    /// - Parameters:
    ///   - element: 目標元素
    ///   - container: 承載目標的捲動容器 (在其上施加 swipe)
    ///   - maxSwipes: 最多捲動次數，達上限仍不可點即放棄
    /// - Returns: 是否成功讓目標進入可點位置
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
    ///   - element: 目標元素
    ///   - container: 承載目標的水平捲動容器 (在其上施加 swipe)
    ///   - maxSwipes: 最多捲動次數，達上限仍不可點即放棄
    /// - Returns: 是否成功讓目標進入可點位置
    @discardableResult
    func scrollToHittableHorizontally(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int = 10
    ) -> Bool {
        scrollUntilHittable(element, within: container, maxSwipes: maxSwipes) { $0.swipeLeft() }
    }

    /// 以小幅、無慣性的拖曳把目標捲進可點位置
    ///
    /// `swipeUp` 帶慣性、一次可捲數百點，對「只差幾點就露出」的元素會整個衝過頭捲離螢幕 (置中 sheet
    /// 這類短容器尤甚)。此版改以固定短距 `press…thenDragTo` 逐步逼近，每步後查可點就停，避免衝過頭。
    /// 目標須已在樹上 (frame 有效);離屏未渲染的惰性列請改用 `swipeUp` 查 `exists` 版
    /// - Parameters:
    ///   - element: 目標元素 (須已渲染、frame 有效)
    ///   - container: 施加拖曳的捲動容器
    ///   - maxDrags: 最多拖曳次數，達上限仍不可點即放棄
    /// - Returns: 是否成功讓目標進入可點位置
    @discardableResult
    func scrollToHittableGently(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxDrags: Int = 12
    ) -> Bool {
        guard container.waitForExistence(timeout: 5) else {
            return false
        }
        var drags = 0
        while element.exists, !element.isHittable, drags < maxDrags {
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end)
            drags += 1
        }
        return element.exists && element.isHittable
    }
}

// MARK: - Private Method

private extension XCUIApplication {

    /// 反覆對容器施加捲動手勢，每次後以短輪詢等目標可點
    ///
    /// 捲動後版面需要時間安定，改以 `waitUntilHittable` 短輪詢取代固定 sleep：
    /// 目標一可點就立刻回傳，該次逾時才進行下一次捲動
    /// - Parameters:
    ///   - element: 目標元素
    ///   - container: 施加手勢的捲動容器
    ///   - maxSwipes: 最多捲動次數
    ///   - swipe: 單次捲動手勢 (垂直傳 `swipeUp`、水平傳 `swipeLeft`)
    /// - Returns: 是否成功讓目標進入可點位置
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
