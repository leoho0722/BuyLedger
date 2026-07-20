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
}

/// 使用設計系統色彩與最小觸控高度的按鈕樣式
struct BLButtonStyle: ButtonStyle {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 是否已開啟「減少動態效果」
    ///
    /// 動畫在來源處統一處理：新增任何動畫前都要先過這個判斷，而不是在各呼叫端各自關閉
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 目前按鈕是否可用
    ///
    /// 自繪背景的樣式必須自行讀取此值——否則停用的按鈕外觀與可用時完全相同，
    /// 使用者按下去沒反應卻沒有任何線索
    @Environment(\.isEnabled) private var isEnabled

    /// 按鈕的語意樣式
    let variant: BLButtonVariant

    // MARK: - View Body

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
            .opacity(opacity(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Private Method

private extension BLButtonStyle {

    /// 最小按鈕高度
    var minimumHeight: CGFloat { BLHitTarget.minimum }

    /// 依按壓與啟用狀態決定不透明度
    ///
    /// 與系統按鈕樣式一致：停用時整體降低不透明度
    /// - Parameter isPressed: 按鈕目前是否被按住
    /// - Returns: 套用於按鈕整體的不透明度
    func opacity(isPressed: Bool) -> Double {
        guard isEnabled else {
            return 0.4
        }
        return isPressed ? 0.72 : 1
    }

    /// 回傳按鈕前景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 按鈕文字與圖示使用的色彩
    func foregroundColor(palette: BLPalette) -> Color {
        switch variant {
        case .primary:
                .white
        case .secondary, .plain:
            palette.accent
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
        }
    }
}

// MARK: - Static Properties

extension ButtonStyle where Self == BLButtonStyle {

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

        // 破壞性語意由 role 表達，樣式端不再提供破壞性變體
        Button("刪除資料", systemImage: "trash", role: .destructive) {}
            .buttonStyle(.blPlain)

        Button("停用中", systemImage: "plus") {}
            .buttonStyle(.blPrimary)
            .disabled(true)
    }
    .padding()
}
