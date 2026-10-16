//
//  DashboardKPITile.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 總覽的單一 KPI 卡片，由上而下是 `tint` 色點與標籤、大數字、變化指標
struct DashboardKPITile: View {

    // MARK: - Properties

    /// 目前的動態字級；用來在無障礙字級下允許數值換行
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 指標下方的變化說明，例如 `+18.2% MoM`；沒有上月比較值時改放其他補充文字
    let delta: LocalizedStringKey

    /// 指標的穩定識別值
    let kpi: BLAccessibilityID.Dashboard.KPI

    /// 卡片左上方的指標名稱，例如「營業額」、「毛利率」
    let label: String

    /// 左上方色點顏色，用來區分指標分類
    let tint: Color

    /// 變化指標相對上月的走向，決定變化率文字的顏色
    let trend: BLTrend

    /// 卡片中央顯示的數值字串 (已預先 format)
    let value: String

    // MARK: - Body

    /// 卡片骨架，合併成單一朗讀單位並以 identifier 供測試定位
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            header

            valueText

            deltaText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(.blSurface)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .overlay {
            border
        }
        // 保留合併朗讀，數值由 `accessibilityValue` 提供
        // 合併後子元素查不到，測試以卡片 identifier 定位後讀該元素的 value
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(value))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.kpiTile(kpi))
    }
}

// MARK: - Private Views

private extension DashboardKPITile {

    /// 左上方的 `tint` 色點與指標名稱
    var header: some View {
        HStack(spacing: 6) {
            // 純裝飾色點，語意已由標籤文字承載
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(label))
                .font(BLTypographyStyle.footnote.font.weight(.medium))
                .foregroundStyle(.blSecondaryLabel)
        }
    }

    /// 中段的大數字，無障礙字級允許換行
    var valueText: some View {
        Text(value)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.8)
            .blTextStyle(.title3Bold)
            .monospacedDigit()
            .foregroundStyle(.blLabel)
    }

    /// 下方的變化指標，依走向著色
    var deltaText: some View {
        Text(delta)
            .font(BLTypographyStyle.caption.font.weight(.medium))
            .foregroundStyle(deltaColor)
    }

    /// 卡片外緣 0.5 pt 的分隔線描邊，圓角與卡片裁切形狀一致
    var border: some View {
        RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
            .stroke(.blSeparator, lineWidth: 0.5)
    }
}

// MARK: - Private Method

private extension DashboardKPITile {

    /// 變化率文字的顏色，上升為綠、下降為紅，沒有上月資料可比時為三級文字色
    var deltaColor: Color {
        switch trend {
        case .up:
            return .blGreen

        case .down:
            return .blRed

        case .unavailable:
            return .blTertiaryLabel
        }
    }
}

// MARK: - Preview

#Preview("KPI 卡") {
    DashboardKPITile(
        delta: "+18.2% MoM",
        kpi: .revenue,
        label: "dashboard.overview.label.revenue",
        tint: .blAccent,
        trend: .up,
        value: "$53,780"
    )
    .padding()
}
