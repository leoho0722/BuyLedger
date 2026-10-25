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

/// ``ColorContrast`` 的單元測試，以已知的對比值作對照
struct ColorContrastTests {

    /// 驗證黑字疊在白底時，對比比值為理論最大值 21
    @Test
    func ratio_黑字疊在白底_對比為最大值21() {
        // Given

        // When
        let ratio = ColorContrast.ratio(.black, on: .white, appearance: .light)

        // Then
        #expect(abs(ratio - 21) < 0.01)
    }

    /// 驗證白字疊在黑底時，對比比值為理論最大值 21
    @Test
    func ratio_白字疊在黑底_對比為最大值21() {
        // Given

        // When
        let ratio = ColorContrast.ratio(.white, on: .black, appearance: .dark)

        // Then
        #expect(abs(ratio - 21) < 0.01)
    }

    /// 驗證同色疊在一起時，對比比值為 1，即沒有對比
    @Test
    func ratio_同色疊在一起_對比為1() {
        // Given

        // When
        let ratio = ColorContrast.ratio(.white, on: .white, appearance: .light)

        // Then
        #expect(abs(ratio - 1) < 0.01)
    }

    /// 驗證成功膠囊的底色疊在表面上時，對比比值為 1.98:1
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

    /// 驗證半透明前景會先合成到底色上再量測，結果低於不透明黑字的 21
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

    /// 驗證圖層堆疊由下而上合成，半透明黑疊在白底上後再與黑字比對，對比比值為 5.28
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

    /// 驗證透明色解析後的不透明度為零
    @Test
    func components_透明色_不透明度為零() {
        // Given

        // When
        let clear = ColorContrast.components(of: .clear, appearance: .light)

        // Then
        #expect(clear.alpha == 0)
    }

    /// 驗證系統動態標籤色在淺色外觀下，紅色分量嚴格低於 0.1
    @Test
    func components_動態標籤色與淺色外觀_紅色分量低於門檻() {
        // Given
        let dynamic = Color(uiColor: .label)

        // When
        let light = ColorContrast.components(of: dynamic, appearance: .light)

        // Then
        #expect(light.red < 0.1)
    }

    /// 驗證系統動態標籤色在深色外觀下，紅色分量嚴格高於 0.9
    @Test
    func components_動態標籤色與深色外觀_紅色分量高於門檻() {
        // Given
        let dynamic = Color(uiColor: .label)

        // When
        let dark = ColorContrast.components(of: dynamic, appearance: .dark)

        // Then
        #expect(dark.red > 0.9)
    }

    /// 驗證系統藍色在淺色外觀下，提高對比與一般情境解析出的色彩分量不同
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
