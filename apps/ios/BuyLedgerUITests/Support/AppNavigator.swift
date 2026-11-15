//
//  AppNavigator.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 吸收原生根分頁列與側邊欄兩種導覽呈現的差異
struct AppNavigator {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Nested Types

extension AppNavigator {

    /// 根分頁列或側邊欄的目前呈現模式
    enum RootPresentationMode: Equatable {

        /// 原生根分頁列
        case tabs

        /// 原生根側邊欄
        case sidebar
    }

    /// 分頁列與側邊欄共用的分頁 key
    enum Tab: CaseIterable {

        /// 總覽頁
        case dashboard

        /// 訂單頁
        case orders

        /// 開團頁
        case campaigns

        /// 分析頁
        case insights

        /// 更多頁
        case more

        /// 對應的 `identifierKey`，與 App 端 `RootTab` 同序
        var identifierKey: BLAccessibilityID.Root.Tab {
            switch self {
            case .dashboard:
                .dashboard

            case .orders:
                .orders

            case .campaigns:
                .campaigns

            case .insights:
                .insights

            case .more:
                .more
            }
        }
    }

    /// 根導覽的版面類別，依實際畫面判定
    enum RootLayout {

        /// 寬版面，側邊欄或頂部分頁列
        case regular

        /// 窄版面，底部分頁列
        case compact
    }
}

// MARK: - Computed Properties

@MainActor
extension AppNavigator {

    /// 側邊欄品牌標記是否存在，且其有效框線與目前視窗相交
    var isSidebarMarkerVisible: Bool {
        let marker = rootSidebarMarker
        guard marker.exists,
              let markerFrame = marker.snapshotFrame,
              let windowFrame = app.windows.firstMatch.snapshotFrame else {
            return false
        }
        let visibleFrame = markerFrame.intersection(windowFrame)
        return visibleFrame.isUsableFrame
    }
}

// MARK: - Internal Method

@MainActor
extension AppNavigator {

    /// 依已核實的根分頁語意 ID 切換到指定目的地，已選取時保留目前堆疊
    ///
    /// - Parameters:
    ///   - tab: 目標分頁
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func selectTab(
        _ tab: Tab,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let matchingTabs = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.Root.tab(tab.identifierKey))
            .allElementsBoundByIndex
        let isTabSelected = matchingTabs.contains { $0.isSelected && $0.isHittableOnScreen }
        if isTabSelected {
            return
        }
        try tapRootTab(tab, file: file, line: line)
    }

