//
//  DashboardKPITiles.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 總覽的 KPI 卡區段：營業額、成本、毛利率與進行中訂單，可排成直欄或格狀
struct DashboardKPITiles: View {

    // MARK: - Properties

    /// 目前的動態字級；用來在無障礙字級下把格狀改為單欄
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// KPI 卡的排列方式：寬版與 hero 卡並排時為直欄，窄版接在 hero 卡下方時為格狀
    let arrangement: Arrangement

    /// 已計算的本月統計
    let stats: DashboardStats

    // MARK: - Body

    /// 依排列方式呈現直欄或格狀的 KPI 卡
    var body: some View {
        switch arrangement {
        case .column:
            columnTiles

        case .grid:
            gridTiles
        }
    }
}

// MARK: - Private Views

private extension DashboardKPITiles {

    /// 營業額與相對上月的變化率
    var revenueTile: some View {
        DashboardKPITile(
            delta: LocalizedStringKey(percentDeltaDisplay(stats.revenueDelta)),
            kpi: .revenue,
            label: "營業額",
            tint: palette.accent,
            trend: trend(for: stats.revenueDelta),
            value: BLFormatters.twd(stats.revenue, locale: locale)
        )
    }

    /// 成本與相對上月的變化率
    var costTile: some View {
        DashboardKPITile(
            delta: LocalizedStringKey(percentDeltaDisplay(stats.costDelta)),
            kpi: .cost,
            label: "成本",
            tint: palette.orange,
            trend: trend(for: stats.costDelta),
            value: BLFormatters.twd(stats.cost, locale: locale)
        )
    }

    /// 毛利率與相對上月的百分點差
    var grossMarginTile: some View {
        DashboardKPITile(
            delta: LocalizedStringKey(marginDeltaDisplay(stats.marginDelta)),
            kpi: .grossMargin,
            label: "毛利率",
            tint: palette.green,
            trend: trend(for: stats.marginDelta),
            value: BLFormatters.percent(stats.margin, locale: locale)
        )
    }

    /// 進行中訂單數，沒有上月比較值，變化指標改顯示件數
    var activeOrdersTile: some View {
        DashboardKPITile(
            delta: "\(stats.activeCount) 件進行中",
            kpi: .activeOrders,
            label: "進行中訂單",
            tint: palette.purple,
            trend: .unavailable,
            value: "\(stats.activeCount)"
        )
    }

    /// 直欄排列的 3 張 KPI 卡 (與 hero 等高呼應)，不含成本卡
    var columnTiles: some View {
        VStack(spacing: BLSpacing.small) {
            revenueTile

            grossMarginTile

            activeOrdersTile
        }
    }

    /// 格狀排列的 4 張 KPI 卡；無障礙字級改為單欄
    var gridTiles: some View {
        LazyVGrid(columns: Self.columns(for: dynamicTypeSize), spacing: BLSpacing.small) {
            revenueTile

            costTile

            grossMarginTile

            activeOrdersTile
        }
    }
}

// MARK: - Nested Types

extension DashboardKPITiles {

    /// KPI 卡區段的排列方式，依 hero 卡是並排還是堆疊決定
    enum Arrangement {

        /// 直欄排列，寬版與 hero 卡並排時使用
        case column

        /// 格狀排列，窄版接在 hero 卡下方；無障礙字級改為單欄
        case grid
    }
}

// MARK: - Internal Method

extension DashboardKPITiles {

    /// KPI 卡格的欄位設定；無障礙字級改為單欄
    ///
    /// - Parameter dynamicTypeSize: 目前的動態字級
    /// - Returns: 供 `LazyVGrid` 使用的欄位設定
    static func columns(for dynamicTypeSize: DynamicTypeSize) -> [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: BLSpacing.small), count: count)
    }
}

// MARK: - Private Method

private extension DashboardKPITiles {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 將 MoM 變化率格式化；nil 顯示「— MoM」
    ///
    /// - Parameter delta: 成長率，例如 `0.182` 表示 +18.2%
    /// - Returns: KPI 卡顯示用字串
    func percentDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let formatted = BLFormatters.percent(delta, locale: locale)
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) MoM"
    }

    /// 將 delta 數值轉成 KPI 卡的變化走向
    ///
    /// - Parameter delta: 成長率或百分點差
    /// - Returns: 大於或等於 0 為上升、小於 0 為下降，nil 代表無上月資料可比
    func trend(for delta: Decimal?) -> DashboardKPITile.Trend {
        guard let delta else {
            return .unavailable
        }
        return delta >= 0 ? .up : .down
    }

    /// 依 App 選定 locale 把毛利率 delta (百分點) 轉成 `+2.4 pt MoM` 風格字串
    ///
    /// - Parameter delta: 百分點差，例如 `0.024` 表示 +2.4pt
    /// - Returns: KPI 卡顯示用字串
    func marginDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let percentagePoints = delta * 100
        let formatted = percentagePoints.formatted(
            .number.precision(.fractionLength(1)).locale(locale)
        )
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) pt MoM"
    }
}

// MARK: - Preview

#Preview("KPI 卡格狀") {
    DashboardKPITiles(
        arrangement: .grid,
        stats: DashboardStats(
            orders: LedgerOrder.sampleOrders,
            monthlyGoal: 80_000,
            referenceDate: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
    )
    .padding()
}

#Preview("KPI 卡直欄") {
    DashboardKPITiles(
        arrangement: .column,
        stats: DashboardStats(
            orders: LedgerOrder.sampleOrders,
            monthlyGoal: 80_000,
            referenceDate: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
    )
    .padding()
}
