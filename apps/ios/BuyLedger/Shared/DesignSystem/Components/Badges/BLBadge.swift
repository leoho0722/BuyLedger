//
//  BLBadge.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 決定徽章的尺寸與填色方式
enum BLBadgeVariant {

    // MARK: - Cases

    /// 數量徽章
    case count

    /// 短文字標籤
    case label
}

/// 顯示短文字或數量的徽章
struct BLBadge: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 徽章顯示的文字
    let text: String

    /// 徽章使用的語意狀態
    let tone: BLTone

    /// 徽章的尺寸與填色樣式
    let variant: BLBadgeVariant

    // MARK: - Init

    /// 建立徽章
    /// - Parameters:
    ///   - text: 徽章顯示的文字
    ///   - tone: 徽章使用的語意狀態
    ///   - variant: 徽章的尺寸與填色樣式
    init(_ text: String, tone: BLTone = .accent, variant: BLBadgeVariant = .label) {
        self.text = text
        self.tone = tone
        self.variant = variant
    }

    // MARK: - View Body

    /// 徽章的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        // label variant 傳固定中文詞時需本地化
        // count variant 的數字字串會 passthrough 不受影響
        Text(LocalizedStringKey(text))
            .font(variant == .count ? .caption.weight(.bold) : .caption2.weight(.bold))
            .foregroundStyle(foregroundColor(palette: palette))
            .lineLimit(1)
            .padding(.vertical, variant == .count ? 1 : 2)
            .padding(.horizontal, variant == .count ? 7 : 6)
            .background(backgroundColor(palette: palette))
            .clipShape(RoundedRectangle(cornerRadius: variant == .count ? BLRadius.pill : 4))
            .monospacedDigit()
    }
}

// MARK: - Private Method

private extension BLBadge {

    /// 回傳徽章前景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 徽章文字使用的色彩
    func foregroundColor(palette: BLPalette) -> Color {
        switch variant {
        case .count:
                .white
        case .label:
            tone.foreground(in: palette)
        }
    }

    /// 回傳徽章背景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 徽章背景使用的色彩
    func backgroundColor(palette: BLPalette) -> Color {
        switch variant {
        case .count:
            tone.foreground(in: palette)
        case .label:
            tone.background(in: palette)
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
