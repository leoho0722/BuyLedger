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
///
/// 涵蓋狀態膠囊、徽章、客戶排名徽章、熱力圖與頭像；圖形元素若旁有文字標籤則屬裝飾、
/// 不在此列 (詳見 design-system-color-contrast spec)
@MainActor
struct ContrastComplianceTests {

    // MARK: - Static Properties

    /// 承載資訊的文字對比下限
    static let textFloor = 4.5

    /// 所有需要驗證的外觀情境
    static let appearances = ColorContrast.Appearance.allCases

    // MARK: - Tests

    // MARK: 狀態膠囊與徽章

    @Test(arguments: BLTone.allCases, ColorContrast.Appearance.allCases)
    func statusPillLabelMeetsTheTextFloor(tone: BLTone, appearance: ColorContrast.Appearance) {
        let ratio = ColorContrast.ratio(tone.onSurface, on: tone.background, appearance: appearance)

        #expect(
            ratio >= Self.textFloor,
            "\(tone) 膠囊文字在 \(appearance) 下僅 \(ratio)"
        )
    }

    @Test(arguments: BLTone.allCases, ColorContrast.Appearance.allCases)
    func countBadgeNumeralMeetsTheTextFloor(tone: BLTone, appearance: ColorContrast.Appearance) {
        let ratio = ColorContrast.ratio(tone.onIndicator, on: tone.indicator, appearance: appearance)

        #expect(
            ratio >= Self.textFloor,
            "\(tone) 計數徽章數字在 \(appearance) 下僅 \(ratio)"
        )
    }

    @Test(arguments: BLTone.allCases, ColorContrast.Appearance.allCases)
    func surfaceTextRemainsLegibleOnTheCardSurface(
        tone: BLTone,
        appearance: ColorContrast.Appearance
    ) {
        let ratio = ColorContrast.ratio(
            tone.onSurface,
            on: appearance.palette.surface,
            appearance: appearance
        )

        #expect(
            ratio >= Self.textFloor,
            "\(tone) 表面文字疊在卡片上在 \(appearance) 下僅 \(ratio)"
        )
    }

    // MARK: 客戶排名徽章

    @Test(arguments: [1, 2, 3], ColorContrast.Appearance.allCases)
    func rankBadgeNumeralMeetsTheTextFloor(rank: Int, appearance: ColorContrast.Appearance) {
        let style = CustomerRankBadgeStyle.style(forRank: rank)
        let palette = appearance.palette
        let ratio = ColorContrast.ratio(
            style.numeral(in: palette),
            on: [style.background(in: palette), palette.surface],
            appearance: appearance
        )

        #expect(
            ratio >= Self.textFloor,
            "第 \(rank) 名徽章數字在 \(appearance) 下僅 \(ratio)"
        )
    }

    // MARK: 熱力圖

    @Test(arguments: BLHeatmapDepth.allCases, ColorContrast.Appearance.allCases)
    func heatmapNumeralMeetsTheTextFloor(
        depth: BLHeatmapDepth,
        appearance: ColorContrast.Appearance
    ) {
        let ratio = ColorContrast.ratio(depth.numeral, on: depth.background, appearance: appearance)

        #expect(
            ratio >= Self.textFloor,
            "熱力圖第 \(depth.rawValue) 級數字在 \(appearance) 下僅 \(ratio)"
        )
    }

    @Test(arguments: ColorContrast.Appearance.allCases)
    func adjacentHeatmapDepthsAreVisiblyDistinct(appearance: ColorContrast.Appearance) {
        let levels = BLHeatmapDepth.allCases
        for (lower, upper) in zip(levels, levels.dropFirst()) {
            let ratio = ColorContrast.ratio(lower.background, on: upper.background, appearance: appearance)

            #expect(
                ratio >= 1.2,
                "熱力圖第 \(lower.rawValue) 與第 \(upper.rawValue) 級底色在 \(appearance) 下僅差 \(ratio)"
            )
        }
    }

    // MARK: 頭像

    /// 涵蓋色輪上八個代表色相，含審查報告點名的黃綠區段
    @Test(arguments: [0.0, 0.125, 0.166, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875])
    func avatarInitialsMeetTheTextFloorAcrossHues(hue: Double) {
        for color in BLAvatar.gradientColors(forHue: hue) {
            for appearance in Self.appearances {
                let ratio = ColorContrast.ratio(.white, on: color, appearance: appearance)

                #expect(
                    ratio >= Self.textFloor,
                    "色相 \(hue) 的頭像縮寫在 \(appearance) 下僅 \(ratio)"
                )
            }
        }
    }

    // MARK: 總覽頁主卡

    /// 主卡文字為純白疊在漸層上；漸層兩端與其中點皆須達標
    @Test(arguments: ColorContrast.Appearance.allCases)
    func heroCardWhiteTextMeetsTheFloorOnBothGradientEnds(appearance: ColorContrast.Appearance) {
        let ends = [
            Color("BLHeroGradientStart", bundle: .assets),
            Color("BLHeroGradientEnd", bundle: .assets),
        ]
        for end in ends {
            let ratio = ColorContrast.ratio(.white, on: end, appearance: appearance)

            #expect(
                ratio >= Self.textFloor,
                "主卡白字在 \(appearance) 下對漸層端僅 \(ratio)"
            )
        }
    }

    // MARK: 具名色彩資源解析

    /// 具名色彩資源缺失時 SwiftUI 會靜默回退為系統預設色，不會有編譯或執行期警訊
    ///
    /// 對比斷言本身抓不到這種情形 (回退色之間仍可能達標)，故逐一比對「一定不存在的名稱」
    /// 所回退到的色值，確認每支資源都真的解析到了
    @Test(arguments: ColorContrast.Appearance.allCases)
    func everyNamedColorResourceActuallyResolves(appearance: ColorContrast.Appearance) {
        let fallback = ColorContrast.components(
            of: Color("BLToneResourceThatDoesNotExist", bundle: .assets),
            appearance: appearance
        )

        var resources: [(String, Color)] = [
            ("BLRankBadgeFirstBackground", CustomerRankBadgeStyle.first.background(in: appearance.palette)),
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

        for (name, color) in resources {
            #expect(
                ColorContrast.components(of: color, appearance: appearance) != fallback,
                "\(name) 在 \(appearance) 下回退為系統預設色，代表具名資源沒有解析到"
            )
        }
    }

    // MARK: 次要標籤色

    /// 涵蓋改走次要標籤色的圖表軸標籤與區段標題
    ///
    /// 這些文字原先誤用第三層標籤色，在淺色外觀下僅約 2.1:1
    @Test(arguments: ColorContrast.Appearance.allCases)
    func secondaryLabelTextMeetsTheTextFloor(appearance: ColorContrast.Appearance) {
        let palette = appearance.palette
        for background in [palette.surface, palette.background, palette.secondaryBackground] {
            let ratio = ColorContrast.ratio(
                palette.secondaryLabel,
                on: background,
                appearance: appearance
            )

            #expect(
                ratio >= Self.textFloor,
                "次要標籤色在 \(appearance) 下僅 \(ratio)"
            )
        }
    }

    @Test func distinctNamesKeepDistinctAvatarHues() {
        let first = BLAvatar.hueValue(for: "王小明")
        let second = BLAvatar.hueValue(for: "李大華")

        #expect(first != second)
    }
}
