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
    @Test func zoomAnimationIsNilWhenReduceMotionIsEnabled() {
        #expect(BLPhotoViewer.zoomAnimation(reduceMotion: true) == nil)
    }
    
    /// 偏好關閉時，縮放動畫應維持原本的快速動畫，而非 `nil`
    @Test func zoomAnimationIsNonNilWhenReduceMotionIsDisabled() {
        #expect(BLPhotoViewer.zoomAnimation(reduceMotion: false) != nil)
    }
}
