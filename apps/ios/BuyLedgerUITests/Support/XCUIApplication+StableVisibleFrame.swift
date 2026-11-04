//
//  XCUIApplication+StableVisibleFrame.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

// MARK: - Nested Types

@MainActor
extension XCUIApplication {

    /// 同一份 accessibility snapshot 中的框線擷取結果
    struct SingleSnapshotFrames {

        /// 有效框線
        let frames: [String: CGRect]

        /// 缺少有效框線的 identifier
        let missingIdentifiers: [String]

        /// 重複或框線不一致的 identifier
        let duplicateIdentifiers: [String]
    }
}

// MARK: - Internal Method

/// 捲動元素並等待穩定框線的 UI 測試輔助方法
@MainActor
extension XCUIApplication {

    /// 從同一份根元素快照讀取多個 identifier 的有效框線
    ///
    /// - Parameters:
    ///   - identifiers: 必須出現在快照中的 accessibility identifier
    ///   - root: 包含目標元素的根元素
    /// - Returns: 有效框線、缺少與重複的 identifier
    /// - Throws: 根元素無法產生 accessibility snapshot 時丟出錯誤
    /// - Note: 同一 identifier 的多個有效框線僅在一框完整包含所有候選時採用外框
    ///   相同框線視為完整包含；其他多筆框線視為重複
    /// - Note: 有效框線存在時，identifier 出現次數多於有效框線數即列為重複
    func framesInSingleSnapshot(
        for identifiers: [String],
        within root: XCUIElement
    ) throws -> SingleSnapshotFrames {
        let snapshot = try root.firstMatch.snapshot()

        let requestedIdentifiers = Set(identifiers)
        var frames: [String: CGRect] = [:]
        var occurrenceCounts: [String: Int] = [:]
        var candidateFrames: [String: [CGRect]] = [:]
        var duplicateIdentifiers: Set<String> = []
        var pending = [snapshot]
        while let element = pending.popLast() {
            pending.append(contentsOf: element.children.reversed())
            let identifier = element.identifier
            guard requestedIdentifiers.contains(identifier) else {
                continue
            }
            occurrenceCounts[identifier, default: 0] += 1
            let frame = element.frame
            guard !frame.isNull,
                  !frame.isInfinite,
                  !frame.isEmpty,
                  frame.minX.isFinite,
                  frame.minY.isFinite,
                  frame.maxX.isFinite,
                  frame.maxY.isFinite else {
                continue
            }
            candidateFrames[identifier, default: []].append(frame)
        }

        for identifier in requestedIdentifiers {
            guard let candidates = candidateFrames[identifier], !candidates.isEmpty else {
                continue
            }
            let occurrenceCount = occurrenceCounts[identifier, default: 0]
            let outerFrame = candidates.first { candidate in
                candidates.allSatisfy {
                    candidate.contains($0)
                }
            }
            if occurrenceCount == candidates.count, let outerFrame {
                frames[identifier] = outerFrame
            } else {
                duplicateIdentifiers.insert(identifier)
            }
        }

        let missingIdentifiers = identifiers.filter { frames[$0] == nil }
        let duplicateIdentifierList = identifiers.filter { duplicateIdentifiers.contains($0) }
        return SingleSnapshotFrames(
            frames: frames,
            missingIdentifiers: missingIdentifiers,
            duplicateIdentifiers: duplicateIdentifierList
        )
    }

    /// 依元素框線選擇捲動方式，等待穩定後回傳可見框線
    ///
    /// - Parameters:
    ///   - element: 要讀取框線的元素
    ///   - container: 包含元素的捲動容器
    /// - Returns: 穩定且可見的元素框線；元素不可見或框線無效時為 `nil`
    /// - Note: 已可點的元素不捲動
    /// - Note: 已建立但不可點的元素先以輕拖避免慣性衝過頭
    /// - Note: 目標中心在容器上半部 (含被頂部導覽列蓋住) 時從 0.3 拖到 0.5，其餘使用預設的 0.7 到 0.5
    /// - Note: 輕拖後仍在容器下方或框線失效時才一般捲動
    /// - Note: 未建立的惰性列直接一般捲動
    func stableVisibleFrame(of element: XCUIElement, within container: XCUIElement) -> CGRect? {
        let elementFrame = element.snapshotFrame
        let containerFrame = container.snapshotFrame
        let isElementInView: Bool
        if element.isHittableOnScreen {
            isElementInView = true
        } else if let elementFrame {
            let isInUpperHalf = containerFrame.map { elementFrame.midY < $0.midY } ?? false
            let hasGentleScrollSucceeded: Bool
            if isInUpperHalf {
                hasGentleScrollSucceeded = scrollToHittableGently(
                    element,
                    within: container,
                    startY: 0.3,
                    endY: 0.5
                )
            } else {
                hasGentleScrollSucceeded = scrollToHittableGently(element, within: container)
            }

            let frameAfterGentleScroll = element.snapshotFrame
            let containerFrameAfterGentleScroll = container.snapshotFrame
            let isStillBelowContainer: Bool
            if let frameAfterGentleScroll, let containerFrameAfterGentleScroll {
                isStillBelowContainer = frameAfterGentleScroll.maxY
                    > containerFrameAfterGentleScroll.maxY
            } else {
                isStillBelowContainer = false
            }
            if !element.isHittableOnScreen, isStillBelowContainer || frameAfterGentleScroll == nil {
                isElementInView = scrollToHittable(element, within: container)
            } else {
                isElementInView = hasGentleScrollSucceeded
            }
        } else {
            isElementInView = scrollToHittable(element, within: container)
        }

        guard isElementInView,
              element.waitUntilStableAndHittable(
                timeout: 2,
                sampleInterval: 0.1,
                requiredSamples: 3
              ) else {
            return nil
        }
        return element.snapshotFrame
    }
}
