//
//  DashboardAdaptiveLayoutUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 總覽在不同字級與寬版視窗下的自適應版面 UI 測試，涵蓋 KPI 數值一致與閱讀區置中
@MainActor
final class DashboardAdaptiveLayoutUITests: BLUITestCase {

    /// 驗證同一份資料在標準與輔助字級下，總覽四項 KPI 數值一致且成本指標存在
    ///
    /// - Throws: 總覽 KPI 未就緒、數值為空白、成本缺失或數值不一致時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L1
    /// - Note: 兩次啟動使用相同 seed
    func testKpiValue_標準與輔助字級_四項數值一致且成本存在() throws {
        // Given
        let requiredKPIs: [BLAccessibilityID.Dashboard.KPI] = [
            .revenue,
            .cost,
            .grossMargin,
            .activeOrders,
        ]
        let standardApp = try launch(LaunchOptions(seed: .fullOrders))
        let standardValues = try readDashboardKPIValues(in: standardApp, required: requiredKPIs)

        // When
        standardApp.terminate()
        let accessibilityApp = try launch(
            LaunchOptions(
                seed: .fullOrders,
                contentSizeCategory: .accessibilityExtraExtraExtraLarge
            )
        )
        let accessibilityValues = try readDashboardKPIValues(
            in: accessibilityApp,
            required: requiredKPIs
        )

        // Then
        for kpi in requiredKPIs {
            let standardValue = standardValues[kpi] ?? "nil"
            let accessibilityValue = accessibilityValues[kpi] ?? "nil"
            try requireCondition(
                standardValues[kpi] == accessibilityValues[kpi],
                in: accessibilityApp,
                "\(kpi.rawValue) 輔助字級「\(accessibilityValue)」與標準字級「\(standardValue)」數值不一致"
            )
        }
    }

    /// 驗證寬版總覽的內容寬度小於可用寬度，且左右邊距一致，即閱讀區存在並置中
    ///
    /// - Throws: 根導覽、總覽 KPI 框線或置中條件不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L4
    /// - Note: 只斷言內容寬度受限與左右置中
    func testKpiTile_寬版總覽_內容未佔滿且左右等距() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .regular, "閱讀區上限只適用 regular 根導覽的寬版視窗")
        let dashboard = try DashboardScreen.open(in: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "總覽畫面未就緒")

        // When
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let kpis: [BLAccessibilityID.Dashboard.KPI] = [.revenue, .cost, .grossMargin, .activeOrders]
        var tileFrames: [CGRect] = []
        for kpi in kpis {
            tileFrames.append(try requireValue(
                app.stableVisibleFrame(of: dashboard.kpiTile(kpi), within: dashboard.rootElement),
                in: app,
                "KPI 卡 \(kpi.rawValue) 框線不可用"
            ))
        }

        // Then
        let contentMinX = try requireValue(tileFrames.map(\.minX).min(), in: app, "寬版總覽 KPI 卡框線為空")
        let contentMaxX = try requireValue(tileFrames.map(\.maxX).max(), in: app, "寬版總覽 KPI 卡框線為空")
        try requireCondition(
            contentMaxX - contentMinX < window.width,
            in: app,
            "寬版總覽內容寬度未受限，已佔滿視窗 (內容 \(contentMaxX - contentMinX)，視窗 \(window.width))"
        )
        let leadingMargin = contentMinX - window.minX
        let trailingMargin = window.maxX - contentMaxX
        try requireCondition(
            abs(leadingMargin - trailingMargin) <= 1,
            in: app,
            "寬版總覽內容未置中 (左邊距 \(leadingMargin)，右邊距 \(trailingMargin))"
        )
    }
}

// MARK: - Private Method

private extension DashboardAdaptiveLayoutUITests {

    /// 進入總覽並讀取指定 KPI 的顯示值，數值為空白或必要種類缺失時讓測試失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - required: 必須出現的 KPI 種類
    /// - Returns: 各 KPI 種類對應的顯示值
    /// - Throws: 總覽未就緒、數值為空白或必要 KPI 缺失時丟出測試錯誤
    func readDashboardKPIValues(
        in app: XCUIApplication,
        required: [BLAccessibilityID.Dashboard.KPI]
    ) throws(UITestError) -> [BLAccessibilityID.Dashboard.KPI: String] {
        let dashboard = try DashboardScreen.open(in: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "總覽畫面未就緒")
        var values: [BLAccessibilityID.Dashboard.KPI: String] = [:]
        for kpi in required {
            if let value = dashboard.kpiValue(kpi) {
                try requireCondition(
                    !value.allSatisfy(\.isWhitespace),
                    in: app,
                    "KPI \(kpi.rawValue) 顯示值為空白"
                )
                values[kpi] = value
            }
        }
        try requireCheckPassed(
            KPIPresenceCheck.verify(required: required, observed: Set(values.keys)),
            in: app
        )
        return values
    }
}
