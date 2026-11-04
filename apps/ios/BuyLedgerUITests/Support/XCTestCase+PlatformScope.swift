//
//  XCTestCase+PlatformScope.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

// MARK: - Nested Types

private extension XCTestCase {

    /// Orders 前景內容的欄位呈現類別
    enum OrdersLayoutMode: Equatable {

        /// 清單與詳情同時可見且水平分離
        case sideBySide

        /// 只有一個可辨識的前景內容區域
        case collapsed
    }

    /// 清單與詳情欄的呈現類別，More 與開團共用
    enum ListDetailLayoutMode: Equatable {

        /// 清單與詳情同時可見且水平分離
        case sideBySide

        /// 清單與詳情只有其中一個可見
        case collapsed
    }
}

// MARK: - Internal Method

@MainActor
extension XCTestCase {

    /// 判斷 Orders 功能是否實際呈現清單與詳情並排
    ///
    /// - Parameter app: 受測 App
    /// - Returns: Orders 清單與詳情前景是否並排且不重疊
    func isRegularLayout(_ app: XCUIApplication) -> Bool {
        guard let mode = ordersLayoutMode(in: app) else {
            app.failWithDiagnostics("無法辨識 Orders 前景欄位：\(ordersLayoutDiagnostics(in: app))")
            return false
        }
        return mode == .sideBySide
    }

    /// 判斷 Orders 功能是否以 collapsed 導覽呈現
    ///
    /// - Parameter app: 受測 App
    /// - Returns: Orders 清單與詳情是否沒有同時並排
    func isCompactLayout(_ app: XCUIApplication) -> Bool {
        guard let mode = ordersLayoutMode(in: app) else {
            app.failWithDiagnostics("無法辨識 Orders 前景欄位：\(ordersLayoutDiagnostics(in: app))")
            return false
        }
        return mode == .collapsed
    }

    /// 判斷 More 功能是否實際呈現入口清單與目前工具並排
    ///
    /// - Parameter app: 受測 App
    /// - Returns: More 入口清單與目前工具是否並排且不重疊
    func isMoreRegularLayout(_ app: XCUIApplication) -> Bool {
        guard let mode = moreLayoutMode(in: app) else {
            app.failWithDiagnostics("無法辨識 More 前景欄位：\(moreLayoutDiagnostics(in: app))")
            return false
        }
        return mode == .sideBySide
    }

    /// 判斷 More 功能是否以收合導覽呈現 (入口清單與目前工具擇一可見)
    ///
    /// - Parameter app: 受測 App
    /// - Returns: More 入口清單與目前工具是否沒有同時並排
    func isMoreCompactLayout(_ app: XCUIApplication) -> Bool {
        guard let mode = moreLayoutMode(in: app) else {
            app.failWithDiagnostics("無法辨識 More 前景欄位：\(moreLayoutDiagnostics(in: app))")
            return false
        }
        return mode == .collapsed
    }

    /// 判斷開團功能是否實際呈現清單與詳情並排
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 開團清單與詳情是否並排且不重疊
    func isCampaignRegularLayout(_ app: XCUIApplication) -> Bool {
        guard let mode = campaignLayoutMode(in: app) else {
            app.failWithDiagnostics("無法辨識開團前景欄位")
            return false
        }
        return mode == .sideBySide
    }

    /// 判斷開團功能是否以收合導覽呈現 (清單與詳情擇一可見)
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 開團清單與詳情是否沒有同時並排
    func isCampaignCompactLayout(_ app: XCUIApplication) -> Bool {
        guard let mode = campaignLayoutMode(in: app) else {
            app.failWithDiagnostics("無法辨識開團前景欄位")
            return false
        }
        return mode == .collapsed
    }

    /// 取得位於視窗前景的 Orders 詳情錨點框線
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 詳情錨點與視窗的交集；皆不可見時為 `nil`
    /// - Note: 依摘要、導覽列更多按鈕、空狀態提示文字的順序取第一個可見者；橫向時摘要可能落在視窗外
    func foregroundOrdersDetailFrame(in app: XCUIApplication) -> CGRect? {
        let identifiers = [
            BLAccessibilityID.Orders.detailSummaryTile(.revenue),
            BLAccessibilityID.Orders.detailSummaryTile(.cost),
            BLAccessibilityID.Orders.detailSummaryTile(.profit),
            BLAccessibilityID.Orders.detailMoreButton,
        ]
        for identifier in identifiers {
            let element = app.descendants(matching: .any)[identifier].firstMatch
            if element.isHittableOnScreen, let frame = visibleFrame(of: element, in: app) {
                return frame
            }
        }

        let prompt = emptyStatePrompt(
            in: app,
            containerIdentifier: BLAccessibilityID.Orders.detailEmptyState
        )
        return visibleFrame(of: prompt, in: app)
    }
}

