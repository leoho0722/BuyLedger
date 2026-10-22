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

    /// 確認黑字疊在白底的對比比值達到理論最大值 21
    @Test
    func ratio_黑字疊在白底_對比為最大值21() {
        // Given

        // When
        let ratio = ColorContrast.ratio(.black, on: .white, appearance: .light)

        // Then
        #expect(abs(ratio - 21) < 0.01)
    }

    /// 確認白字疊在黑底的對比比值達到理論最大值 21
    @Test
    func ratio_白字疊在黑底_對比為最大值21() {
        // Given

        // When
        let ratio = ColorContrast.ratio(.white, on: .black, appearance: .dark)

        // Then
        #expect(abs(ratio - 21) < 0.01)
    }

    /// 確認同色疊在一起時對比比值為 1，即沒有對比
    @Test
    func ratio_同色疊在一起_對比為1() {
        // Given

        // When
        let ratio = ColorContrast.ratio(.white, on: .white, appearance: .light)

        // Then
        #expect(abs(ratio - 1) < 0.01)
    }

    /// 確認成功膠囊的底色疊在表面上時，對比比值為 1.98:1
    @Test
    func ratio_成功膠囊底色疊在表面_對比為一點九八() {
        // Given

        // When
        let ratio = ColorContrast.ratio(
            .blGreen,
            on: [.blGreen.opacity(0.14), .blSurface],
            appearance: .light
        )

        // Then
        #expect(abs(ratio - 1.98) < 0.01)
    }

    /// 確認半透明前景會先合成到底色上再量測，結果低於不透明黑字的 21
    @Test
    func ratio_半透明前景_先合成後再量測() {
        // Given

        // When
        let translucent = ColorContrast.ratio(
            Color.black.opacity(0.3),
            on: .white,
            appearance: .light
        )

        // Then
        #expect(translucent < 21)
        #expect(abs(translucent - 2.11) < 0.01)
    }

    /// 確認圖層堆疊由下而上合成，半透明黑疊在白底上後再與黑字比對
    @Test
    func ratio_圖層堆疊_依由下而上順序合成() {
        // Given

        // When
        let ratio = ColorContrast.ratio(
            .black,
            on: [Color.black.opacity(0.5), .white],
            appearance: .light
        )

        // Then
        #expect(abs(ratio - 5.28) < 0.01)
    }

    /// 確認透明色解析後的不透明度為零
    @Test
    func components_透明色_不透明度為零() {
        // Given

        // When
        let clear = ColorContrast.components(of: .clear, appearance: .light)

        // Then
        #expect(clear.alpha == 0)
    }

    /// 確認同一個動態色彩在淺色與深色外觀下解析出不同的分量
    @Test
    func components_動態色彩_依外觀解析出不同分量() {
        // Given
        let dynamic = Color(uiColor: .label)

        // When
        let light = ColorContrast.components(of: dynamic, appearance: .light)
        let dark = ColorContrast.components(of: dynamic, appearance: .dark)

        // Then
        #expect(light.red < 0.1)
        #expect(dark.red > 0.9)
    }

    /// 確認提高對比情境會解析出與一般情境不同的分量
    @Test
    func components_提高對比情境_解析出不同於一般情境的分量() {
        // Given
        let dynamic = Color(uiColor: .systemBlue)

        // When
        let normal = ColorContrast.components(of: dynamic, appearance: .light)
        let increased = ColorContrast.components(of: dynamic, appearance: .lightIncreasedContrast)

        // Then
        #expect(normal != increased)
    }
}
