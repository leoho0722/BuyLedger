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

    /// App 根層依語言偏好注入的 locale
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
        .accessibilityValue(Text(profitDisplay(stats.profit)))
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

            Text(profitDisplay(stats.profit))
                .font(.system(size: heroProfitSize, weight: .bold))
                .monospacedDigit()
                // 無障礙字級允許換行，保留使用者設定的字級
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.7)

            HStack(spacing: BLSpacing.small) {
                Text(profitDeltaDisplay(stats.profitDelta))
                    .blTextStyle(.footnote)

                Text(verbatim: "·")

                Text(AppLanguage.format("dashboard.overview.label.orderCount", stats.orderCount, locale: locale))
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
            summary: sparklineSummary,
            axisXTitle: language.localized("orders.list.label.sequence"),
            axisYTitle: language.localized("orders.detail.label.value"),
            seriesName: language.localized("dashboard.overview.label.trendChart")
        ) {
            language.localizedString(forKey: "common.general.label.pointLd", $0)
        }
    }

    /// 月目標進度條；目標為 0 (使用者未設定) 時整列隱藏
    @ViewBuilder
    var goalProgressBar: some View {
        if stats.goal > 0 {
            let progress = stats.goalProgress

            HStack(spacing: BLSpacing.small) {
                // 軌道與文字固定使用白色
                ProgressView(value: progress)
                    .progressViewStyle(
                        BLProgressViewStyle(tint: .white, track: .white.opacity(0.25))
                    )

                Text(verbatim: "\(Int(progress * 100))% / \(BLFormatters.twd(stats.goal, locale: locale))")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Private Method

private extension DashboardHeroCard {

    /// 走勢圖的趨勢摘要，供輔助技術朗讀
    var sparklineSummary: LocalizedStringKey {
        let points = stats.sparkline
        guard points.count > 1,
              let first = points.first,
              let last = points.last,
              let lowest = points.min(),
              let highest = points.max() else {
            return "dashboard.overview.label.monthlyProfitTrend"
        }

        // 三個方向各自成句、不拼接片語：拼接的句子無法在其他語言正確重組
        let low = BLFormatters.twd(Decimal(lowest), locale: locale)
        let high = BLFormatters.twd(Decimal(highest), locale: locale)
        if last > first {
            return LocalizedStringKey(AppLanguage.format("dashboard.overview.accessibility.trendUp", points.count, low, high, locale: locale))
        }
        if last < first {
            return LocalizedStringKey(AppLanguage.format("dashboard.overview.accessibility.trendDown", points.count, low, high, locale: locale))
        }
        return LocalizedStringKey(AppLanguage.format("dashboard.overview.accessibility.trendFlat", points.count, low, high, locale: locale))
    }

    /// 將獲利金額格式化為含正負號的新台幣字串
    ///
    /// - Parameter profit: 獲利金額
    /// - Returns: 顯示在 hero 卡上的金額字串
    func profitDisplay(_ profit: Decimal) -> String {
        let formatted = BLFormatters.twd(profit, locale: locale)
        return profit > 0 ? "+\(formatted)" : formatted
    }

    /// 依 App 選定 locale 把獲利 delta 轉成 hero 卡上的 `↑ 24.3% MoM` 風格字串
    ///
    /// - Parameter delta: 成長率，例如 `0.243` 表示 +24.3%
    /// - Returns: hero 卡顯示用字串；無資料時顯示「— MoM」
    func profitDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let arrow = delta >= 0 ? "↑" : "↓"
        let magnitude = delta < 0 ? -delta : delta
        let formatted = BLFormatters.percent(magnitude, locale: locale)
        return "\(arrow) \(formatted) MoM"
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