    /// 讀取目前根導覽的原生呈現模式
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 根分頁列或側邊欄的目前呈現模式
    /// - Throws: 根控制項不足或根導覽模式無法辨識時丟出測試錯誤
    /// - Note: 只用側邊欄品牌標記與五個根語意控制項判定，不推測 Orders 欄位模式
    func rootPresentationMode(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> RootPresentationMode {
        guard let mode = waitForRootPresentationMode(timeout: 10) else {
            try app.stopWithDiagnostics(
                """
                根導覽模式無法辨識：可見 Root.tab.* 數=\(visibleRootTabCount(timeout: 0))，\
                sidebar marker exists=\(rootSidebarMarker.exists)，\
                frame=\(String(describing: rootSidebarMarker.snapshotFrame))
                """,
                file: file,
                line: line
            )
        }
        return mode
    }

    /// 判定根導覽版面：側邊欄或頂部分頁列為 regular，底部分頁列為 compact
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 依實際畫面判定的根導覽版面
    /// - Throws: 根控制項或版面框線無法判定時丟出測試錯誤
    /// - Note: 只依側邊欄標記與五個根分頁的位置判定，不以裝置類型或系統版本推測
    func rootLayout(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> RootLayout {
        guard let mode = waitForRootPresentationMode(timeout: 10) else {
            try app.stopWithDiagnostics(
                "根導覽版面無法判定：可見 Root.tab.* 數=\(visibleRootTabCount(timeout: 0))",
                file: file,
                line: line
            )
        }
        if mode == .sidebar {
            return .regular
        }
        guard let windowFrame = app.windows.firstMatch.snapshotFrame,
              windowFrame.isUsableFrame else {
            try app.stopWithDiagnostics("根導覽版面無法判定：App 視窗框線無效", file: file, line: line)
        }
        let tabFrames = Tab.allCases.compactMap { tab in
            let element = rootTabElement(for: tab)
            return element.isHittableOnScreen ? element.snapshotFrame : nil
        }
        guard tabFrames.count == Tab.allCases.count else {
            try app.stopWithDiagnostics("根導覽版面無法判定：根分頁框線不完整", file: file, line: line)
        }
        if tabFrames.allSatisfy({ $0.midY < windowFrame.midY }) {
            return .regular
        }
        if tabFrames.allSatisfy({ $0.midY > windowFrame.midY }) {
            return .compact
        }
        try app.stopWithDiagnostics("根導覽版面無法判定：根分頁未落在視窗同一側", file: file, line: line)
    }

    /// 依語意 ID 點擊原生根分頁；分頁列溢出收不下目標時改由側邊欄點選
    ///
    /// - Parameters:
    ///   - tab: 要點選的根分頁
    ///   - timeout: 整次點擊的總逾時秒數，先短等與後續等待共用
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 根分頁或側邊欄備援路徑逾時不可用時丟出測試錯誤
    /// - Note: 目標先短等 1.5 秒；分頁列溢出時目標不會出現，不必等滿逾時
    func tapRootTab(
        _ tab: Tab,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let deadline = Date.now.addingTimeInterval(timeout)
        let resolution = rootTabResolution(for: tab)
        let element = resolution.element
        if element.waitUntilHittable(timeout: min(timeout, 1.5)) {
            if resolution.usesPositionalFallback {
                print("[BLUITest] root tab fallback used")
            }
            element.tap()
            return
        }
        if isTopTabBarPresented {
            try tapRootTabFromSidebar(tab, deadline: deadline, file: file, line: line)
            return
        }
        guard element.waitUntilHittable(timeout: remainingSeconds(until: deadline)) else {
            try app.stopWithDiagnostics(
                "找不到可互動的根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey))",
                file: file,
                line: line
            )
        }
        if resolution.usesPositionalFallback {
            print("[BLUITest] root tab fallback used")
        }
        element.tap()
    }

    /// 側邊欄收起時透過系統切換按鈕顯示側邊欄
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 根呈現模式或側邊欄切換路徑未就緒時丟出測試錯誤
    func revealSidebarIfCollapsed(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard let mode = waitForRootPresentationMode(timeout: 10) else {
            try app.stopWithDiagnostics("根導覽控制項未就緒，無法切換側邊欄", file: file, line: line)
        }
        if mode == .sidebar {
            return
        }

        guard let toggle = rootSidebarToggle() else {
            try app.stopWithDiagnostics("找不到唯一已觀測的原生根側邊欄切換按鈕", file: file, line: line)
        }
        guard toggle.waitUntilHittable(timeout: 10) else {
            try app.stopWithDiagnostics("原生根側邊欄切換按鈕不可點", file: file, line: line)
        }

        toggle.tap()
        guard waitForRootSidebarPresentation(timeout: 10) else {
            try app.stopWithDiagnostics(
                "點擊原生切換按鈕後，sidebar marker 與五個根目的地未同時出現",
                file: file,
                line: line
            )
        }
    }

    /// 查詢系統根側邊欄切換按鈕，只接受已觀測的精確 identifier
    ///
    /// - Returns: 唯一出現的切換按鈕；零個或多個候選時回傳 `nil`
    func rootSidebarToggle() -> XCUIElement? {
        let identifiers = [
            SystemAccessibilityID.sidebarToggleButtonAlternate,
            SystemAccessibilityID.sidebarToggleButton,
        ]
        let matches = identifiers.compactMap { identifier in
            let element = app.buttons[identifier].firstMatch
            return element.exists ? element : nil
        }
        guard matches.count == 1 else {
            return nil
        }
        return matches[0]
    }

    /// 等待側邊欄品牌標記存在且有效框線進入目前視窗
    ///
    /// - Parameter timeout: 等待標記出現並進入視窗的秒數
    /// - Returns: 標記是否在逾時前可見
    func waitForRootSidebarMarkerVisible(timeout: TimeInterval = 10) -> Bool {
        Polling.wait(timeout: timeout, interval: 0.1) {
            isSidebarMarkerVisible
        }
    }

    /// 等待五個根分頁語意元素可見後回傳目的地數
    ///
    /// - Parameter timeout: 等待根分頁目的地可見的秒數
    /// - Returns: 可見且可點的根分頁目的地數
    func visibleRootTabCount(timeout: TimeInterval = 10) -> Int {
        var visibleCount = 0
        // 超時時仍回傳最後一次觀察到的數量，供診斷訊息描述目前狀態
        _ = Polling.wait(timeout: timeout, interval: 0.1) { // 超時時保留最後觀察值供診斷
            visibleCount = Tab.allCases.reduce(into: 0) { count, tab in
                if rootTabElement(for: tab).isHittableOnScreen {
                    count += 1
                }
            }
            return visibleCount == Tab.allCases.count
        }
        return visibleCount
    }

    /// 依語意分頁 ID 取得原生根分頁元素，identifier 查無時依分頁列由左至右的順序退回
    ///
    /// - Parameter tab: 要查詢的根分頁
    /// - Returns: 使用已核實根分頁 identifier 的第一個相符元素；退回條件不成立時為不存在的元素
    /// - Note: 退回條件是五個根分頁都查無 identifier 且分頁列恰有五個按鈕，依宣告順序對應
    func rootTabElement(for tab: Tab) -> XCUIElement {
        rootTabResolution(for: tab).element
    }

    /// 解析根分頁元素與是否使用位置順序退回
    ///
    /// - Parameter tab: 要解析的根分頁
    /// - Returns: 根分頁元素與位置順序退回狀態
    func rootTabResolution(for tab: Tab) -> (element: XCUIElement, usesPositionalFallback: Bool) {
        let identifiedElement = app.descendants(matching: .any)[
            BLAccessibilityID.Root.tab(tab.identifierKey)
        ].firstMatch
        guard !identifiedElement.exists,
              !hasIdentifiedRootTab,
              let index = Tab.allCases.firstIndex(of: tab) else {
            return (identifiedElement, false)
        }
        let buttons = tabBarButtonsInLayoutOrder
        guard buttons.count == Tab.allCases.count else {
            return (identifiedElement, false)
        }
        return (buttons[index], true)
    }
}

// MARK: - Private Method

@MainActor
private extension AppNavigator {

    /// 根側邊欄的品牌標記，用於區別原生根分頁與側邊欄版面
    var rootSidebarMarker: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar].firstMatch
    }

