//
//  SnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// 把主要畫面渲染成圖片並與存好的基準圖比對，版面或樣式意外改變時測試失敗
@MainActor
struct SnapshotTests {

    // MARK: - Tests

    /// iPhone 寬度的訂單清單載入全部範例訂單後的畫面
    @Test
    func ordersCompactView_一般訂單清單_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.hasLoaded = true

            // When
            let view = OrdersCompactView(
                store: Store(initialState: state) {
                    OrdersFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 客戶名稱與商品類別很長時，訂單列不會把頁面撐寬，左右邊距維持正常
    @Test
    func ordersCompactView_長內容訂單清單_避免撐寬版面() {
        TestDependencies.withFixedNow {
            // Given
            let longOrder = LedgerOrder(
                id: "BL-LONG-0001",
                customer: LedgerCustomer(
                    name: "line19991030_verylongusername",
                    initials: "LI",
                    tier: .vip
                ),
                status: .shipping,
                currency: .twd,
                date: TestDependencies.fixedNow,
                items: [LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 1_000)],
                itemCost: 600,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 1_000,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "蝦皮",
                categories: ["aespa Lemonade QQ 音樂限定禮包"],
                paymentMethod: "信用卡",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )

            var state = OrdersFeature.State()
            state.orders = [longOrder]
            state.hasLoaded = true

            // When
            let view = OrdersCompactView(
                store: Store(initialState: state) {
                    OrdersFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// iPhone 寬度的訂單清單進入多選並勾選第一筆時，顯示勾選狀態與多選工具列
    ///
    /// - Note: 窄版與寬版共用 `OrderSelectableRow` 與 `OrdersToolbarContent`
    @Test
    func ordersCompactView_多選模式_顯示勾選與工具列() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.hasLoaded = true
            state.isSelecting = true
            state.selectedOrderIDs = [LedgerOrder.sampleOrders[0].id]

            // When
            let view = OrdersCompactView(
                store: Store(initialState: state) {
                    OrdersFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 寬版 (iPad 的 regular 寬度) 訂單頁進入多選並勾選第一筆時，清單顯示選取列
    ///
    /// - Note: 以 `horizontalSizeClass` 設為 `.regular` 模擬 iPad 版面，不需要 iPad 模擬器
    @Test
    func ordersView_寬版多選模式_顯示選取列() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.hasLoaded = true
            state.isSelecting = true
            state.selectedOrderIDs = [LedgerOrder.sampleOrders[0].id]

            // When
            let view = OrdersView(
                store: Store(initialState: state) {
                    OrdersFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.horizontalSizeClass, .regular)
            .frame(width: 1024, height: 768)

            // Then
            // 使用離屏快照，避免 key window 尺寸造成不穩定
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 儀表板以全部範例訂單計算後顯示的統計畫面
    @Test
    func dashboardView_一般儀表板資料_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = DashboardFeature.State()
            state.orders = LedgerOrder.sampleOrders
            state.loadState = .loaded

            // When
            let view = DashboardView(
                store: Store(initialState: state) {
                    DashboardFeature()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 洞察頁以全部範例訂單計算後顯示的分析畫面
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
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 編輯既有訂單時，表單帶入第一筆範例訂單的內容
    @Test
    func orderEditView_一般既有訂單_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrderEditFeature.State(
                original: LedgerOrder.sampleOrders[0],
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            // 快照不經過 .task，直接標記照片載入完成
            state.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 編輯合併產生的訂單時，商品類別與開團欄位把多個值以「、」串接顯示
    ///
    /// - Throws: 範例訂單沒有合併訂單時由 `#require` 丟出
    @Test
    func orderEditView_合併訂單情境_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let mergedOrder = try #require(
                LedgerOrder.sampleOrders.first {
                    !$0.mergedSourceIDs.isEmpty
                }
            )
            var state = OrderEditFeature.State(
                original: mergedOrder,
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            // 快照不經過 .task，直接標記照片載入完成
            state.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 訂單編號很長時，編輯表單版面不被撐壞，短版識別碼 (`displayID`) 也依規則截短
    ///
    /// - Note: 截圖守住的是表單可見部分，短識別碼的截短規則由字面值斷言守住，「原始訂單」段不在截圖範圍內
    @Test
    func orderEditView_長訂單識別碼_顯示短識別碼() {
        TestDependencies.withFixedNow {
            // Given
            let longIDOrder = LedgerOrder(
                id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
                customer: LedgerCustomer(name: "長編號測試", initials: "LI", tier: .regular),
                status: .quoting,
                currency: .twd,
                date: TestDependencies.fixedNow,
                items: [LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 1_000)],
                itemCost: 600,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 1_000,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "蝦皮",
                categories: ["美妝"],
                paymentMethod: "信用卡",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
            var state = OrderEditFeature.State(
                original: longIDOrder,
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            // 快照不經過 .task，直接標記照片載入完成
            state.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            #expect(longIDOrder.displayID == "BL-DRAFT-000000")
        }
    }

    /// 訂單詳情的成本圖表把刷卡、平台、金流三種手續費分別列出
    ///
    /// - Throws: 手續費字面值無法轉成 `Decimal` 時由 `#require` 丟出
    @Test
    func orderDetailView_成本明細內容_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let cardFeeRate = try #require(Decimal(string: "0.015"))
            let platformFeeRate = try #require(Decimal(string: "0.03"))
            let paymentFeeRate = try #require(Decimal(string: "0.005"))
            let order = LedgerOrder(
                id: "BL-FEE-SNAP-001",
                customer: LedgerCustomer(name: "手續費拆解", initials: "FB", tier: .vip),
                status: .delivered,
                currency: .jpy,
                date: Date(timeIntervalSince1970: 1_777_145_600),
                items: [
                    LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 30_000),
                ],
                itemCost: Decimal(6_000),
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: cardFeeRate,
                platformFeeRate: platformFeeRate,
                paymentFeeRate: paymentFeeRate,
                chargedAmount: Decimal(10_000),
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "示範",
                categories: ["美妝"],
                paymentMethod: "信用卡",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )

            // When
            let view = OrderDetailView(order: order)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 長條圖放入 30 天資料並開啟捲動時，預設停在最新的一端，每根長條都標出日期
    @Test
    func blBarChart_近三十天資料_捲動停在最新日期() {
        TestDependencies.withFixedNow {
            // Given
            let calendar = TestDependencies.fixedCalendar
            let base = TestDependencies.fixedNow

            let bars: [BLBarChartValue] = (0..<30).reversed().compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: base) else {
                    return nil
                }
                let amount = (offset * 53) % 180 + 20
                return BLBarChartValue(
                    label: day.formatted(
                        .verbatim(
                            "\(month: .twoDigits)/\(day: .twoDigits)",
                            timeZone: calendar.timeZone,
                            calendar: calendar
                        )
                    ),
                    value: Double(amount),
                    valueDescription: "NT$\(amount)"
                )
            }

            // When
            let view = BLBarChart(data: bars, height: 200, isScrollEnabled: true)
                .frame(width: 393)
                .padding()

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 資料無法開啟時的阻斷畫面，顯示說明文字與「改用空白資料庫繼續」按鈕
    @Test
    func persistenceFailureView_持久化錯誤_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given

            // When
            let view = PersistenceFailureView(
                store: Store(initialState: PersistenceFailureFeature.State()) {
                    PersistenceFailureFeature()
                }
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            // 復原按鈕的 prominent 玻璃樣式在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 報價試算填入非零的商品價格與目標毛利時，建議售價卡片與成本拆解都顯示實際數字，不是破折號
    @Test
    func quoteView_非零試算輸入_顯示成本與建議售價() {
        TestDependencies.withFixedNow {
            // Given
            let state = QuoteFeature.State(
                rateSource: QuoteRateFeature.State(
                    fromCurrency: .krw,
                    snapshot: FxRateSnapshot.fallback
                ),
                itemPrice: 100_000,
                domesticShipping: 5_000,
                internationalShippingTWD: 180,
                cardFeePercent: 2.5,
                paymentFeePercent: 1,
                platformFeePercent: 1,
                targetMarginPercent: 25
            )

            let store = Store(initialState: state) {
                QuoteFeature()
            }

            // When
            let view = QuoteView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 匯率資料裡沒有所選幣別 (韓圓) 的匯率時，報價頁顯示錯誤狀態
    @Test
    func quoteView_沒有可用匯率_顯示錯誤狀態() {
        TestDependencies.withFixedNow {
            // Given
            let unavailableSnapshot = FxRateSnapshot(
                date: Date(timeIntervalSince1970: 0),
                base: .twd,
                rates: [.twd: 1]
            )
            let state = QuoteFeature.State(
                rateSource: QuoteRateFeature.State(
                    fromCurrency: .krw,
                    snapshot: unavailableSnapshot
                )
            )

            let store = Store(initialState: state) {
                QuoteFeature()
            }

            // When
            let view = QuoteView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 匯率工具已有匯率資料時顯示已連線狀態
    @Test
    func fxView_已載入匯率快照_顯示連線狀態() {
        TestDependencies.withFixedNow {
            // Given
            let state = FxFeature.State(snapshot: FxRateSnapshot.fallback)
            let store = Store<FxFeature.State, FxFeature.Action>(initialState: state) {
                EmptyReducer()
            }

            // When
            let view = FxView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 匯率工具在載入失敗時顯示錯誤橫幅與重試鍵
    @Test
    func fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵() {
        TestDependencies.withFixedNow {
            // Given
            let state = FxFeature.State(errorMessage: "網路連線異常；無法顯示即時匯率，請稍後再試。")
            let store = Store<FxFeature.State, FxFeature.Action>(initialState: state) {
                EmptyReducer()
            }

            // When
            let view = FxView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}
