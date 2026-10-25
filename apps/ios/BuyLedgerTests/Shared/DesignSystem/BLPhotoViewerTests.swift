//
//  BLPhotoViewerTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// `BLPhotoViewer` 的單元測試，涵蓋 `zoomAnimation` 的兩種結果
struct BLPhotoViewerTests {

    /// 驗證減少動態效果開啟時，`zoomAnimation` 回傳 `nil`，不使用縮放動畫
    @Test
    func zoomAnimation_減少動態效果_不使用縮放動畫() {
        // Given
        let isReduceMotionEnabled = true

        // When
        let actual = BLPhotoViewer.zoomAnimation(reduceMotion: isReduceMotionEnabled)

        // Then
        #expect(actual == nil)
    }

    /// 驗證減少動態效果關閉時，縮放動畫維持 `.snappy(duration: 0.2)`，而非 `nil`
    ///
    /// - Throws: 動畫不存在時丟出測試錯誤
    @Test
    func zoomAnimation_關閉減少動態效果_保留快速縮放動畫() throws {
        // Given
        let isReduceMotionEnabled = false

        // When
        let actual = try #require(
            BLPhotoViewer.zoomAnimation(reduceMotion: isReduceMotionEnabled),
            "關閉減少動態效果時應使用縮放動畫"
        )

        // Then
        #expect(String(reflecting: actual) == String(reflecting: Animation.snappy(duration: 0.2)))
    }
}
