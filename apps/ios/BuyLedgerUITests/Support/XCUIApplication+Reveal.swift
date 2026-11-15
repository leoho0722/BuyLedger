//
//  XCUIApplication+Reveal.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import CoreGraphics
import XCTest

// MARK: - 依位置簽章捲動露出元素

/// 依內容位置是否改變，捲動容器直到指定元素符合可見條件
@MainActor
extension XCUIApplication {

    /// 露出元素時使用的捲動手勢
    enum RevealGestureStyle: Equatable {

        /// 以無慣性的拖曳改變捲動位置
        case drag

        /// 以慢速拖曳並短暫停留，避免誤關閉 sheet
        case slowDrag

        /// 以系統滑動手勢捲動，會帶有慣性
        case swipe
    }

    /// 捲動容器尋找元素，內容位置停止改變或達手勢上限時停止
    ///
    /// - Parameters:
    ///   - element: 要露出的元素
    ///   - container: 元素所在的捲動容器
    ///   - isSwipingUp: 是否先向上滑動以尋找容器下方的內容
    ///   - maxGestures: 每個搜尋方向允許的手勢次數
    ///   - startX: 拖曳起點的正規化 X 座標
    ///   - startY: 第一搜尋方向拖曳起點的正規化 Y 座標；未指定時依方向選擇
    ///   - oppositeStartY: 反向搜尋時拖曳起點的正規化 Y 座標
    ///   - dragDistance: 拖曳距離的正規化高度
    ///   - gestureStyle: 第一搜尋方向使用的手勢
    ///   - oppositeGestureStyle: 反向搜尋時使用的手勢
    ///   - holdDuration: 慢速拖曳後停留的秒數
    ///   - searchesBothDirections: 第一個方向到底後是否改向搜尋
    ///   - requiresVisibleFrame: 是否要求元素框線與容器相交
    ///   - requiresFullVisibility: 是否要求元素框線完整落在容器內
    ///   - requiresHittable: 是否要求元素可點且框線穩定
    ///   - signatureElements: 以相對於容器的位置補充判斷捲動是否停止的元素
    ///   - timeout: 等待容器與每次手勢後位置穩定的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 容器不存在或元素未能露出時丟出 `UITestError.stopped`
    func reveal(
        _ element: XCUIElement,
        within container: XCUIElement,
        isSwipingUp: Bool,
        maxGestures: Int = 12,
        startX: CGFloat = 0.5,
        startY: CGFloat? = nil,
        oppositeStartY: CGFloat? = nil,
        dragDistance: CGFloat = 0.2,
        gestureStyle: RevealGestureStyle = .drag,
        oppositeGestureStyle: RevealGestureStyle? = nil,
        holdDuration: TimeInterval = 0,
        searchesBothDirections: Bool = false,
        requiresVisibleFrame: Bool = false,
        requiresFullVisibility: Bool = false,
        requiresHittable: Bool = true,
        signatureElements: [XCUIElement] = [],
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard maxGestures >= 0, timeout.isFinite, timeout >= 0 else {
            try stopWithDiagnostics("露出元素的手勢上限或逾時秒數無效", file: file, line: line)
        }
        guard container.waitForExistence(timeout: timeout) else {
            try stopWithDiagnostics("捲動容器不存在，無法露出目標元素", file: file, line: line)
        }

        if isRevealed(
            element,
            within: container,
            requiresVisibleFrame: requiresVisibleFrame,
            requiresFullVisibility: requiresFullVisibility,
            requiresHittable: requiresHittable
        ) {
            return
        }

        let directions = searchesBothDirections ? [isSwipingUp, !isSwipingUp] : [isSwipingUp]
        for direction in directions {
            let style = direction == isSwipingUp
                ? gestureStyle
                : oppositeGestureStyle ?? gestureStyle
            guard style == .swipe || isValidRevealDrag(
                isSwipingUp: direction,
                startX: startX,
                startY: direction == isSwipingUp ? startY : oppositeStartY,
                dragDistance: dragDistance
            ) else {
                try stopWithDiagnostics("露出元素的拖曳座標或距離無效", file: file, line: line)
            }
            if style == .slowDrag && (!holdDuration.isFinite || holdDuration < 0) {
                try stopWithDiagnostics("露出元素的拖曳停留秒數無效", file: file, line: line)
            }
        }

        for direction in directions {
            var previousSignature = waitForStableRevealSignature(
                in: container,
                sampling: signatureElements,
                timeout: min(timeout, 3)
            )
            for _ in 0..<max(maxGestures, 0) {
                let directionGestureStyle = direction == isSwipingUp
                    ? gestureStyle
                    : oppositeGestureStyle ?? gestureStyle
                let directionStartY = direction == isSwipingUp ? startY : oppositeStartY
                performRevealGesture(
                    in: container,
                    isSwipingUp: direction,
                    startX: startX,
                    startY: directionStartY,
                    dragDistance: dragDistance,
                    gestureStyle: directionGestureStyle,
                    holdDuration: holdDuration
                )
                let currentSignature = waitForStableRevealSignature(
                    in: container,
                    sampling: signatureElements,
                    timeout: min(timeout, 3)
                )

                if isRevealed(
                    element,
                    within: container,
                    requiresVisibleFrame: requiresVisibleFrame,
                    requiresFullVisibility: requiresFullVisibility,
                    requiresHittable: requiresHittable
                ) {
                    return
                }
                if let currentSignature, currentSignature == previousSignature {
                    break
                }
                previousSignature = currentSignature
            }
        }

        try stopWithDiagnostics("捲動後仍未露出目標元素", file: file, line: line)
    }
}

