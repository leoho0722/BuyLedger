//
//  ColorContrastTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI
import Testing
import UIKit
@testable import BuyLedger

/// ``ColorContrast`` 自身的對照案例
struct ColorContrastTests {

    // MARK: - Tests

    @Test func blackOnWhiteReachesTheMaximumRatio() {
        let ratio = ColorContrast.ratio(.black, on: .white, appearance: .light)

        #expect(abs(ratio - 21) < 0.01)
    }

    @Test func whiteOnBlackReachesTheMaximumRatio() {
        let ratio = ColorContrast.ratio(.white, on: .black, appearance: .dark)

        #expect(abs(ratio - 21) < 0.01)
    }

    @Test func identicalColorsYieldNoContrast() {
        let ratio = ColorContrast.ratio(.white, on: .white, appearance: .light)

        #expect(abs(ratio - 1) < 0.01)
    }

    /// 重現審查報告對 success 膠囊量到的 1.98:1
    @Test func successPillReproducesTheAuditedRatioBeforeTheChange() {
        let palette = BLPalette()
        let ratio = ColorContrast.ratio(
            palette.green,
            on: [palette.green.opacity(0.14), palette.surface],
            appearance: .light
        )

        #expect(abs(ratio - 1.98) < 0.01)
    }

    @Test func translucentForegroundIsCompositedBeforeMeasuring() {
        let opaque = ColorContrast.ratio(.black, on: .white, appearance: .light)
        let translucent = ColorContrast.ratio(
            Color.black.opacity(0.3), on: .white, appearance: .light)

        #expect(translucent < opaque)
        #expect(abs(translucent - 2.11) < 0.01)
    }

    @Test func layerStackIsCompositedFromTheBottomUp() {
        // Given：半透明黑色前景疊在白色背景上
        let stacked = ColorContrast.components(of: .clear, appearance: .light)

        #expect(stacked.alpha == 0)

        // When：計算堆疊色彩的對比度
        let ratio = ColorContrast.ratio(
            .black,
            on: [Color.black.opacity(0.5), .white],
            appearance: .light
        )

        // Then：結果應符合由下而上的合成值
        #expect(abs(ratio - 5.28) < 0.01)
    }

    // MARK: 情境解析

    @Test func appearanceResolvesDynamicColorsPerInterfaceStyle() {
        let dynamic = Color(uiColor: .label)
        let light = ColorContrast.components(of: dynamic, appearance: .light)
        let dark = ColorContrast.components(of: dynamic, appearance: .dark)

        #expect(light.red < 0.1)
        #expect(dark.red > 0.9)
    }

    @Test func appearanceResolvesTheIncreasedContrastVariant() {
        let dynamic = Color(uiColor: .systemBlue)
        let normal = ColorContrast.components(of: dynamic, appearance: .light)
        let increased = ColorContrast.components(of: dynamic, appearance: .lightIncreasedContrast)

        #expect(normal != increased)
    }
}
