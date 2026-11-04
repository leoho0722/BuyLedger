//
//  ReadableWidthUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/2.
//

import CoreGraphics
import XCTest

/// 驗證 regular 根導覽下 More 商品類別與設定列的閱讀寬度
@MainActor
final class ReadableWidthUITests: BLUITestCase {

    // MARK: - Properties

    /// 商品類別列的最大閱讀寬度字面值 (單位：pt)
    private static let categoryReadableWidth: CGFloat = 640

    /// 設定列的最大閱讀寬度字面值 (單位：pt)
    private static let settingsReadableWidth: CGFloat = 680

    /// 閱讀欄兩側各自預留的最低空間字面值 (單位：pt)
    private static let minimumReadableSideMargin: CGFloat = 40

    /// 幾何量測容許誤差 (單位：pt)
    private static let frameTolerance: CGFloat = 1

    /// 驗證更多頁商品類別與設定表單分別使用 640 pt 與 680 pt 閱讀寬度
    ///
    /// - Throws: 導覽、版面或列框線寬度與置中位置不符合預期時丟出測試錯誤
    func testMoreReadableWidth_商品類別與設定_限寬並置中() throws {
        // Given
        let app = try launchRegularLandscapeApp()
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToMore(), in: app, "更多分頁未就緒")
        let navigator = AppNavigator(app: app)
        if navigator.isSidebarMarkerVisible {
            let sidebarToggle = try requireValue(
                navigator.rootSidebarToggle(),
                in: app,
                "根側邊欄已展開但找不到原生切換按鈕"
            )
            try requireCondition(
                sidebarToggle.waitUntilHittable(timeout: 10),
                in: app,
                "根側邊欄切換按鈕不可互動"
            )
            sidebarToggle.tap()
        }
        let rootLayoutAfterToggle = try requireValue(
            navigator.rootLayout,
            in: app,
            "側邊欄切換後根導覽版面無法判定"
        )
        let sidebarMarkerVisible = navigator.isSidebarMarkerVisible
        let visibleRootTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            rootLayoutAfterToggle == .regular
                && !sidebarMarkerVisible
                && visibleRootTabCount == 5,
            in: app,
            """
            根導覽應收起側邊欄並顯示五個原生分頁
            sidebar marker visible=\(sidebarMarkerVisible)，tabs=\(visibleRootTabCount)
            """
        )

        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root].firstMatch

        // When
        let categoryEntry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.categories)]
        categoryEntry.tapAfterWaiting(in: app, elementName: "商品類別入口")
        let lookup = LookupManagementScreen(app: app)

        // Then
        try requireCondition(lookup.waitUntilReady(), in: app, "商品類別頁未就緒")
        try requireDetailColumnRoom(
            leadingColumn: moreRoot,
            window: app.windows.firstMatch,
            readableWidth: Self.categoryReadableWidth,
            minimumSideMargin: Self.minimumReadableSideMargin,
            context: "商品類別詳情欄",
            app: app
        )
        try assertCenteredRow(
            lookup.itemRow(named: "美妝"),
            leadingColumn: moreRoot,
            expectedWidth: Self.categoryReadableWidth,
            context: "商品類別列",
            app: app
        )

        // When
        let settingsEntry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
        settingsEntry.tapAfterWaiting(in: app, elementName: "設定入口")
        let settings = SettingsScreen(app: app)

        // Then
        try requireCondition(settings.waitUntilReady(), in: app, "設定表單未就緒")
        try requireDetailColumnRoom(
            leadingColumn: moreRoot,
            window: app.windows.firstMatch,
            readableWidth: Self.settingsReadableWidth,
            minimumSideMargin: Self.minimumReadableSideMargin,
            context: "設定詳情欄",
            app: app
        )
        try assertCenteredRow(
            app.descendants(matching: .any)[BLAccessibilityID.Settings.defaultCurrencyRow],
            leadingColumn: moreRoot,
            expectedWidth: Self.settingsReadableWidth,
            context: "設定預設幣別列",
            app: app
        )
        try rotateToPortrait(app)
    }
}