    /// 頂部分頁列是否呈現：側邊欄未開，且可見的根分頁都位於視窗上半
    ///
    /// - Note: 不依 `rootLayout()`，分頁列溢出缺一個分頁時根版面無法判定
    var isTopTabBarPresented: Bool {
        guard !isSidebarMarkerVisible, let windowFrame = app.windows.firstMatch.snapshotFrame else {
            return false
        }
        let visibleTabFrames = Tab.allCases.compactMap { tab in
            let element = rootTabElement(for: tab)
            return element.isHittableOnScreen ? element.snapshotFrame : nil
        }
        return !visibleTabFrames.isEmpty
            && visibleTabFrames.allSatisfy { $0.midY < windowFrame.midY }
    }

    /// 五個根分頁是否有任一 identifier 可查到；有則分頁列按鈕已掛上 identifier，不退回版面順序
    var hasIdentifiedRootTab: Bool {
        Tab.allCases.contains {
            app.descendants(matching: .any)[BLAccessibilityID.Root.tab($0.identifierKey)].exists
        }
    }

    /// 分頁列按鈕依水平位置由左至右排列，沒有框線的按鈕不納入
    var tabBarButtonsInLayoutOrder: [XCUIElement] {
        app.tabBars.firstMatch.buttons.allElementsBoundByIndex
            .compactMap { button -> (element: XCUIElement, minX: CGFloat)? in
                guard let frame = button.snapshotFrame else {
                    return nil
                }
                return (element: button, minX: frame.minX)
            }
            .sorted { lhs, rhs in lhs.minX < rhs.minX }
            .map(\.element)
    }

    /// 等待五個根控制項與側邊欄標記形成可辨識的穩定模式
    ///
    /// - Parameter timeout: 等待根模式穩定的秒數
    /// - Returns: 根呈現模式；必要控制項缺失時回傳 `nil`
    func waitForRootPresentationMode(timeout: TimeInterval) -> RootPresentationMode? {
        var previousMode: RootPresentationMode?
        var stableMode: RootPresentationMode?
        let isStable = Polling.wait(timeout: timeout, interval: 0.1) {
            let tabCount = visibleRootTabCount(timeout: 0)
            if tabCount == Tab.allCases.count {
                let currentMode: RootPresentationMode = isSidebarMarkerVisible
                    ? .sidebar
                    : .tabs
                if currentMode == previousMode {
                    stableMode = currentMode
                    return true
                }
                previousMode = currentMode
            } else {
                previousMode = nil
            }
            return false
        }
        return isStable ? stableMode : nil
    }