// MARK: - Private Method

@MainActor
private extension XCTestCase {

    /// 等待 Orders 的真實前景錨點穩定後判定欄位呈現
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待前景版面穩定的秒數
    /// - Returns: 可辨識的 Orders 欄位呈現；必要錨點缺失或重疊時回傳 `nil`
    func ordersLayoutMode(
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) -> OrdersLayoutMode? {
        let deadline = Date.now.addingTimeInterval(timeout)
        var previousMode: OrdersLayoutMode?
        var previousListFrame: CGRect?
        var previousDetailFrame: CGRect?

        while true {
            let listFrame = foregroundOrdersListFrame(in: app)
            let detailFrame = foregroundOrdersDetailFrame(in: app)
            let currentMode: OrdersLayoutMode?

            if let listFrame, let detailFrame {
                if listFrame.maxX <= detailFrame.minX || detailFrame.maxX <= listFrame.minX {
                    currentMode = .sideBySide
                } else if listFrame == previousListFrame, detailFrame == previousDetailFrame {
                    return nil
                } else {
                    currentMode = nil
                }
            } else if listFrame != nil || detailFrame != nil {
                currentMode = .collapsed
            } else {
                currentMode = nil
            }

            if let currentMode,
               currentMode == previousMode,
               listFrame == previousListFrame,
               detailFrame == previousDetailFrame {
                return currentMode
            }
            previousMode = currentMode
            previousListFrame = listFrame
            previousDetailFrame = detailFrame

            guard Date.now < deadline else {
                return nil
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
    }

    /// 取得位於視窗前景的 Orders 清單列或清單空狀態框線
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 可互動清單列或可見清單空狀態與視窗的交集
    func foregroundOrdersListFrame(in app: XCUIApplication) -> CGRect? {
        let rowPrefix = BLAccessibilityID.Orders.row(orderID: "")
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", rowPrefix)
        )
        for row in rows.allElementsBoundByIndex where row.isHittableOnScreen {
            if let frame = visibleFrame(of: row, in: app) {
                return frame
            }
        }

        let emptyState = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.listEmptyState
        ].firstMatch
        return visibleFrame(of: emptyState, in: app)
    }

    /// 取得元素框線與 App 視窗相交後的有效框線
    ///
    /// - Parameters:
    ///   - element: 要檢查的前景元素
    ///   - app: 受測 App
    /// - Returns: 有效可見框線；元素或視窗不存在時回傳 `nil`
    func visibleFrame(of element: XCUIElement, in app: XCUIApplication) -> CGRect? {
        guard element.exists,
              let elementFrame = element.snapshotFrame,
              let windowFrame = app.windows.firstMatch.snapshotFrame else {
            return nil
        }

        let clippedFrame = elementFrame.intersection(windowFrame)
        guard !clippedFrame.isNull,
              !clippedFrame.isInfinite,
              !clippedFrame.isEmpty,
              clippedFrame.minX.isFinite,
              clippedFrame.minY.isFinite,
              clippedFrame.maxX.isFinite,
              clippedFrame.maxY.isFinite else {
            return nil
        }
        return clippedFrame
    }