// MARK: - 私有捲動判定

/// 集中處理露出元素時的位置簽章、手勢與可見條件
@MainActor
private extension XCUIApplication {

    /// 判斷元素是否符合呼叫端指定的可見條件
    ///
    /// - Parameters:
    ///   - element: 要檢查的元素
    ///   - container: 元素所在的捲動容器
    ///   - requiresVisibleFrame: 是否要求元素框線與容器相交
    ///   - requiresFullVisibility: 是否要求元素框線完整落在容器內
    ///   - requiresHittable: 是否要求元素可點且框線穩定
    /// - Returns: 元素是否已符合可見條件
    func isRevealed(
        _ element: XCUIElement,
        within container: XCUIElement,
        requiresVisibleFrame: Bool,
        requiresFullVisibility: Bool,
        requiresHittable: Bool
    ) -> Bool {
        guard element.exists else {
            return false
        }
        if requiresVisibleFrame || requiresFullVisibility || requiresHittable {
            guard let elementFrame = element.snapshotFrame,
                  elementFrame.isUsableFrame,
                  let containerFrame = container.snapshotFrame,
                  containerFrame.isUsableFrame,
                  containerFrame.intersects(elementFrame) else {
                return false
            }
            if requiresFullVisibility && !containerFrame.contains(elementFrame) {
                return false
            }
        }
        guard requiresHittable else {
            return true
        }
        return element.isHittableOnScreen
            && element.waitUntilStableAndHittable(
                timeout: 1,
                sampleInterval: 0.2,
                requiredSamples: 2
            )
    }

