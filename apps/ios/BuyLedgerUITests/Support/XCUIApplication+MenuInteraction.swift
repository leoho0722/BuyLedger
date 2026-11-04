//
//  XCUIApplication+MenuInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 排除的選單觸發鈕 accessibility identifier，標籤回退時不可點擊觸發鈕本身或其子元素
private let excludedTriggerIdentifiers: Set<String> = [
    BLAccessibilityID.Orders.filterDateMenuButton,
    BLAccessibilityID.Orders.filterPaymentMethodMenuButton,
]

// MARK: - Internal Method

@MainActor
extension XCUIApplication {

    /// 點選單項目，可在 identifier 缺失時以可見標籤回退
    ///
    /// - Parameters:
    ///   - identifier: 選單項目的 accessibility identifier
    ///   - label: identifier 缺失時回退使用的可見標籤，預設為 `nil`
    ///   - timeout: 等待選單項目可互動的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否成功點選選單項目
    @discardableResult
    func tapMenuItem(
        _ identifier: String,
        label: String? = nil,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while true {
            let identifierQueries = queriesForIdentifier(identifier)
            if let item = firstHittableCandidate(in: identifierQueries) {
                item.tap()
                return true
            }

            if let label, !hasElement(withIdentifier: identifier) {
                let labelQueries = queriesForLabel(label)
                if let item = firstHittableCandidate(in: labelQueries, excludingTriggers: true) {
                    _ = item.waitUntilStableAndHittable(
                        timeout: 2,
                        sampleInterval: 0.2,
                        requiredSamples: 3
                    )
                    item.tap()
                    XCTContext.runActivity(
                        named: "選單項目以標籤回退：identifier \(identifier)，標籤 \(label)"
                    ) { _ in }
                    return true
                }
            }

            guard Date.now < deadline else {
                break
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }

        let status = hasElement(withIdentifier: identifier) ? "存在但不可點" : "不存在"
        let labelDesc = label.map { "\"\($0)\"" } ?? "未提供"
        failWithDiagnostics(
            """
            找不到或無法點擊選單項目 \
            (identifier: "\(identifier)" [\(status)], 標籤: \(labelDesc))
            """,
            file: file,
            line: line
        )
        return false
    }
}

// MARK: - Private Method

@MainActor
private extension XCUIApplication {

    /// 目前已呈現的原生選單或 Popover 容器
    var activeMenuContainers: [XCUIElement] {
        var containers: [XCUIElement] = []
        if menus.firstMatch.exists {
            containers.append(contentsOf: menus.allElementsBoundByIndex.filter(\.exists))
        }
        if popovers.firstMatch.exists {
            containers.append(contentsOf: popovers.allElementsBoundByIndex.filter(\.exists))
        }
        return containers
    }

    /// 畫面上現存選單觸發鈕的有效框線，供排除子元素判斷
    var activeTriggerFrames: [CGRect] {
        excludedTriggerIdentifiers.compactMap { identifier in
            let trigger = descendants(matching: .any)[identifier].firstMatch
            guard trigger.exists else {
                return nil
            }
            let frame = trigger.frame
            guard frame.origin.x.isFinite, frame.origin.y.isFinite, !frame.isEmpty else {
                return nil
            }
            return frame
        }
    }

    /// 依 identifier 建立查詢清單，優先查詢作用中的選單容器
    ///
    /// - Parameter identifier: 選單項目的 accessibility identifier
    /// - Returns: 依序排列的元素查詢清單
    func queriesForIdentifier(_ identifier: String) -> [XCUIElementQuery] {
        var queries: [XCUIElementQuery] = []
        let containers = activeMenuContainers
        for container in containers {
            queries.append(container.menuItems.matching(identifier: identifier))
            queries.append(container.buttons.matching(identifier: identifier))
            queries.append(container.descendants(matching: .any).matching(identifier: identifier))
        }
        queries.append(menuItems.matching(identifier: identifier))
        queries.append(buttons.matching(identifier: identifier))
        queries.append(descendants(matching: .any).matching(identifier: identifier))
        return queries
    }

    /// 在多組查詢中依序尋找第一個位於畫面上且可互動的候選元素
    ///
    /// - Parameters:
    ///   - queries: 要依序查詢的元素查詢清單
    ///   - excludingTriggers: 是否排除選單觸發鈕及其子元素
    /// - Returns: 第一個可互動的元素；若無則為 `nil`
    func firstHittableCandidate(
        in queries: [XCUIElementQuery],
        excludingTriggers: Bool = false
    ) -> XCUIElement? {
        let triggerFrames = excludingTriggers ? activeTriggerFrames : []
        for query in queries {
            let candidates = query.allElementsBoundByIndex
            for element in candidates where element.isHittableOnScreen {
                if excludingTriggers && isExcludedTrigger(element, triggerFrames: triggerFrames) {
                    continue
                }
                return element
            }
        }
        return nil
    }

    /// 檢查元素是否為排除的選單觸發鈕或其子元素
    ///
    /// - Parameters:
    ///   - element: 要檢查的候選元素
    ///   - triggerFrames: 目前有效的觸發鈕框線清單
    /// - Returns: 是否應排除此元素
    func isExcludedTrigger(_ element: XCUIElement, triggerFrames: [CGRect]) -> Bool {
        if excludedTriggerIdentifiers.contains(element.identifier) {
            return true
        }
        let frame = element.frame
        guard frame.origin.x.isFinite, frame.origin.y.isFinite, !frame.isEmpty else {
            return false
        }
        return triggerFrames.contains {
            $0.insetBy(dx: -1, dy: -1).contains(frame)
        }
    }

    /// 檢查是否有符合指定 identifier 的元素存在於畫面階層中
    ///
    /// - Parameter identifier: 選單項目的 accessibility identifier
    /// - Returns: 是否至少有一個符合的元素存在
    func hasElement(withIdentifier identifier: String) -> Bool {
        menuItems.matching(identifier: identifier).firstMatch.exists
            || buttons.matching(identifier: identifier).firstMatch.exists
            || descendants(matching: .any).matching(identifier: identifier).firstMatch.exists
    }

    /// 依可見標籤建立查詢清單，容器存在時限縮於容器內，無容器才退到全域
    ///
    /// - Parameter label: 選單項目的可見標籤
    /// - Returns: 依序排列的元素查詢清單
    func queriesForLabel(_ label: String) -> [XCUIElementQuery] {
        let predicate = NSPredicate(format: "label == %@", label)
        let containers = activeMenuContainers
        if !containers.isEmpty {
            return containers.flatMap {
                [
                    $0.menuItems.matching(predicate),
                    $0.buttons.matching(predicate),
                ]
            }
        }
        return [
            menuItems.matching(predicate),
            buttons.matching(predicate),
            descendants(matching: .any).matching(predicate),
        ]
    }
}
