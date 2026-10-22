//
//  BLButtonStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 使用設計系統色彩與最小觸控高度的按鈕樣式
struct BLButtonStyle {

    // MARK: - Properties

    /// 是否已開啟「減少動態效果」
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 目前按鈕是否可用
    @Environment(\.isEnabled) private var isEnabled

    /// 按鈕的語意樣式
    let variant: Variant
}

// MARK: - Nested Types

extension BLButtonStyle {

    /// BuyLedger 支援的按鈕語意
    enum Variant {

        /// 主要操作
        case primary

        /// 次要操作
        case secondary

        /// 不帶背景的文字操作
        case plain
    }
}

// MARK: - ButtonStyle

extension BLButtonStyle: ButtonStyle {

    /// 回傳套用樣式後的按鈕內容
    ///
    /// - Parameter configuration: 按鈕目前的互動狀態
    /// - Returns: 套用樣式後的按鈕內容
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, variant == .plain ? 0 : 18)
            .frame(minHeight: BLHitTarget.minimum)
            .blTextStyle(.headline)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
            .opacity(opacity(isPressed: configuration.isPressed))
            // 縮放要在裁切之後，按下時圓角背景才會一起縮小
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - BuyLedger Button Styles

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

// MARK: - Private Method

private extension BLButtonStyle {

    /// 按鈕文字與圖示使用的色彩
    var foregroundColor: Color {
        switch variant {
        case .primary:
            .white

        case .secondary, .plain:
            .blAccent
        }
    }

    /// 按鈕背景使用的色彩
    var backgroundColor: Color {
        switch variant {
        case .primary:
            .blAccent

        case .secondary:
            .blFillTertiary

        case .plain:
            .clear
        }
    }

    /// 依按壓與啟用狀態決定不透明度
    ///
    /// - Parameter isPressed: 按鈕目前是否被按住
    /// - Returns: 套用於按鈕整體的不透明度
    func opacity(isPressed: Bool) -> Double {
        guard isEnabled else {
            return 0.4
        }
        return isPressed ? 0.72 : 1
    }
}

// MARK: - Preview

#Preview("按鈕樣式") {
    VStack(spacing: BLSpacing.medium) {
        Button("common.ui.label.primaryAction", systemImage: "plus") {
        }
            .buttonStyle(.blPrimary)

        Button("common.ui.label.secondaryAction", systemImage: "square.and.pencil") {
        }
            .buttonStyle(.blSecondary)

        Button("common.ui.label.textAction", systemImage: "arrow.clockwise") {
        }
            .buttonStyle(.blPlain)

        // 破壞性語意由 `role` 表達，樣式端不再提供破壞性變體
        Button("campaigns.general.label.deleteData", systemImage: "trash", role: .destructive) {
        }
            .buttonStyle(.blPlain)

        Button("common.ui.label.disabled", systemImage: "plus") {
        }
            .buttonStyle(.blPrimary)
            .disabled(true)
    }
    .padding()
}
