//
//  ColorContrast.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI
import UIKit
@testable import BuyLedger

/// 依 WCAG 2.1 計算色彩對比比值的測試輔助工具
///
/// 半透明色彩要先與底色合成才有對比可言，因此所有 API 都要求呼叫端由上而下
/// 列出實際的圖層堆疊，不對「疊在什麼之上」做任何預設
enum ColorContrast {}

// MARK: - Nested Types

extension ColorContrast {

    /// 解析動態色彩時所處的外觀與對比情境
    enum Appearance: CaseIterable {

        // MARK: - Cases

        /// 淺色外觀
        case light

        /// 深色外觀
        case dark

        /// 淺色外觀且開啟提高對比
        case lightIncreasedContrast

        /// 深色外觀且開啟提高對比
        case darkIncreasedContrast
    }

    /// 已解析為 sRGB 分量的色彩
    struct Components: Equatable {

        // MARK: - Data Properties

        /// 紅色分量
        let red: Double

        /// 綠色分量
        let green: Double

        /// 藍色分量
        let blue: Double

        /// 不透明度
        let alpha: Double
    }
}

// MARK: - Internal Method

extension ColorContrast.Appearance {

    /// 對應此情境的 trait collection，供動態色彩解析使用
    var traitCollection: UITraitCollection {
        let isDark = self == .dark || self == .darkIncreasedContrast
        let isIncreased = self == .lightIncreasedContrast || self == .darkIncreasedContrast
        return UITraitCollection { mutable in
            mutable.userInterfaceStyle = isDark ? .dark : .light
            mutable.accessibilityContrast = isIncreased ? .high : .normal
        }
    }

    /// 對應此情境的設計系統色盤
    var palette: BLPalette {
        BLPalette(isDark: self == .dark || self == .darkIncreasedContrast)
    }
}

// MARK: - Internal Method

extension ColorContrast {

    /// 回傳前景色疊在指定圖層堆疊之上的對比比值
    /// - Parameters:
    ///   - foreground: 前景色，可帶透明度
    ///   - layers: 由上而下排列的背景圖層，最底層須為不透明色
    ///   - appearance: 解析動態色彩所用的外觀情境
    /// - Returns: WCAG 對比比值，範圍 1 至 21
    static func ratio(_ foreground: Color, on layers: [Color], appearance: Appearance) -> Double {
        let background = composite(layers, appearance: appearance)
        let front = blend(components(of: foreground, appearance: appearance), over: background)
        return ratio(luminance(of: front), luminance(of: background))
    }

    /// 回傳前景色疊在單一不透明底色之上的對比比值
    /// - Parameters:
    ///   - foreground: 前景色，可帶透明度
    ///   - background: 不透明的底色
    ///   - appearance: 解析動態色彩所用的外觀情境
    /// - Returns: WCAG 對比比值，範圍 1 至 21
    static func ratio(_ foreground: Color, on background: Color, appearance: Appearance) -> Double {
        ratio(foreground, on: [background], appearance: appearance)
    }

    /// 將色彩解析為指定情境下的 sRGB 分量
    /// - Parameters:
    ///   - color: 待解析的色彩，可為 asset catalog 具名資源等動態色彩
    ///   - appearance: 解析所用的外觀情境
    /// - Returns: 解析後的分量
    static func components(of color: Color, appearance: Appearance) -> Components {
        let resolved = UIColor(color).resolvedColor(with: appearance.traitCollection)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Components(
            red: clamp(Double(red)),
            green: clamp(Double(green)),
            blue: clamp(Double(blue)),
            alpha: clamp(Double(alpha))
        )
    }
}

// MARK: - Private Method

private extension ColorContrast {

    /// 由下而上合成圖層堆疊，回傳最終可見的底色分量
    static func composite(_ layers: [Color], appearance: Appearance) -> Components {
        var result: Components?
        for layer in layers.reversed() {
            let current = components(of: layer, appearance: appearance)
            if let base = result {
                result = blend(current, over: base)
            } else {
                result = current
            }
        }
        return result ?? Components(red: 1, green: 1, blue: 1, alpha: 1)
    }

    /// 以來源覆蓋 (source-over) 方式將前景合成到不透明底色上
    ///
    /// 合成在 gamma 空間進行，與 Core Animation 實際繪製一致
    static func blend(_ top: Components, over base: Components) -> Components {
        Components(
            red: top.red * top.alpha + base.red * (1 - top.alpha),
            green: top.green * top.alpha + base.green * (1 - top.alpha),
            blue: top.blue * top.alpha + base.blue * (1 - top.alpha),
            alpha: 1
        )
    }

    /// 回傳分量對應的 WCAG 相對亮度
    static func luminance(of components: Components) -> Double {
        0.2126 * linearized(components.red)
            + 0.7152 * linearized(components.green)
            + 0.0722 * linearized(components.blue)
    }

    /// 將 sRGB 分量轉為線性光強度
    static func linearized(_ channel: Double) -> Double {
        let value = clamp(channel)
        if value <= 0.03928 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }

    /// 回傳兩個相對亮度之間的對比比值
    static func ratio(_ first: Double, _ second: Double) -> Double {
        (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    /// 將數值限制在 0 至 1 之間，避免 extended sRGB 的超界分量污染計算
    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
