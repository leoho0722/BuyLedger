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
        let ratio = ColorContrast.ratio(
            tone.onIndicator, on: tone.indicator, appearance: appearance)
        
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
            let ratio = ColorContrast.ratio(
                lower.background, on: upper.background, appearance: appearance)
            
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
    
    // MARK: 彩底 hero 卡
    
    /// 驗證 hero 卡白字與漸層的對比度
    @Test(arguments: ColorContrast.Appearance.allCases)
    func heroCardWhiteTextMeetsTheFloorOnBothGradientEnds(appearance: ColorContrast.Appearance) {
        for end in BLHeroCardBackground.gradientColors {
            let ratio = ColorContrast.ratio(.white, on: end, appearance: appearance)
            
            #expect(
                ratio >= Self.textFloor,
                "主卡白字在 \(appearance) 下對漸層端僅 \(ratio)"
            )
        }
    }
    
    // MARK: 具名色彩資源解析
    
    /// 驗證具名色彩資源存在
    @Test(arguments: ColorContrast.Appearance.allCases)
    func everyNamedColorResourceActuallyResolves(appearance: ColorContrast.Appearance) {
        let fallback = ColorContrast.components(
            of: Color("BLToneResourceThatDoesNotExist", bundle: .assets),
            appearance: appearance
        )
        
        var resources: [(String, Color)] = [
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
        
        for (name, color) in resources {
            #expect(
                ColorContrast.components(of: color, appearance: appearance) != fallback,
                "\(name) 在 \(appearance) 下回退為系統預設色，代表具名資源沒有解析到"
            )
        }
    }
    
    // MARK: 次要標籤色
    
    /// 涵蓋改走次要標籤色的圖表軸標籤與區段標題
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
    
    // MARK: 次要標籤色縮寫
    
    /// 驗證次要標籤色的對比度
    @Test(arguments: ColorContrast.Appearance.allCases)
    func blSecondaryLabelShorthandResolvesToThePaletteColor(appearance: ColorContrast.Appearance) {
        let shorthand = ColorContrast.components(of: .blSecondaryLabel, appearance: appearance)
        let paletteValue = ColorContrast.components(
            of: appearance.palette.secondaryLabel, appearance: appearance)
        
        #expect(
            shorthand == paletteValue,
            "Color.blSecondaryLabel 在 \(appearance) 下與色盤次要標籤色分量不同：\(shorthand) vs \(paletteValue)"
        )
    }
    
    // MARK: 分組色相
    
    /// 驗證側邊欄各分組在不同外觀下使用不同色相
    @Test(arguments: ColorContrast.Appearance.allCases)
    func statusHueValuesStayMutuallyDistinguishable(appearance: ColorContrast.Appearance) {
        let palette = appearance.palette
        let statuses = RootSidebarLayout.SmartGroup.orderBrowsingCases.map(\.status)
        let components = statuses.map {
            ColorContrast.components(
                of: BLStatusHue.color(for: $0, in: palette), appearance: appearance)
        }
        
        for i in components.indices {
            for j in components.indices where j > i {
                #expect(
                    components[i] != components[j],
                    "\(statuses[i]) 與 \(statuses[j]) 在 \(appearance) 下的分組色相相同"
                )
            }
        }
    }
    
}
