//
//  SnapshotTests+Insights.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 洞察頁以全部範例訂單計算後顯示的分析畫面
    ///
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    @Test
    func insightsView_一般洞察資料_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded

            // When
            let view = InsightsView(
                store: Store(initialState: state) {
                    InsightsFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.horizontalSizeClass, .compact)
            .environment(\.verticalSizeClass, .regular)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 寬版 (iPad 的 regular 寬度) 的洞察頁，類別排行與成本結構兩張卡左右並排
    @Test
    func insightsView_寬版_並排顯示類別排行與成本結構() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded

            // When
            let view = InsightsView(
                store: Store(initialState: state) {
                    InsightsFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.verticalSizeClass, .regular)
            .frame(width: 1024, height: 768)

            // Then
            // 使用離屏快照，避免 key window 尺寸造成不穩定
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 大尺寸 iPhone 橫向 (水平 regular、垂直 compact，寬 956) 的洞察頁，兩張卡上下堆疊
    ///
    /// - Note: 水平 `.regular` 但垂直 `.compact` 時版面分類仍是 compact，不並排類別排行與成本結構
    /// - Note: 高度加到 1000 是為了讓兩張卡完整露出，版面由尺寸分類決定，高度不影響判斷
    @Test
    func insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded

            // When
            let view = InsightsView(
                store: Store(initialState: state) {
                    InsightsFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.verticalSizeClass, .compact)
            .frame(width: 956, height: 1000)

            // Then
            // 使用離屏快照，避免 key window 是直向 iPhone 而裁切
            assertSnapshot(of: view, as: .image)
        }
    }
}
