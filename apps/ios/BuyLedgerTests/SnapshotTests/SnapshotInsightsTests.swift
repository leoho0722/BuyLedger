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

    /// 驗證寬版 (iPad 的 `regular` 寬度) 洞察頁的卡片依固定順序垂直排列，內容限寬置中，畫面符合基準圖
    ///
    /// - Note: 使用離屏快照，避免 key window 尺寸造成不穩定
    @Test
    func insightsView_寬版_卡片依固定順序垂直排列() {
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
    /// - Note: 所有寬度都依同一順序垂直排列，寬度超過閱讀上限時內容置中
    /// - Note: 高度加到 1000 是為了讓兩張卡完整露出
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

    /// 驗證 393 點寬最大輔助字級下，成本結構卡的圓餅圖與中心文字留在卡片內，圖例完整呈現
    ///
    /// - Note: 高度足以容納圓餅圖、中心文字與圖例
    /// - Note: 使用固定的三筆成本區塊資料
    @Test
    func insightsCostStructureCard_393點寬最大輔助字級_圓餅圖與中心文字留在卡片內() {
        TestDependencies.withFixedNow {
            // Given
            let segments = [
                InsightsCostSegment(
                    label: "orders.detail.label.itemCost",
                    value: 12_000,
                    tone: .accent
                ),
                InsightsCostSegment(
                    label: "orders.detail.label.localShipping",
                    value: 1_500,
                    tone: .teal
                ),
                InsightsCostSegment(label: "orders.detail.label.fees", value: 900, tone: .orange),
            ]

            // When
            let view = InsightsCostStructureCard(
                language: .traditionalChinese,
                segments: segments,
                totalCost: 14_400
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.dynamicTypeSize, .accessibility5)
                .frame(width: 393, height: 800, alignment: .top)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證 393 點寬最大輔助字級下，走勢卡的長條圖軸標依放大後的間距抽樣，不互相重疊
    ///
    /// - Note: 標籤採正式 `.twelveMonths` 的 `yy/MM` 格式，結束於 `fixedNow` 所在的 2026/04
    /// - Note: 使用十二個月的固定走勢資料，高度足以容納整張走勢卡
    @Test
    func insightsTrendCard_393點寬最大輔助字級_走勢軸標不重疊() {
        TestDependencies.withFixedNow {
            // Given
            let monthLabels = [
                "25/05",
                "25/06",
                "25/07",
                "25/08",
                "25/09",
                "25/10",
                "25/11",
                "25/12",
                "26/01",
                "26/02",
                "26/03",
                "26/04",
            ]
            let bars = monthLabels.enumerated().map { index, label in
                BLBarChartValue(
                    label: label,
                    value: Double((index + 1) * 100),
                    valueDescription: "NT$\((index + 1) * 100)"
                )
            }

            // When
            let view = InsightsTrendCard(
                bars: bars,
                delta: "↑ 18.5%",
                language: .traditionalChinese,
                range: .twelveMonths,
                totalProfit: 5_900,
                trend: .up
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.dynamicTypeSize, .accessibility5)
                .frame(width: 393, height: 900, alignment: .top)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證 393 點寬最大輔助字級下，類別排行列的金額保持單行不斷字，名稱負責換行
    ///
    /// - Note: 使用三個固定類別資料，高度足以容納整張排行卡
    @Test
    func insightsCategoryCard_393點寬最大輔助字級_金額不斷字() {
        TestDependencies.withFixedNow {
            // Given
            let categories = [
                InsightsCategory(name: "美妝保養", profit: 8_600, ratio: 1),
                InsightsCategory(name: "服飾配件", profit: 5_200, ratio: 0.6),
                InsightsCategory(name: "零食", profit: 1_900, ratio: 0.22),
            ]

            // When
            let view = InsightsCategoryCard(categories: categories) { _ in
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.dynamicTypeSize, .accessibility5)
                .frame(width: 393, height: 580, alignment: .top)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}
