//
//  ContrastComplianceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// 承載資訊的文字在四種外觀情境下的對比下限
@MainActor
struct ContrastComplianceTests {

    // MARK: - Properties

    /// 承載資訊的文字對比下限
    private static let textFloor = 4.5

    /// 所有需要驗證的外觀情境
    private static let appearances = ColorContrast.Appearance.allCases

    /// 確認狀態膠囊文字疊在膠囊底色上，每種外觀情境都達到文字對比下限
    ///
    /// - Parameters:
    ///   - tone: 要驗證的語意色軌
    ///   - appearance: 要驗證的外觀情境
    @Test(arguments: BLTone.allCases, ColorContrast.Appearance.allCases)
    func onSurface_膠囊文字疊在膠囊底色_對比達文字下限(tone: BLTone, appearance: ColorContrast.Appearance) {
        // Given
        let text = tone.onSurface
        let background = tone.background

        // When
        let ratio = ColorContrast.ratio(text, on: background, appearance: appearance)

        // Then
        #expect(ratio >= Self.textFloor, "\(tone) 膠囊文字在 \(appearance) 下僅 \(ratio)")
    }

    /// 確認計數徽章數字疊在實心底色上，每種外觀情境都達到文字對比下限
    ///
    /// - Parameters:
    ///   - tone: 要驗證的語意色軌
    ///   - appearance: 要驗證的外觀情境
    @Test(arguments: BLTone.allCases, ColorContrast.Appearance.allCases)
    func onIndicator_計數徽章數字疊在實心底_對比達文字下限(tone: BLTone, appearance: ColorContrast.Appearance) {
        // Given
        let numeral = tone.onIndicator
        let indicator = tone.indicator

        // When
        let ratio = ColorContrast.ratio(numeral, on: indicator, appearance: appearance)

        // Then
        #expect(ratio >= Self.textFloor, "\(tone) 計數徽章數字在 \(appearance) 下僅 \(ratio)")
    }

    /// 確認表面文字疊在卡片表面上，每種外觀情境都達到文字對比下限
    ///
    /// - Parameters:
    ///   - tone: 要驗證的語意色軌
    ///   - appearance: 要驗證的外觀情境
    @Test(arguments: BLTone.allCases, ColorContrast.Appearance.allCases)
    func onSurface_文字疊在卡片表面_對比達文字下限(tone: BLTone, appearance: ColorContrast.Appearance) {
        // Given
        let text = tone.onSurface
        let surface = appearance.palette.surface

        // When
        let ratio = ColorContrast.ratio(text, on: surface, appearance: appearance)

        // Then
        #expect(ratio >= Self.textFloor, "\(tone) 表面文字疊在卡片上在 \(appearance) 下僅 \(ratio)")
    }

    /// 確認前三名的排名徽章數字疊在徽章底色與卡片上，每種外觀情境都達到文字對比下限
    ///
    /// - Parameters:
    ///   - rank: 要驗證的名次
    ///   - appearance: 要驗證的外觀情境
    @Test(arguments: [1, 2, 3], ColorContrast.Appearance.allCases)
    func numeral_排名徽章數字疊在底色_對比達文字下限(rank: Int, appearance: ColorContrast.Appearance) {
        // Given
        let style = CustomerRankBadgeStyle.style(forRank: rank)
        let palette = appearance.palette
        let numeral = style.numeral(in: palette)
        let layers = [style.background(in: palette), palette.surface]

        // When
        let ratio = ColorContrast.ratio(numeral, on: layers, appearance: appearance)

        // Then
        #expect(ratio >= Self.textFloor, "第 \(rank) 名徽章數字在 \(appearance) 下僅 \(ratio)")
    }

