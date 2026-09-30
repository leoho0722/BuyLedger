//
//  BLBadge.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 顯示短文字或數量的徽章
struct BLBadge: View {

    // MARK: - Properties

    /// 徽章垂直內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var countVerticalPadding: CGFloat = 1

    /// 徽章水平內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var countHorizontalPadding: CGFloat = 7

    /// label 變體的垂直內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption2) private var labelVerticalPadding: CGFloat = 2

    /// label 變體的水平內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption2) private var labelHorizontalPadding: CGFloat = 6

    /// 徽章顯示的文字
    let text: String

    /// 徽章使用的語意狀態
    let tone: BLTone

    /// 徽章的尺寸與填色樣式
    let variant: Variant

    // MARK: - Init

    /// 建立徽章
    /// - Parameters:
    ///   - text: 徽章顯示的文字
    ///   - tone: 徽章使用的語意狀態
    ///   - variant: 徽章的尺寸與填色樣式
    init(
        _ text: String,
        tone: BLTone = .accent,
        variant: Variant = .label
    ) {
        self.text = text
        self.tone = tone
        self.variant = variant
    }

    // MARK: - Body

    /// 徽章的畫面內容
    var body: some View {
        badgeContent
    }
}

// MARK: - Private Views

private extension BLBadge {

    /// 徽章的文字、間距與背景呈現
    var badgeContent: some View {
        // label variant 傳固定中文詞時需本地化
        // count variant 的數字字串會 passthrough 不受影響
        Text(LocalizedStringKey(text))
            .padding(.vertical, variant == .count ? countVerticalPadding : labelVerticalPadding)
            .padding(
                .horizontal, variant == .count ? countHorizontalPadding : labelHorizontalPadding
            )
            .font(font.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: variant == .count ? BLRadius.pill : 4))
    }
}

// MARK: - Nested Types

extension BLBadge {

    /// 決定徽章的尺寸與填色方式
    enum Variant {

        /// 數量徽章
        case count

        /// 短文字標籤
        case label
    }
}

// MARK: - Computed Properties

private extension BLBadge {

    /// 根據尺寸與填色樣式決定顯示字體類型
    var font: Font {
        (variant == .count ? BLTypographyStyle.caption : BLTypographyStyle.caption2).font
    }

    /// 徽章文字使用的色彩
    var foregroundColor: Color {
        switch variant {
        case .count:
            tone.onIndicator
        case .label:
            tone.onSurface
        }
    }

    /// 徽章背景使用的色彩
    var backgroundColor: Color {
        switch variant {
        case .count:
            tone.indicator
        case .label:
            tone.background
        }
    }
}

// MARK: - Preview

#Preview("徽章") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        HStack(spacing: BLSpacing.small) {
            BLBadge("12", tone: .accent, variant: .count)
            BLBadge("3", tone: .destructive, variant: .count)
        }

        HStack(spacing: BLSpacing.small) {
            BLBadge("同步完成", tone: .success)
            BLBadge("待確認", tone: .warning)
            BLBadge("資訊", tone: .informative)
        }
    }
    .padding()
}
