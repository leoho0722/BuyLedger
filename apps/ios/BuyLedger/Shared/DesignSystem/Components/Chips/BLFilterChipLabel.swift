//
//  BLFilterChipLabel.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import SwiftUI

/// 篩選膠囊共用的圖示、文字與配色，供按鈕與選單呈現
struct BLFilterChipLabel: View {

    // MARK: - Properties

    /// 目前的動態字級，判斷是否為無障礙字級
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 大尺寸膠囊的水平內距，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var largeHorizontalPadding: CGFloat = 14

    /// 膠囊垂直內距，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var verticalPadding: CGFloat = 7

    /// 選用的前綴 SF Symbol 名稱
    var icon: String? = nil

    /// 是否撐滿可用寬度並允許換行 (trigger 類膠囊使用)
    var isExpanded: Bool = false

    /// 是否為選取狀態
    let isSelected: Bool

    /// 字級與水平內距的尺寸
    var size: BLFilterChip.Size = .standard

    /// 選取態的語意配色
    var style: BLFilterChip.Style = .inverted

    /// 膠囊顯示的文字
    let title: LocalizedStringKey

    /// 選用的尾端 SF Symbol 名稱
    var trailingIcon: String? = nil

    // MARK: - Body

    /// 膠囊外觀與最小命中範圍，互動由呼叫端提供
    var body: some View {
        content
            .frame(minHeight: BLHitTarget.minimum)
            .contentShape(.capsule)
    }
}

// MARK: - Private Views

private extension BLFilterChipLabel {

    /// 膠囊的可見內容：圖示、文字與選取態配色
    var content: some View {
        HStack(
            alignment: isExpanded ? .firstTextBaseline : .center,
            spacing: BLSpacing.extraSmall
        ) {
            if let icon {
                Image(systemName: icon)
                    .font(iconFont)
                    .accessibilityHidden(true)
            }

            titleText

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(iconFont)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, verticalPadding)
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

// MARK: - Private Method

private extension BLFilterChipLabel {

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
            largeHorizontalPadding
        }
    }
}

// MARK: - Preview

#Preview("篩選膠囊標籤") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        HStack(spacing: BLSpacing.small) {
            BLFilterChipLabel(isSelected: true, title: "common.action.label.all")

            BLFilterChipLabel(isSelected: false, title: "customers.list.label.quoting")

            BLFilterChipLabel(
                icon: "calendar",
                isSelected: true,
                style: .accent,
                title: "orders.list.label.month"
            )
        }

        BLFilterChipLabel(
            icon: "creditcard",
            isExpanded: true,
            isSelected: true,
            size: .large,
            style: .purple,
            title: "orders.list.label.selectPaymentMethod",
            trailingIcon: "chevron.down"
        )
    }
    .padding()
}