    /// 產生 Orders 前景欄位診斷，包含根容器、實際列、摘要錨點與空狀態提示文字
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 根容器、列和詳情錨點的存在、可互動狀態與框線
    func ordersLayoutDiagnostics(in app: XCUIApplication) -> String {
        let listRoot = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot].firstMatch
        let detailRootID = BLAccessibilityID.Orders.detailRoot
        let detailRoot = app.descendants(matching: .any)[detailRootID].firstMatch
        let firstRow = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                BLAccessibilityID.Orders.row(orderID: "")
            )
        )
            .firstMatch
        let summaryID = BLAccessibilityID.Orders.detailSummaryTile(.revenue)
        let summary = app.descendants(matching: .any)[summaryID].firstMatch
        let emptyStateID = BLAccessibilityID.Orders.detailEmptyState
        let detailEmptyState = app.descendants(matching: .any)[emptyStateID].firstMatch
        let emptyPrompt = emptyStatePrompt(in: app, containerIdentifier: emptyStateID)

        return """
        listRoot exists=\(listRoot.exists), \
        frame=\(String(describing: listRoot.snapshotFrame)); \
        row hittable=\(firstRow.isHittableOnScreen), \
        frame=\(String(describing: firstRow.snapshotFrame)); \
        detailRoot exists=\(detailRoot.exists), \
        frame=\(String(describing: detailRoot.snapshotFrame)); \
        summary hittable=\(summary.isHittableOnScreen), \
        frame=\(String(describing: summary.snapshotFrame)); \
        detailEmpty exists=\(detailEmptyState.exists), \
        frame=\(String(describing: detailEmptyState.snapshotFrame)); \
        emptyPrompt exists=\(emptyPrompt.exists), \
        frame=\(String(describing: emptyPrompt.snapshotFrame))
        """
    }

    /// 取得空狀態容器內第一個 StaticText (提示文字)，容器或提示文字缺席時回傳不存在的元素
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - containerIdentifier: 空狀態容器的 identifier
    /// - Returns: 提示文字元素，缺席時 `exists` 為 `false`
    /// - Note: 不退回容器本身；空狀態容器在 iPadOS 27 會延伸到清單欄底下，其框線不代表詳情欄
    func emptyStatePrompt(in app: XCUIApplication, containerIdentifier: String) -> XCUIElement {
        app.descendants(matching: .any)[containerIdentifier].firstMatch.staticTexts.firstMatch
    }

    /// 等待 More 的前景錨點穩定後判定入口清單與目前工具的呈現
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 可辨識的 More 欄位呈現；必要錨點缺失或重疊時回傳 `nil`
    func moreLayoutMode(in app: XCUIApplication) -> ListDetailLayoutMode? {
        listDetailLayoutMode(in: app) {
            foregroundMoreListFrame(in: $0)
        } detail: {
            foregroundMoreDetailFrame(in: $0)
        } detailRootExists: {
            moreDetailRoots(in: $0).contains {
                $0.element.exists
            }
        }
    }

    /// 等待清單與詳情的前景錨點穩定後判定欄位呈現
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待前景版面穩定的秒數
    ///   - list: 取得前景清單框線的方法，回傳 `nil` 表示清單不可見
    ///   - detail: 取得前景詳情框線的方法，回傳 `nil` 表示詳情錨點不可見
    ///   - detailRootExists: 判斷詳情根是否存在；存在但沒有錨點時不分類為收合
    /// - Returns: 可辨識的欄位呈現；必要錨點缺失或重疊時回傳 `nil`
    func listDetailLayoutMode(
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        list: (XCUIApplication) -> CGRect?,
        detail: (XCUIApplication) -> CGRect?,
        detailRootExists: (XCUIApplication) -> Bool = { _ in false }
    ) -> ListDetailLayoutMode? {
        let deadline = Date.now.addingTimeInterval(timeout)
        var previousMode: ListDetailLayoutMode?
        var previousListFrame: CGRect?
        var previousDetailFrame: CGRect?

        while true {
            let listFrame = list(app)
            let detailFrame = detail(app)
            let currentMode: ListDetailLayoutMode?

            if detailRootExists(app), detailFrame == nil {
                currentMode = nil
            } else if let listFrame, let detailFrame {
                if listFrame.maxX <= detailFrame.minX || detailFrame.maxX <= listFrame.minX {
                    currentMode = .sideBySide
                } else {
                    currentMode = nil
                }
            } else if listFrame != nil || detailFrame != nil {
                currentMode = .collapsed
            } else {
                currentMode = nil
            }

            if let currentMode,
               currentMode == previousMode,
               listFrame == previousListFrame,
               detailFrame == previousDetailFrame {
                return currentMode
            }
            previousMode = currentMode
            previousListFrame = listFrame
            previousDetailFrame = detailFrame

            guard Date.now < deadline else {
                return nil
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
    }

    /// 取得位於視窗前景且可互動的 More 入口列框線
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 入口列的可見框線；沒有可互動的入口列時為 `nil`
    /// - Note: 以可見的入口列為錨點，清單容器的可互動狀態不作判定依據
    func foregroundMoreListFrame(in app: XCUIApplication) -> CGRect? {
        let anchors = [
            BLAccessibilityID.More.row(.fx),
            BLAccessibilityID.More.row(.customers),
            BLAccessibilityID.More.row(.settings),
        ]
        for identifier in anchors {
            let row = app.descendants(matching: .any)[identifier].firstMatch
            if row.isHittableOnScreen, let frame = visibleFrame(of: row, in: app) {
                return frame
            }
        }
        return nil
    }

    /// 取得位於視窗前景的 More 目前工具根或未選取提示框線
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 目前工具根或未選取提示與視窗的交集；皆不可見時為 `nil`
    /// - Note: 未選取提示取空狀態內文字
    /// - Note: 工具根錨點最多取前 10 個文字與 10 個 cell
    func foregroundMoreDetailFrame(in app: XCUIApplication) -> CGRect? {
        let prompt = emptyStatePrompt(
            in: app,
            containerIdentifier: BLAccessibilityID.Common.detailEmptyState
        )
        if prompt.isHittableOnScreen, let frame = visibleFrame(of: prompt, in: app) {
            return frame
        }

        for root in moreDetailRoots(in: app) {
            let probe = firstVisibleMoreDetailAnchor(in: root.element, app: app)
            if let frame = probe.frame {
                return frame
            }
        }
        return nil
    }

    /// 從工具根的前 10 個文字與前 10 個 cell 取第一個可互動且位於視窗內的框線
    ///
    /// - Parameters:
    ///   - container: More 工具的詳情根容器
    ///   - app: 受測 App
    /// - Returns: 可見錨點框線與取樣元素數；找不到時框線為 `nil`
    func firstVisibleMoreDetailAnchor(
        in container: XCUIElement,
        app: XCUIApplication
    ) -> (frame: CGRect?, sampledElementCount: Int) {
        guard container.exists else {
            return (nil, 0)
        }

        var sampledElementCount = 0
        let queries = [container.staticTexts, container.cells]
        for query in queries {
            for index in 0..<10 {
                let element = query.element(boundBy: index)
                guard element.exists else {
                    break
                }
                sampledElementCount += 1
                guard element.isHittableOnScreen,
                      let frame = visibleFrame(of: element, in: app) else {
                    continue
                }
                return (frame, sampledElementCount)
            }
        }
        return (nil, sampledElementCount)
    }

    /// 取得 More 可呈現的工具根與識別碼
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 依工具順序排列的根識別碼與元素
    func moreDetailRoots(in app: XCUIApplication) -> [(identifier: String, element: XCUIElement)] {
        let identifiers = [
            BLAccessibilityID.Fx.root,
            BLAccessibilityID.Quote.root,
            BLAccessibilityID.Settings.root,
            BLAccessibilityID.Customers.listRoot,
            BLAccessibilityID.LookupManagement.root,
        ]
        return identifiers.map {
            (
                identifier: $0,
                element: app.descendants(matching: .any).matching(identifier: $0).firstMatch
            )
        }
    }

    /// More 欄位無法辨識時列出工具根與已取樣的錨點數
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 各工具根的存在狀態、錨點取樣數與可見框線
    func moreLayoutDiagnostics(in app: XCUIApplication) -> String {
        let rootDetails = moreDetailRoots(in: app).map { root in
            guard root.element.exists else {
                return "\(root.identifier) exists=false, sampled=0"
            }
            let probe = firstVisibleMoreDetailAnchor(in: root.element, app: app)
            return """
            \(root.identifier) exists=true, sampled=\(probe.sampledElementCount), \
            frame=\(String(describing: probe.frame))
            """
        }
        return rootDetails.joined(separator: "; ")
    }

    /// 等待開團的前景錨點穩定後判定清單與詳情的呈現
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 可辨識的開團欄位呈現；必要錨點缺失或重疊時回傳 `nil`
    func campaignLayoutMode(in app: XCUIApplication) -> ListDetailLayoutMode? {
        listDetailLayoutMode(in: app) {
            foregroundCampaignListFrame(in: $0)
        } detail: {
            foregroundCampaignDetailFrame(in: $0)
        }
    }

    /// 取得位於視窗前景且可互動的開團列框線，沒有可互動列時以列表空狀態為錨點
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 可互動開團列或可見列表空狀態與視窗的交集
    func foregroundCampaignListFrame(in app: XCUIApplication) -> CGRect? {
        let rowPrefix = BLAccessibilityID.Campaigns.row(campaignID: "")
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", rowPrefix)
        )
        for row in rows.allElementsBoundByIndex where row.isHittableOnScreen {
            if let frame = visibleFrame(of: row, in: app) {
                return frame
            }
        }

        let emptyState = app.descendants(matching: .any)[
            BLAccessibilityID.Campaigns.listEmptyState
        ].firstMatch
        return visibleFrame(of: emptyState, in: app)
    }

    /// 取得位於視窗前景的開團詳情錨點框線，依詳情摘要、導覽列更多按鈕、空狀態提示文字的順序取第一個可見者
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 詳情錨點與視窗的交集；皆不可見時為 `nil`
    func foregroundCampaignDetailFrame(in app: XCUIApplication) -> CGRect? {
        let identifiers = [
            BLAccessibilityID.Campaigns.detailSummary(.receivables),
            BLAccessibilityID.Campaigns.detailMoreButton,
        ]
        for identifier in identifiers {
            let element = app.descendants(matching: .any)[identifier].firstMatch
            if element.isHittableOnScreen, let frame = visibleFrame(of: element, in: app) {
                return frame
            }
        }

        let prompt = emptyStatePrompt(
            in: app,
            containerIdentifier: BLAccessibilityID.Common.detailEmptyState
        )
        if prompt.isHittableOnScreen, let frame = visibleFrame(of: prompt, in: app) {
            return frame
        }
        return nil
    }
}