    /// 確認熱力圖各級數的數字疊在該級底色上，每種外觀情境都達到文字對比下限
    ///
    /// - Parameters:
    ///   - depth: 要驗證的熱力圖級數
    ///   - appearance: 要驗證的外觀情境
    @Test(arguments: BLHeatmapDepth.allCases, ColorContrast.Appearance.allCases)
    func numeral_熱力圖數字疊在底色_對比達文字下限(depth: BLHeatmapDepth, appearance: ColorContrast.Appearance) {
        // Given
        let numeral = depth.numeral
        let background = depth.background

        // When
        let ratio = ColorContrast.ratio(numeral, on: background, appearance: appearance)

        // Then
        #expect(ratio >= Self.textFloor, "熱力圖第 \(depth.rawValue) 級數字在 \(appearance) 下僅 \(ratio)")
    }

    /// 確認熱力圖相鄰兩級的底色對比至少 1.2，肉眼分得出深淺
    ///
    /// - Parameter appearance: 要驗證的外觀情境
    @Test(arguments: ColorContrast.Appearance.allCases)
    func background_相鄰熱力圖級數_底色可目視區分(appearance: ColorContrast.Appearance) {
        // Given
        let levels = BLHeatmapDepth.allCases

        // When
        let ratios = zip(levels, levels.dropFirst()).map { lower, upper in
            ColorContrast.ratio(lower.background, on: upper.background, appearance: appearance)
        }

        // Then
        for (index, ratio) in ratios.enumerated() {
            #expect(
                ratio >= 1.2,
                "熱力圖第 \(levels[index].rawValue) 與第 \(levels[index + 1].rawValue) 級底色在 \(appearance) 下僅差 \(ratio)"
            )
        }
    }

    /// 涵蓋色輪上八個代表色相與審查報告點名的黃綠區段，確認頭像的白色縮寫達到文字對比下限
    ///
    /// - Parameter hue: 要驗證的色相
    @Test(arguments: [0.0, 0.125, 0.166, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875])
    func gradientColors_代表色相的頭像漸層_白色縮寫達文字對比下限(hue: Double) {
        // Given
        let colors = BLAvatar.gradientColors(forHue: hue)

        // When
        let ratios = Self.appearances.map { appearance in
            colors.map {
                ColorContrast.ratio(.white, on: $0, appearance: appearance)
            }
        }

        // Then
        for (appearance, appearanceRatios) in zip(Self.appearances, ratios) {
            for ratio in appearanceRatios {
                #expect(ratio >= Self.textFloor, "色相 \(hue) 的頭像縮寫在 \(appearance) 下僅 \(ratio)")
            }
        }
    }

    /// 確認彩底主卡的白字疊在漸層兩端時，每種外觀情境都達到文字對比下限
    ///
    /// - Parameter appearance: 要驗證的外觀情境
    @Test(arguments: ColorContrast.Appearance.allCases)
    func gradientColors_彩底主卡漸層兩端_白字達文字對比下限(appearance: ColorContrast.Appearance) {
        // Given
        let ends = BLHeroCardBackground.gradientColors

        // When
        let ratios = ends.map {
            ColorContrast.ratio(.white, on: $0, appearance: appearance)
        }

        // Then
        for ratio in ratios {
            #expect(ratio >= Self.textFloor, "主卡白字在 \(appearance) 下對漸層端僅 \(ratio)")
        }
    }

    /// 確認每個具名色彩資源都真的解析到資源，沒有靜默回退成系統預設色
    ///
    /// - Parameter appearance: 要驗證的外觀情境
    @Test(arguments: ColorContrast.Appearance.allCases)
    func components_所有具名色彩資源_皆解析到資源而非系統預設色(appearance: ColorContrast.Appearance) {
        // Given
        let fallback = ColorContrast.components(
            of: Color("BLToneResourceThatDoesNotExist", bundle: .assets),
            appearance: appearance
        )
        var resources: [(name: String, color: Color)] = [
            (
                "BLRankBadgeFirstBackground",
                CustomerRankBadgeStyle.first.background(in: appearance.palette)
            ),
            ("BLHeroGradientStart", BLHeroCardBackground.gradientColors[0]),
            ("BLHeroGradientEnd", BLHeroCardBackground.gradientColors[1]),
        ]
        for tone in BLTone.allCases {
            resources.append(("\(tone) onSurface", tone.onSurface))
            resources.append(("\(tone) background", tone.background))
            resources.append(("\(tone) indicator", tone.indicator))
            resources.append(("\(tone) onIndicator", tone.onIndicator))
        }
        for depth in BLHeatmapDepth.allCases {
            resources.append(("熱力圖第 \(depth.rawValue) 級底色", depth.background))
            resources.append(("熱力圖第 \(depth.rawValue) 級數字", depth.numeral))
        }

        // When
        let resolved = resources.map {
            ($0.name, ColorContrast.components(of: $0.color, appearance: appearance))
        }

        // Then
        for (name, components) in resolved {
            #expect(components != fallback, "\(name) 在 \(appearance) 下回退為系統預設色，代表具名資源沒有解析到")
        }
    }

    /// 涵蓋改走次要標籤色的圖表軸標籤與區段標題，確認它疊在三種背景上都達到文字對比下限
    ///
    /// - Parameter appearance: 要驗證的外觀情境
    @Test(arguments: ColorContrast.Appearance.allCases)
    func secondaryLabel_疊在三種背景_對比達文字下限(appearance: ColorContrast.Appearance) {
        // Given
        let palette = appearance.palette
        let backgrounds = [palette.surface, palette.background, palette.secondaryBackground]

        // When
        let ratios = backgrounds.map {
            ColorContrast.ratio(palette.secondaryLabel, on: $0, appearance: appearance)
        }

        // Then
        for ratio in ratios {
            #expect(ratio >= Self.textFloor, "次要標籤色在 \(appearance) 下僅 \(ratio)")
        }
    }

    /// 確認兩個不同的姓名對應到不同的頭像色相
    @Test
    func hueValue_兩個不同姓名_色相不同() {
        // Given
        let firstName = "王小明"
        let secondName = "李大華"

        // When
        let firstHue = BLAvatar.hueValue(for: firstName)
        let secondHue = BLAvatar.hueValue(for: secondName)

        // Then
        #expect(firstHue != secondHue)
    }

    /// 確認 `Color.blSecondaryLabel` 縮寫在每種外觀情境都解析成色盤的次要標籤色
    ///
    /// - Parameter appearance: 要驗證的外觀情境
    @Test(arguments: ColorContrast.Appearance.allCases)
    func blSecondaryLabel_各外觀情境_與色盤次要標籤色分量相同(appearance: ColorContrast.Appearance) {
        // Given
        let secondaryLabel = appearance.palette.secondaryLabel

        // When
        let shorthand = ColorContrast.components(of: .blSecondaryLabel, appearance: appearance)
        let paletteValue = ColorContrast.components(of: secondaryLabel, appearance: appearance)

        // Then
        #expect(
            shorthand == paletteValue,
            "Color.blSecondaryLabel 在 \(appearance) 下與色盤次要標籤色分量不同：\(shorthand) vs \(paletteValue)"
        )
    }

    /// 確認側邊欄各訂單分組在每種外觀情境下使用互不相同的色相
    ///
    /// - Parameter appearance: 要驗證的外觀情境
    @Test(arguments: ColorContrast.Appearance.allCases)
    func sidebarHue_各分組狀態_色相互不相同(appearance: ColorContrast.Appearance) {
        // Given
        let palette = appearance.palette
        let statuses = SidebarSmartGroup.orderBrowsingCases.map(\.status)

        // When
        let components = statuses.map {
            ColorContrast.components(of: $0.sidebarHue(in: palette), appearance: appearance)
        }

        // Then
        for firstIndex in components.indices {
            for secondIndex in components.indices where secondIndex > firstIndex {
                #expect(
                    components[firstIndex] != components[secondIndex],
                    "\(statuses[firstIndex]) 與 \(statuses[secondIndex]) 在 \(appearance) 下的分組色相相同"
                )
            }
        }
    }
}