    /// 依方向與手勢設定捲動容器一次
    ///
    /// - Parameters:
    ///   - container: 要捲動的容器
    ///   - isSwipingUp: 是否向上捲動
    ///   - startX: 拖曳起點的正規化 X 座標
    ///   - startY: 拖曳起點的正規化 Y 座標；未指定時依方向選擇
    ///   - dragDistance: 拖曳距離的正規化高度
    ///   - gestureStyle: 要使用的手勢
    ///   - holdDuration: 慢速拖曳後停留的秒數
    func performRevealGesture(
        in container: XCUIElement,
        isSwipingUp: Bool,
        startX: CGFloat,
        startY: CGFloat?,
        dragDistance: CGFloat,
        gestureStyle: RevealGestureStyle,
        holdDuration: TimeInterval
    ) {
        if gestureStyle == .swipe {
            if isSwipingUp {
                container.swipeUp()
            } else {
                container.swipeDown()
            }
            return
        }

        let originY = startY ?? (isSwipingUp ? 0.7 : 0.3)
        let destinationY = isSwipingUp ? originY - dragDistance : originY + dragDistance
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: originY))
        let end = container.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: destinationY))
        if gestureStyle == .slowDrag {
            start.press(
                forDuration: 0.1,
                thenDragTo: end,
                withVelocity: .slow,
                thenHoldForDuration: max(holdDuration, 0)
            )
        } else {
            start.press(forDuration: 0.1, thenDragTo: end)
        }
    }

    /// 確認慢速拖曳起點與終點位於容器的正規化範圍內
    ///
    /// - Parameters:
    ///   - isSwipingUp: 是否向上捲動
    ///   - startX: 拖曳起點的正規化 X 座標
    ///   - startY: 拖曳起點的正規化 Y 座標；未指定時依方向選擇
    ///   - dragDistance: 拖曳距離的正規化高度
    /// - Returns: 起點與終點是否都位於容器範圍內
    func isValidRevealDrag(
        isSwipingUp: Bool,
        startX: CGFloat,
        startY: CGFloat?,
        dragDistance: CGFloat
    ) -> Bool {
        guard startX.isFinite,
              (0...1).contains(startX),
              dragDistance.isFinite,
              dragDistance > 0 else {
            return false
        }
        let originY = startY ?? (isSwipingUp ? 0.7 : 0.3)
        let destinationY = isSwipingUp ? originY - dragDistance : originY + dragDistance
        return originY.isFinite
            && destinationY.isFinite
            && (0...1).contains(originY)
            && (0...1).contains(destinationY)
    }

    /// 等待捲動內容的位置連續兩次相同
    ///
    /// - Parameters:
    ///   - container: 要觀察的捲動容器
    ///   - sampling: 要相對容器取樣的元素
    ///   - timeout: 等待位置穩定的秒數
    /// - Returns: 穩定的位置簽章；逾時或沒有可取樣內容時為 `nil`
    func waitForStableRevealSignature(
        in container: XCUIElement,
        sampling elements: [XCUIElement],
        timeout: TimeInterval
    ) -> String? {
        var previous: String?
        var stableSignature: String?
        var matchingSamples = 0
        let isStable = Polling.wait(timeout: timeout, interval: 0.15) {
            guard let current = revealPositionSignature(in: container, sampling: elements) else {
                previous = nil
                matchingSamples = 0
                return false
            }
            matchingSamples = current == previous ? matchingSamples + 1 : 1
            previous = current
            guard matchingSamples >= 2 else {
                return false
            }
            stableSignature = current
            return true
        }
        return isStable ? stableSignature : nil
    }

    /// 組合容器內可見內容與呼叫端指定元素的位置簽章
    ///
    /// - Parameters:
    ///   - container: 要觀察的捲動容器
    ///   - elements: 要相對容器取樣的元素
    /// - Returns: 可比較的位置簽章；內容尚未建立時為 `nil`
    func revealPositionSignature(
        in container: XCUIElement,
        sampling elements: [XCUIElement]
    ) -> String? {
        let visibleContent = scrollPositionSignature(in: container)
        guard !elements.isEmpty,
              let containerFrame = container.snapshotFrame,
              containerFrame.isUsableFrame else {
            return visibleContent
        }
        let sampledFrames = elements.compactMap { element -> String? in
            guard let frame = element.snapshotFrame, frame.isUsableFrame else {
                return nil
            }
            let relativeFrame = frame.offsetBy(dx: -containerFrame.minX, dy: -containerFrame.minY)
            return "\(element.identifier)|\(relativeFrame)"
        }
        guard !sampledFrames.isEmpty else {
            return visibleContent
        }
        var signatures = sampledFrames
        if let visibleContent {
            signatures.insert(visibleContent, at: 0)
        }
        return signatures.joined(separator: "\n")
    }
}
