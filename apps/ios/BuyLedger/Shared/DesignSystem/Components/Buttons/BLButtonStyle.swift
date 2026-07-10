//
//  BLButtonStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// BuyLedger 支援的按鈕語意
enum BLButtonVariant {

    // MARK: - Cases

    /// 主要操作
    case primary

    /// 次要操作
    case secondary

    /// 不帶背景的文字操作
    case plain

    /// 破壞性操作
    case destructive
}

/// 使用設計系統色彩與最小觸控高度的按鈕樣式
struct BLButtonStyle: ButtonStyle {

    // MARK: - Style Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 按鈕的語意樣式
    let variant: BLButtonVariant

    // MARK: - Style Body

    /// 回傳套用樣式後的按鈕內容
    func makeBody(configuration: Configuration) -> some View {
        let palette = BLTheme.palette(for: colorScheme)

        configuration.label
            .font(.headline)
            .foregroundStyle(foregroundColor(palette: palette))
            .frame(minHeight: minimumHeight)
            .padding(.horizontal, variant == .plain ? 0 : 18)
            .background(backgroundColor(palette: palette))
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Private Method

private extension BLButtonStyle {

    /// 最小按鈕高度
    var minimumHeight: CGFloat { 44 }

    /// 回傳按鈕前景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 按鈕文字與圖示使用的色彩
    func foregroundColor(palette: BLPalette) -> Color {
        switch variant {
        case .primary:
                .white
        case .secondary, .plain:
            palette.accent
        case .destructive:
            palette.red
        }
    }

    /// 回傳按鈕背景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 按鈕背景使用的色彩
    func backgroundColor(palette: BLPalette) -> Color {
        switch variant {
        case .primary:
            palette.accent
        case .secondary:
            palette.fillTertiary
        case .plain:
                .clear
        case .destructive:
            palette.red.opacity(0.14)
        }
    }
}

extension ButtonStyle where Self == BLButtonStyle {

    // MARK: - Static Properties

    /// 主要操作按鈕
    static var blPrimary: BLButtonStyle {
        BLButtonStyle(variant: .primary)
    }

    /// 次要操作按鈕
    static var blSecondary: BLButtonStyle {
        BLButtonStyle(variant: .secondary)
    }

    /// 純文字操作按鈕
    static var blPlain: BLButtonStyle {
        BLButtonStyle(variant: .plain)
    }

    /// 破壞性操作按鈕
    static var blDestructive: BLButtonStyle {
        BLButtonStyle(variant: .destructive)
    }
}

// MARK: - Preview

#Preview("按鈕樣式") {
    VStack(spacing: BLSpacing.medium) {
        Button("主要操作", systemImage: "plus") {}
            .buttonStyle(.blPrimary)

        Button("次要操作", systemImage: "square.and.pencil") {}
            .buttonStyle(.blSecondary)

        Button("純文字操作", systemImage: "arrow.clockwise") {}
            .buttonStyle(.blPlain)

        Button("刪除資料", systemImage: "trash") {}
            .buttonStyle(.blDestructive)
    }
    .padding()
}
