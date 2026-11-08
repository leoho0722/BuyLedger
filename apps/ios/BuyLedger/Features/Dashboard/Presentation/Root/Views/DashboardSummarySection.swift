//
//  DashboardSummarySection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 總覽的本月摘要區段，固定依序呈現 hero 卡與完整 KPI 格
struct DashboardSummarySection: View {

    // MARK: - Properties

    /// 已計算的本月統計
    let stats: DashboardStats

    // MARK: - Body

    /// 先顯示本月摘要，再依動態字級排列四項 KPI
    var body: some View {
        VStack(spacing: BLSpacing.medium) {
            DashboardHeroCard(stats: stats)

            DashboardKPITiles(stats: stats)
        }
    }
}

// MARK: - Preview

#Preview("本月摘要") {
    DashboardSummarySection(
        stats: DashboardStats(
            orders: LedgerOrder.sampleOrders,
            monthlyGoal: 80_000,
            referenceDate: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
    )
    .padding()
}
