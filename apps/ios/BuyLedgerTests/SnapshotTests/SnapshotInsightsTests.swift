//
//  SnapshotInsightsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `InsightsView` 的快照測試，涵蓋各尺寸分類與資料狀態
@MainActor
struct SnapshotInsightsTests {

    /// 驗證洞察頁以範例訂單計算後顯示分析畫面，畫面符合基準圖
    ///
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    @Test
    func insightsView_一般洞察資料_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded
            state.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

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

    /// 驗證寬版 (iPad 的 `regular` 寬度) 洞察頁的類別排行與成本結構兩張卡左右並排，畫面符合基準圖
    ///
    /// - Note: 使用離屏快照，避免 key window 尺寸造成不穩定
    @Test
    func insightsView_寬版_並排顯示類別排行與成本結構() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded
            state.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

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
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證大尺寸 iPhone 橫向 (水平 `regular`、垂直 `compact`，寬 956) 的洞察頁，兩張卡上下堆疊，畫面符合基準圖
    ///
    /// - Note: 水平 `.regular` 但垂直 `.compact` 時版面分類仍是 `compact`，不並排類別排行與成本結構
    /// - Note: 高度加到 1000 是為了讓兩張卡完整露出，版面由尺寸分類決定，高度不影響判斷
    /// - Note: 使用離屏快照，避免 key window 是直向 iPhone 而裁切
    @Test
    func insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded
            state.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

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
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證洞察資料載入前顯示骨架：範圍列、趨勢卡與排行卡的佔位區塊，延遲出現的轉圈不列入基準，畫面符合基準圖
    ///
    /// - Note: `loadState` 維持初始值 `.loading`
    /// - Note: 使用 `EmptyReducer`，`.task` 不會觸發 Service
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    @Test
    func insightsView_載入中_顯示載入骨架() {
        TestDependencies.withFixedNow {
            // Given
            let state = InsightsFeature.State()

            // When
            let view = InsightsView(
                store: Store(initialState: state) {
                    EmptyReducer()
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

    /// 驗證訂單載入完成但沒有任何訂單時，以空狀態取代分析內容，引導使用者先建立訂單，畫面符合基準圖
    ///
    /// - Note: `loadState` 為 `.loaded`、`orders` 為空，並帶入記錄的日期脈絡
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    /// - Note: 使用離屏快照，避免 key window 是直向 iPhone 而裁切
    @Test
    func insightsView_已載入無訂單_顯示空狀態() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.loadState = .loaded
            state.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = InsightsView(
                store: Store(initialState: state) {
                    EmptyReducer()
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

    /// 驗證分析頁帶範例開團訂單與開團資料時，於趨勢卡下方顯示每團毛利排行卡，畫面符合基準圖
    ///
    /// - Note: 排行卡只在有可排行的開團時出現，其餘測試不帶開團，因此不含此卡
    /// - Note: 高度加到 1800 讓排行卡露出
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    /// - Note: 使用離屏快照，避免 key window 是直向 iPhone 而裁切
    @Test
    func insightsView_帶開團資料_顯示每團毛利排行卡() {
        TestDependencies.withFixedNow {
            // Given
            var state = InsightsFeature.State()
            state.orders = LedgerOrder.sampleCampaignOrders
            state.campaigns = Campaign.sampleCampaigns
            state.loadState = .loaded
            state.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = InsightsView(
                store: Store(initialState: state) {
                    EmptyReducer()
                },
                language: .traditionalChinese
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.horizontalSizeClass, .compact)
                .environment(\.verticalSizeClass, .regular)
                .frame(width: 393, height: 1_800)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}
