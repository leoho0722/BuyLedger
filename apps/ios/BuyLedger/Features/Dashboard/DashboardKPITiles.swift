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

    /// App 根層依語言偏好注入的 `locale`
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
            delta: LocalizedStringKey(
                DashboardFormatters.percentDelta(stats.revenueDelta, locale: locale)
            ),
            kpi: .revenue,
            label: "dashboard.overview.label.revenue",
            tint: .blAccent,
            trend: BLTrend(delta: stats.revenueDelta),
            value: BLFormatters.twd(stats.revenue, locale: locale)
        )
    }

    /// 成本與相對上月的變化率
    var costTile: some View {
        DashboardKPITile(
            delta: LocalizedStringKey(
                DashboardFormatters.percentDelta(stats.costDelta, locale: locale)
            ),
            kpi: .cost,
            label: "orders.detail.label.cost",
            tint: .blOrange,
            trend: BLTrend(delta: stats.costDelta),
            value: BLFormatters.twd(stats.cost, locale: locale)
        )
    }

    /// 毛利率與相對上月的百分點差
    var grossMarginTile: some View {
        DashboardKPITile(
            delta: LocalizedStringKey(
                DashboardFormatters.marginDelta(stats.marginDelta, locale: locale)
            ),
            kpi: .grossMargin,
            label: "orders.detail.label.grossMargin",
            tint: .blGreen,
            trend: BLTrend(delta: stats.marginDelta),
            value: BLFormatters.percent(stats.margin, locale: locale)
        )
    }

    /// 進行中訂單數，沒有上月比較值，變化指標改顯示件數
    var activeOrdersTile: some View {
        DashboardKPITile(
            delta: LocalizedStringKey(
                AppLanguage.format(
                    "dashboard.overview.label.activeCountInProgress",
                    stats.activeCount,
                    locale: locale
                )
            ),
            kpi: .activeOrders,
            label: "dashboard.overview.label.activeOrders",
            tint: .blPurple,
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