    /// 頂部分頁列收不下目標分頁時展開側邊欄點選；點選後側邊欄仍開著就收回
    ///
    /// - Parameters:
    ///   - tab: 要點選的根分頁
    ///   - deadline: 整次點擊的截止時間，各步等待只用截止前剩餘的秒數
    /// - Throws: 側邊欄或目標分頁無法互動時丟出測試錯誤
    /// - Note: 不用 `revealSidebarIfCollapsed()`，它要求五個根分頁同時可見，分頁列溢出時不成立
    func tapRootTabFromSidebar(
        _ tab: Tab,
        deadline: Date,
        file: StaticString,
        line: UInt
    ) throws(UITestError) {
        guard let toggle = rootSidebarToggle(),
              toggle.waitUntilHittable(timeout: remainingSeconds(until: deadline)) else {
            try app.stopWithDiagnostics(
                "找不到可互動的根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey))",
                file: file,
                line: line
            )
        }
        toggle.tap()
        guard waitForRootSidebarMarkerVisible(timeout: remainingSeconds(until: deadline)) else {
            try app.stopWithDiagnostics(
                "找不到可互動的根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey))",
                file: file,
                line: line
            )
        }
        let resolution = rootTabResolution(for: tab)
        let element = resolution.element
        guard element.waitUntilHittable(timeout: remainingSeconds(until: deadline)) else {
            try app.stopWithDiagnostics(
                "找不到可互動的根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey))",
                file: file,
                line: line
            )
        }
        if resolution.usesPositionalFallback {
            print("[BLUITest] root tab fallback used")
        }
        element.tap()

        // 直向的浮動側邊欄點選後自行收起；橫向的常駐側邊欄仍開著，收回後分頁列回到點選前的呈現
        if waitForRootSidebarMarkerHidden(timeout: min(2, remainingSeconds(until: deadline))) {
            return
        }
        guard let collapse = rootSidebarToggle(),
              collapse.waitUntilHittable(timeout: remainingSeconds(until: deadline)) else {
            try app.stopWithDiagnostics(
                "點選根分頁後無法收起原生根側邊欄",
                file: file,
                line: line
            )
        }
        collapse.tap()
        guard waitForRootSidebarMarkerHidden(timeout: remainingSeconds(until: deadline)) else {
            try app.stopWithDiagnostics(
                "點選根分頁後無法收起原生根側邊欄",
                file: file,
                line: line
            )
        }
    }

    /// 計算到截止時間還剩的秒數，已過截止時為 0
    ///
    /// - Parameter deadline: 截止時間
    /// - Returns: 剩餘秒數，不為負值
    func remainingSeconds(until deadline: Date) -> TimeInterval {
        max(0, deadline.timeIntervalSinceNow)
    }

    /// 等待側邊欄品牌標記不再與視窗相交，到逾時為止
    ///
    /// - Parameter timeout: 等待側邊欄收起的秒數
    /// - Returns: 側邊欄是否在逾時前收起
    func waitForRootSidebarMarkerHidden(timeout: TimeInterval) -> Bool {
        Polling.wait(timeout: timeout, interval: 0.1) {
            !isSidebarMarkerVisible
        }
    }

    /// 等待側邊欄品牌標記與五個根目的地同時可見
    ///
    /// - Parameter timeout: 等待原生側邊欄呈現的秒數
    /// - Returns: 側邊欄模式是否在逾時前穩定出現
    func waitForRootSidebarPresentation(timeout: TimeInterval) -> Bool {
        var isPreviouslyVisible = false
        return Polling.wait(timeout: timeout, interval: 0.1) {
            let isVisible = isSidebarMarkerVisible
                && visibleRootTabCount(timeout: 0) == Tab.allCases.count
            if isVisible && isPreviouslyVisible {
                return true
            }
            isPreviouslyVisible = isVisible
            return false
        }
    }
}
