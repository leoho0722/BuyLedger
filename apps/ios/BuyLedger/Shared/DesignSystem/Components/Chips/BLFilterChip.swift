//
//  BLFilterChip.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 篩選膠囊：訂單列表的狀態、日期、類別與付款方式篩選共用
struct BLFilterChip: View {

    // MARK: - Properties

    /// 目前的動態字級，判斷是否為無障礙字級
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 選用的前綴 SF Symbol 名稱
    var icon: String? = nil

    /// 是否撐滿可用寬度並允許換行 (trigger 類膠囊使用)
    var isExpanded: Bool = false

    /// 是否為選取狀態
    let isSelected: Bool

    /// 字級與水平內距的尺寸
    var size: Size = .standard

    /// 選取態的語意配色
    var style: Style = .inverted

    /// 膠囊顯示的文字
    let title: LocalizedStringKey

    /// 選用的尾端 SF Symbol 名稱
    var trailingIcon: String? = nil

    /// 點擊時的動作
    let action: () -> Void

    // MARK: - Body

    /// 篩選膠囊的畫面內容
    var body: some View {
        Button(action: action) {
            label
                // 命中區放在標籤內部才會擴大可點區域；形狀用 `capsule` 而非外接矩形
                // 否則相鄰膠囊的命中區會在圓角處重疊
                .frame(minHeight: BLHitTarget.minimum)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Private Views

private extension BLFilterChip {

    /// 膠囊的可見內容：圖示、文字與選取態配色
    @ViewBuilder
    var label: some View {
        HStack(
            alignment: isExpanded ? .firstTextBaseline : .center,
            spacing: BLSpacing.extraSmall
        ) {
            if let icon {
                Image(systemName: icon)
                    .font(iconFont)
            }

            titleText

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(iconFont)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, horizontalPadding)
        .foregroundStyle(selectionForeground)
        .background(selectionBackground)
        .clipShape(Capsule())
    }

    /// 膠囊文字：撐滿型允許換行並靠左，其餘維持單行自然寬度
    @ViewBuilder
    var titleText: some View {
        if isExpanded {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .font(titleFont)
        } else {
            Text(title)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .font(titleFont)
        }
    }
}

// MARK: - Nested Types

extension BLFilterChip {

    /// 膠囊選取態的語意配色
    enum Style {

        /// 以反白呈現選取 (狀態篩選)
        case inverted

        /// 以強調色呈現選取 (日期區間篩選)
        case accent

        /// 以輔助強調色呈現選取 (類別、付款方式與整合篩選)
        case purple
    }

    /// 膠囊的字級與水平內距
    enum Size {

        /// `.footnote` 加 12pt 水平內距 (regular 版面)
        case standard

        /// `.subheadline` 加 14pt 水平內距 (compact 版面)
        case large
    }
}

// MARK: - Private Method

private extension BLFilterChip {

    /// 膠囊的文字與圖示色彩，依選取態與選取配色決定
    var selectionForeground: Color {
        guard isSelected else {
            return .blSecondaryLabel
        }
        switch style {
        case .inverted:
            return .blBackground

        case .accent:
            return .blAccent

        case .purple:
            return .blPurple
        }
    }

    /// 膠囊的底色，依選取態與選取配色決定
    var selectionBackground: Color {
        guard isSelected else {
            return .blFillTertiary
        }
        switch style {
        case .inverted:
            return .blLabel

        case .accent:
            return .blAccent.opacity(0.18)

        case .purple:
            return .blPurple.opacity(0.18)
        }
    }

    /// 膠囊文字字級
    var titleFont: Font {
        switch size {
        case .standard:
            BLTypographyStyle.footnote.font.weight(.semibold)

        case .large:
            BLTypographyStyle.subhead.font.weight(.semibold)
        }
    }

    /// 膠囊圖示字級
    var iconFont: Font {
        switch size {
        case .standard:
            BLTypographyStyle.caption2.font.weight(.semibold)

        case .large:
            BLTypographyStyle.caption.font.weight(.semibold)
        }
    }

    /// 膠囊水平內距
    var horizontalPadding: CGFloat {
        switch size {
        case .standard:
            BLSpacing.medium

        case .large:
            14
        }
    }
}

// MARK: - Preview

#Preview("篩選膠囊") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        HStack(spacing: BLSpacing.small) {
            BLFilterChip(isSelected: true, title: "common.action.label.all") {
            }
            BLFilterChip(isSelected: false, title: "customers.list.label.quoting") {
            }
            BLFilterChip(
                icon: "calendar",
                isSelected: true,
                style: .accent,
                title: "orders.list.label.month"
            ) {
            }
        }

        BLFilterChip(
            icon: "line.3.horizontal.decrease",
            isExpanded: true,
            isSelected: false,
            size: .large,
            style: .purple,
            title: "篩選: 全部",
            trailingIcon: "chevron.down"
        ) {
        }
    }
    .padding()
}