// MARK: - Private Method

private extension ReadableWidthUITests {

    /// 啟動測試資料並確認根導覽為 regular 後轉向橫向
    ///
    /// - Returns: 已在橫向呈現的受測 App
    /// - Throws: 根畫面或根導覽版面無法判定時丟出測試錯誤
    func launchRegularLandscapeApp() throws -> XCUIApplication {
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽總覽頁未就緒")
        let rootLayout = try requireValue(
            AppNavigator(app: app).rootLayout,
            in: app,
            "根導覽版面無法判定"
        )
        try XCTSkipUnless(rootLayout == .regular, "閱讀寬度案例限 regular 根導覽")
        try rotateToLandscape(app)
        return app
    }

    /// 確認閱讀內容所在詳情欄寬於閱讀上限與兩側最低邊距總和
    ///
    /// - Parameters:
    ///   - leadingColumn: 更多入口清單欄
    ///   - window: App 視窗
    ///   - readableWidth: 預期閱讀寬度上限
    ///   - minimumSideMargin: 詳情欄兩側各自需要的最小空間
    ///   - context: 失敗診斷中的詳情欄描述
    ///   - app: 受測 App
    /// - Throws: 欄位框線無效或可用寬度不足時丟出測試錯誤
    func requireDetailColumnRoom(
        leadingColumn: XCUIElement,
        window: XCUIElement,
        readableWidth: CGFloat,
        minimumSideMargin: CGFloat,
        context: String,
        app: XCUIApplication
    ) throws {
        let leadingFrame = try requireValidFrame(of: leadingColumn, in: app, context: "更多入口清單欄")
        let windowFrame = try requireValidFrame(of: window, in: app, context: "App 視窗")
        let detailWidth = windowFrame.maxX - leadingFrame.maxX
        let requiredWidth = readableWidth + minimumSideMargin * 2
        try requireCondition(
            detailWidth > requiredWidth,
            in: app,
            """
            \(context) 可用寬度應大於 \(requiredWidth) pt，實際 \(detailWidth) pt
            入口欄=\(leadingFrame)，視窗=\(windowFrame)
            """
        )
    }

    /// 確認前景列在更多入口欄與視窗右緣之間限寬並置中
    ///
    /// - Parameters:
    ///   - row: 要量測的清單或表單列
    ///   - leadingColumn: 更多入口清單欄
    ///   - expectedWidth: 預期列寬 (單位：pt)
    ///   - context: 失敗診斷中的列描述
    ///   - app: 受測 App
    /// - Throws: 必要列或容器框線無效、列寬或置中位置不符時丟出測試錯誤
    func assertCenteredRow(
        _ row: XCUIElement,
        leadingColumn: XCUIElement,
        expectedWidth: CGFloat,
        context: String,
        app: XCUIApplication
    ) throws {
        let rowFrame = try requireHittableFrame(of: row, in: app, context: context)
        let leadingFrame = try requireValidFrame(of: leadingColumn, in: app, context: "更多入口清單欄")
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "App 視窗"
        )
        let leadingGap = rowFrame.minX - leadingFrame.maxX
        let trailingGap = windowFrame.maxX - rowFrame.maxX
        let diagnostics = """
            列框線：\(rowFrame)，入口欄：\(leadingFrame)，視窗：\(windowFrame)
            左間距：\(leadingGap)，右間距：\(trailingGap)
            """

        try requireCondition(
            abs(rowFrame.width - expectedWidth) <= Self.frameTolerance,
            in: app,
            "\(context) 寬度應為 \(expectedWidth) pt，實際 \(rowFrame.width) pt\n\(diagnostics)"
        )
        try requireCondition(
            leadingGap >= -Self.frameTolerance && trailingGap >= -Self.frameTolerance,
            in: app,
            "\(context) 應完整位於入口欄與視窗右緣之間\n\(diagnostics)"
        )
        try requireCondition(
            abs(leadingGap - trailingGap) <= Self.frameTolerance,
            in: app,
            "\(context) 左右間距應相等\n\(diagnostics)"
        )
    }
}
