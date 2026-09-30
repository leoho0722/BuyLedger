//
//  BLPhotoViewerTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證 zoomAnimation 的兩種結果
struct BLPhotoViewerTests {

    // MARK: - Tests

    /// 減少動態效果時不使用縮放動畫
    @Test func zoomAnimation_isNilWhenReduceMotionIsEnabled() {
        // Given：裝置啟用減少動態效果
        let reduceMotion = true

        // When：取得相片檢視器的縮放動畫
        let actual = BLPhotoViewer.zoomAnimation(reduceMotion: reduceMotion)

        // Then：不應使用縮放動畫
        #expect(actual == nil)
    }

    /// 偏好關閉時，縮放動畫應維持原本的快速動畫，而非 `nil`
    ///
    /// - Throws: 動畫不存在時拋出測試錯誤
    @Test
    func zoomAnimation_isNonNilWhenReduceMotionIsDisabled() throws(any Error) {
        // Given：裝置未啟用減少動態效果
        let reduceMotion = false

        // When：取得相片檢視器的縮放動畫
        let actual = try #require(
            BLPhotoViewer.zoomAnimation(reduceMotion: reduceMotion),
            "關閉減少動態效果時應使用縮放動畫"
        )

        // Then：動畫應是預期的快速縮放動畫
        #expect(
            String(reflecting: actual) == String(reflecting: Animation.snappy(duration: 0.2))
        )
    }
}
