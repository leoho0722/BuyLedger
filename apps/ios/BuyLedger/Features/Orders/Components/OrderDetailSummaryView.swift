//
//  OrderDetailSummaryView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 窄欄財務摘要與寬欄三項指標卡片
struct OrderDetailSummaryView: View {

    // MARK: - Properties

    /// 系統選用的動態字級，用於無障礙字級下改採直排
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 指標標籤旁的裝飾色點尺寸，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var indicatorSize: CGFloat = 8

    /// 指標標籤與色點的間距，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var labelSpacing: CGFloat = 6

    /// 詳情採用的窄欄或寬欄版面
    let layout: OrderDetailView.OrderDetailLayout

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 詳情區段的畫面骨架
    var body: some View {
        switch layout {
        case .compact:
            profitCard

        case .wide:
            kpiThreeUp
        }
    }
}

// MARK: - Private Views

private extension OrderDetailSummaryView {

    /// 收款、成本與獲利摘要卡片
    var profitCard: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                profitSummary

                Divider()

                financialMetrics
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 獲利與毛利率，無障礙字級下改為直排
    @ViewBuilder
    var profitSummary: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                profitValues
            }
        } else {
            HStack(alignment: .bottom) {
                profitValues
            }
        }
    }

    /// 獲利與毛利率共用的文字內容
    @ViewBuilder
    var profitValues: some View {
        let summary = order.summary
        let profitValue = OrderFormatters.signedTWD(summary.profit, locale: locale)

        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("獲利")
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)

            Text(profitValue)
                .blTextStyle(.largeTitle)
                .foregroundStyle(summary.profit >= 0 ? palette.green : palette.red)
                .monospacedDigit()
        }
        // 合併朗讀，主要數值由 `accessibilityValue` 承載供 UI 測試讀取
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.profit))
        .accessibilityValue(profitValue)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer()
        }

        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: BLSpacing.extraSmall
        ) {
            Text("毛利率")
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)

            Text(OrderFormatters.marginPercent(summary, locale: locale))
                .blTextStyle(.title3Bold)
                .monospacedDigit()
        }
    }

    /// 收款、成本與手續費，無障礙字級下改為直排
    @ViewBuilder
    var financialMetrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                metricValues
            }
        } else {
            HStack {
                metricValues
            }
        }
    }

    /// 收款、成本與手續費共用的文字內容
    @ViewBuilder
    var metricValues: some View {
        let summary = order.summary
        let revenueValue = OrderFormatters.twd(summary.revenue, locale: locale)
        let costValue = OrderFormatters.twd(summary.totalCost, locale: locale)

        metric("總收款", value: revenueValue, palette: palette)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.revenue))
            .accessibilityValue(revenueValue)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer()
        }

        metric("總成本", value: costValue, palette: palette)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.cost))
            .accessibilityValue(costValue)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer()
        }

        metric("手續費", value: OrderFormatters.twd(summary.fees, locale: locale), palette: palette)
    }

    /// 寬欄版面的三項財務指標，無障礙字級下改為直排
    @ViewBuilder
    var kpiThreeUp: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                kpiTiles
            }
        } else {
            HStack(alignment: .top, spacing: BLSpacing.medium) {
                kpiTiles
            }
        }
    }

    /// 寬欄版面共用的收款、成本與獲利卡片
    @ViewBuilder
    var kpiTiles: some View {
        let summary = order.summary
        let revenueValue = OrderFormatters.twd(summary.revenue, locale: locale)
        let costValue = OrderFormatters.twd(summary.totalCost, locale: locale)
        let profitValue = OrderFormatters.signedTWD(summary.profit, locale: locale)

        kpiTile(
            label: "總收款",
            value: revenueValue,
            tint: palette.accent,
            palette: palette
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.revenue))
        .accessibilityValue(revenueValue)

        kpiTile(
            label: "總成本",
            value: costValue,
            tint: palette.orange,
            palette: palette
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.cost))
        .accessibilityValue(costValue)

        kpiTile(
            label: "獲利",
            value: profitValue,
            delta: OrderFormatters.marginPercent(summary, locale: locale),
            deltaTint: summary.profit >= 0 ? palette.green : palette.red,
            tint: summary.profit >= 0 ? palette.green : palette.red,
            palette: palette
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.profit))
        .accessibilityValue(profitValue)
    }

    /// 顯示單一 KPI 卡片
    ///
    /// - Parameters:
    ///   - label: 指標標題
    ///   - value: 主要數值
    ///   - delta: 副標數值，例如毛利率，可省略
    ///   - deltaTint: 副標數值的色彩，未指定時採中性色
    ///   - tint: 標籤前色點與主要數值的強調色
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 卡片 view
    @ViewBuilder
    func kpiTile(
        label: String,
        value: String,
        delta: String? = nil,
        deltaTint: Color? = nil,
        tint: Color,
        palette: BLPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            HStack(spacing: labelSpacing) {
                // 純裝飾色點，語意已由標籤文字承載
                Circle()
                    .frame(width: indicatorSize, height: indicatorSize)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(LocalizedStringKey(label))
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                    .foregroundStyle(palette.secondaryLabel)
            }

            Text(value)
                .blTextStyle(.title2)
                .monospacedDigit()
                .foregroundStyle(palette.label)

            if let delta {
                Text(delta)
                    .font(BLTypographyStyle.caption.font.weight(.medium))
                    .foregroundStyle(deltaTint ?? palette.tertiaryLabel)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                .stroke(palette.separator, lineWidth: 0.5)
        }
        // 合併為單一朗讀單位；裝飾色點已先排除
        .accessibilityElement(children: .combine)
    }

    /// 顯示單一財務指標
    ///
    /// - Parameters:
    ///   - title: 指標標題
    ///   - value: 指標值
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 指標 view
    @ViewBuilder
    func metric(_ title: String, value: String, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(LocalizedStringKey(title))
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)

            Text(value)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Private Method

private extension OrderDetailSummaryView {

    /// 依目前外觀取得的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    OrderDetailSummaryView(layout: .compact, order: LedgerOrder.sampleOrders[0])
}
