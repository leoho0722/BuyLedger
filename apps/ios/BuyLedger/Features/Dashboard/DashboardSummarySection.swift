//
//  DashboardSummarySection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 總覽的本月摘要區段：hero 卡與 KPI 卡，寬版左右並排、窄版上下堆疊
struct DashboardSummarySection: View {

    // MARK: - Properties

    /// 目前版面分類，用來區分單欄的窄版與 hero 並排 KPI 的寬版
    @Environment(\.blLayoutClass) private var layoutClass

    /// App 目前選用的顯示語系
    let language: AppLanguage

    /// 已計算的本月統計
    let stats: DashboardStats

    // MARK: - Body

    /// 依版面分類選擇並排或堆疊排列
    var body: some View {
        if shouldUseWideHero {
            wideLayout
        } else {
            narrowLayout
        }
    }
}

// MARK: - Private Views

private extension DashboardSummarySection {

    /// 寬版排列：hero 卡在左，3 張 KPI 卡直排在右
    var wideLayout: some View {
        HStack(alignment: .top, spacing: BLSpacing.medium) {
            DashboardHeroCard(language: language, stats: stats)
                .frame(maxWidth: .infinity)

            DashboardKPITiles(arrangement: .column, stats: stats)
                .frame(maxWidth: 320)
        }
    }

    /// 窄版排列：hero 卡在上，KPI 卡以格狀排在下
    var narrowLayout: some View {
        VStack(spacing: BLSpacing.medium) {
            DashboardHeroCard(language: language, stats: stats)

            DashboardKPITiles(arrangement: .grid, stats: stats)
        }
    }
}

// MARK: - Private Method

private extension DashboardSummarySection {

    /// 是否採用 hero + 3 KPI 並排版面 (版面分類為 `regular`)
    var shouldUseWideHero: Bool {
        layoutClass == .regular
    }
}

// MARK: - Preview

#Preview("本月摘要") {
    DashboardSummarySection(
        language: .traditionalChinese,
        stats: DashboardStats(
            orders: LedgerOrder.sampleOrders,
            monthlyGoal: 80_000,
            referenceDate: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
    )
    .padding()
}
