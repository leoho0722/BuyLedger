//
//  SnapshotTests+Dashboard.swift
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

    /// 儀表板以全部範例訂單計算後顯示的統計畫面
    ///
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    /// - Note: 日期脈絡在 State 帶入固定值，畫面本身不讀取時間
    @Test
    func dashboardView_一般儀表板資料_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = DashboardFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded
            state.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = DashboardView(
                store: Store(initialState: state) {
                    DashboardFeature()
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

    /// 儀表板帶進行中的開團時，在 KPI 與近期訂單之間顯示「進行中的開團」區段
    ///
    /// - Note: 範例開團只有「四月韓國團」為進行中，「三月日本團」已結束不列出
    /// - Note: 區段位於 393 × 852 畫面內，不需加高
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    /// - Note: 日期脈絡在 State 帶入固定值，畫面本身不讀取時間
    @Test
    func dashboardView_含進行中開團_顯示進行中的開團區段() {
        TestDependencies.withFixedNow {
            // Given
            var state = DashboardFeature.State()
            state.orders = LedgerOrder.sampleCampaignOrders
            state.campaigns = Campaign.sampleCampaigns
            state.loadState = .loaded
            state.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = DashboardView(
                store: Store(initialState: state) {
                    DashboardFeature()
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

    /// 寬版 (iPad 的 `regular` 寬度) 的儀表板，hero 卡與 KPI 卡左右並排
    ///
    /// - Note: State 與一般儀表板資料相同且不帶開團
    /// - Note: 使用離屏快照，避免 key window 尺寸造成不穩定
    @Test
    func dashboardView_寬版_並排顯示hero與KPI() {
        TestDependencies.withFixedNow {
            // Given
            var state = DashboardFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded
            state.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = DashboardView(
                store: Store(initialState: state) {
                    DashboardFeature()
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

    /// 大尺寸 iPhone 橫向 (水平 `regular`、垂直 `compact`，956 × 440) 的儀表板，KPI 卡維持在 hero 卡下方
    ///
    /// - Note: 水平 `.regular` 但垂直 `.compact` 時版面分類仍是 `compact`，不採用 hero 並排 KPI 的寬版
    /// - Note: 使用離屏快照，避免 key window 是直向 iPhone 而裁切
    @Test
    func dashboardView_大尺寸iPhone橫向_KPI維持在hero下方() {
        TestDependencies.withFixedNow {
            // Given
            var state = DashboardFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded
            state.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = DashboardView(
                store: Store(initialState: state) {
                    DashboardFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.verticalSizeClass, .compact)
            .frame(width: 956, height: 440)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 首次載入訂單前的骨架：英雄卡、四格 KPI 與清單的佔位區塊，延遲出現的轉圈不列入基準
    ///
    /// - Note: `loadState` 維持初始值 `.loading`
    /// - Note: 使用 `EmptyReducer`，`.task` 不會觸發 Service
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    @Test
    func dashboardView_載入中_顯示載入骨架() {
        TestDependencies.withFixedNow {
            // Given
            let state = DashboardFeature.State()

            // When
            let view = DashboardView(
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

    /// 訂單載入完成但沒有任何訂單時，以首次使用畫面取代總覽，不顯示統計區段
    ///
    /// - Note: `loadState` 為 `.loaded`、`orders` 為空，且已記錄日期
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 水平 `.compact`、垂直 `.regular` 模擬 iPhone 直向，不依賴 snapshot host 的尺寸分類
    /// - Note: 使用離屏快照，避免 key window 是直向 iPhone 而裁切
    @Test
    func dashboardView_已載入無訂單_顯示首次使用畫面() {
        TestDependencies.withFixedNow {
            // Given
            var state = DashboardFeature.State()
            state.loadState = .loaded
            state.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )

            // When
            let view = DashboardView(
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
}
