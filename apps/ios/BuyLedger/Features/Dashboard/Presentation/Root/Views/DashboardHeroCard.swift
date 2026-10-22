//
//  DashboardHeroCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 總覽的漸層 hero 卡：本月淨獲利、走勢圖與月目標進度
struct DashboardHeroCard: View {

    // MARK: - Properties

    /// 目前的動態字級；用來在無障礙字級下允許淨獲利換行
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// hero 淨獲利金額字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroProfitSize: CGFloat = 36

    /// App 目前選用的顯示語系
    let language: AppLanguage

    /// 已計算的本月統計
    let stats: DashboardStats

    // MARK: - Body

    /// 卡片骨架，由上而下是淨獲利摘要、走勢圖與月目標進度條
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            profitSummary

            sparkline

            goalProgressBar
        }
        .padding(BLSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 漸層上的文字固定使用白色
        .foregroundStyle(.white)
        // 使用低亮度漸層確保白字對比度
        .blHeroCardBackground()
        .blCardShadow()
        // 保留走勢圖與目標進度的個別朗讀內容
        // 淨獲利放入卡片值
        .accessibilityElement(children: .contain)
        .accessibilityValue(Text(DashboardFormatters.signedProfit(stats.profit, locale: locale)))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.kpiTile(.netProfit))
    }
}

// MARK: - Private Views

private extension DashboardHeroCard {

    /// 本月淨獲利、與上月的變化率及訂單筆數
    var profitSummary: some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            // 層級由字重與字級表達；不透明度降階會直接損害對比
            Text("dashboard.overview.label.monthNet")
                .font(BLTypographyStyle.footnote.font.weight(.medium))

            Text(DashboardFormatters.signedProfit(stats.profit, locale: locale))
                // 無障礙字級允許換行，保留使用者設定的字級
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.7)
                .font(.system(size: heroProfitSize, weight: .bold))
                .monospacedDigit()

            HStack(spacing: BLSpacing.small) {
                Text(DashboardFormatters.profitDelta(stats.profitDelta, locale: locale))
                    .blTextStyle(.footnote)

                Text(verbatim: "·")

                Text(
                    AppLanguage.format(
                        "dashboard.overview.label.orderCount",
                        stats.orderCount,
                        locale: locale
                    )
                )
                .blTextStyle(.footnote)
            }
        }
    }

    /// 近 12 個月的淨獲利走勢圖
    var sparkline: some View {
        BLSparkline(
            data: stats.sparkline,
            tint: .white,
            height: 36,
            axisXTitle: language.localized("orders.list.label.sequence"),
            axisYTitle: language.localized("orders.detail.label.value"),
            seriesName: language.localized("dashboard.overview.label.trendChart"),
            summary: DashboardFormatters.sparklineSummary(stats.sparkline, locale: locale)
        ) {
            language.localizedString(forKey: "common.general.label.pointLd", $0)
        }
    }

    /// 月目標進度條；目標為 0 (使用者未設定) 時整列隱藏
    @ViewBuilder
    var goalProgressBar: some View {
        if stats.goal > 0 {
            let progress = stats.goalProgress
            let goalText = DashboardFormatters.goalProgress(
                progress,
                goal: stats.goal,
                locale: locale
            )

            HStack(spacing: BLSpacing.small) {
                // 軌道與文字固定使用白色
                ProgressView(value: progress)
                    .progressViewStyle(
                        BLProgressViewStyle(tint: .white, track: .white.opacity(0.25))
                    )

                Text(verbatim: goalText)
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Preview

#Preview("hero 卡") {
    DashboardHeroCard(
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
