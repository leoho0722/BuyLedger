//
//  SnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

#if canImport(SnapshotTesting) && os(iOS)
    
    import ComposableArchitecture
    import SnapshotTesting
    import SwiftUI
    import Testing
    @testable import BuyLedger
    
    /// Snapshot baseline 用於視覺迴歸測試
    @MainActor
    struct SnapshotTests {
        
        // MARK: - Tests
        
        @Test func ordersCompactViewBaseline() {
            TestDependencies.withFixedNow {
                let state: OrdersFeature.State = {
                    var s = OrdersFeature.State()
                    s.orders = LedgerOrder.sampleOrders
                    s.hasLoaded = true
                    return s
                }()
                
                let view = OrdersCompactView(
                    store: Store(initialState: state) { OrdersFeature() },
                    language: .traditionalChinese
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func ordersCompactViewLongContentBaseline() {
            // 長文字不可撐寬訂單列，確保頁面左右邊距正常
            TestDependencies.withFixedNow {
                let longOrder = LedgerOrder(
                    id: "BL-LONG-0001",
                    customer: LedgerCustomer(
                        name: "line19991030_verylongusername", initials: "LI", tier: .vip),
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
                
                let state: OrdersFeature.State = {
                    var s = OrdersFeature.State()
                    s.orders = [longOrder]
                    s.hasLoaded = true
                    return s
                }()
                
                let view = OrdersCompactView(
                    store: Store(initialState: state) { OrdersFeature() },
                    language: .traditionalChinese
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func ordersCompactViewMultiSelectBaseline() {
            // 驗證 compact 多選畫面的勾選狀態與工具列。
            // 兩種版面共用 OrderSelectableRow 與 OrdersToolbarContent
            TestDependencies.withFixedNow {
                let state: OrdersFeature.State = {
                    var s = OrdersFeature.State()
                    s.orders = LedgerOrder.sampleOrders
                    s.hasLoaded = true
                    s.isSelecting = true
                    s.selectedOrderIDs = [LedgerOrder.sampleOrders[0].id]
                    return s
                }()
                
                let view = OrdersCompactView(
                    store: Store(initialState: state) { OrdersFeature() },
                    language: .traditionalChinese
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
        
        @Test func ordersRegularViewMultiSelectBaseline() {
            // regular size class 驗證多選列，不依賴 iPad 模擬器
            //
            // 使用離屏快照，避免 key window 尺寸造成不穩定
            TestDependencies.withFixedNow {
                let state: OrdersFeature.State = {
                    var s = OrdersFeature.State()
                    s.orders = LedgerOrder.sampleOrders
                    s.hasLoaded = true
                    s.isSelecting = true
                    s.selectedOrderIDs = [LedgerOrder.sampleOrders[0].id]
                    return s
                }()
                
                let view = OrdersView(
                    store: Store(initialState: state) { OrdersFeature() },
                    language: .traditionalChinese
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.horizontalSizeClass, .regular)
                .frame(width: 1024, height: 768)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func dashboardViewBaseline() {
            TestDependencies.withFixedNow {
                let state: DashboardFeature.State = {
                    var s = DashboardFeature.State()
                    s.orders = LedgerOrder.sampleOrders
                    s.loadState = .loaded
                    return s
                }()
                
                let view = DashboardView(
                    store: Store(initialState: state) { DashboardFeature() },
                    language: .traditionalChinese
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func insightsViewBaseline() {
            TestDependencies.withFixedNow {
                let state: InsightsFeature.State = {
                    var s = InsightsFeature.State()
                    s.orders = LedgerOrder.sampleOrders
                    s.loadState = .loaded
                    return s
                }()
                
                let view = InsightsView(
                    store: Store(initialState: state) { InsightsFeature() },
                    language: .traditionalChinese
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func orderEditViewBaseline() {
            TestDependencies.withFixedNow {
                var state = OrderEditFeature.State(
                    original: LedgerOrder.sampleOrders[0], id: UUID(0),
                    currentDate: TestDependencies.fixedNow)
                // 快照不經過 .task，直接標記照片載入完成。
                state.photoLoadPhase = .loaded
                
                let view = OrderEditView(
                    store: Store(initialState: state) { OrderEditFeature() }
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
        
        @Test func orderEditViewMergeContextBaseline() {
            // 合併產生的訂單：類別/開團為多選 trigger row (「、」串接顯示)
            // 金額與明細欄位與一般訂單相同、維持可編輯
            TestDependencies.withFixedNow {
                let mergedOrder = LedgerOrder.sampleOrders.first { !$0.mergedSourceIDs.isEmpty }!
                var state = OrderEditFeature.State(
                    original: mergedOrder, id: UUID(0), currentDate: TestDependencies.fixedNow)
                // 理由同 orderEditViewBaseline，手動標記照片已載入完成
                state.photoLoadPhase = .loaded
                
                let view = OrderEditView(
                    store: Store(initialState: state) { OrderEditFeature() }
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
        
        @Test func orderEditViewLongIdentifierBaseline() {
            // 長編號仍應顯示短版 displayID，避免撐壞版面
            TestDependencies.withFixedNow {
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
                    original: longIDOrder, id: UUID(0), currentDate: TestDependencies.fixedNow)
                // 理由同 orderEditViewBaseline，手動標記照片已載入完成
                state.photoLoadPhase = .loaded
                
                let view = OrderEditView(
                    store: Store(initialState: state) { OrderEditFeature() }
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
        
        @Test func orderDetailCostBreakdownBaseline() {
            TestDependencies.withFixedNow {
                // 驗證成本圖表分別列出三種手續費。
                let order = LedgerOrder(
                    id: "BL-FEE-SNAP-001",
                    customer: LedgerCustomer(name: "手續費拆解", initials: "FB", tier: .vip),
                    status: .delivered,
                    currency: .jpy,
                    date: Date(timeIntervalSince1970: 1_777_145_600),
                    items: [
                        LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 30_000)
                    ],
                    itemCost: Decimal(6_000),
                    domesticShipping: 0,
                    internationalShipping: 0,
                    foreignDomesticShipping: 0,
                    cardFeeRate: Decimal(string: "0.015") ?? 0,
                    platformFeeRate: Decimal(string: "0.03") ?? 0,
                    paymentFeeRate: Decimal(string: "0.005") ?? 0,
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
                
                let view = OrderDetailView(order: order)
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func blBarChartThirtyDaysBaseline() {
            TestDependencies.withFixedNow {
                // 產生 30 天資料，驗證長條圖的標籤抽稀與捲動邊界。
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
                let base = TestDependencies.fixedNow
                
                let bars = (0..<30).reversed().compactMap { offset -> BLBarChartValue? in
                    guard let day = calendar.date(byAdding: .day, value: -offset, to: base) else {
                        return nil
                    }
                    return BLBarChartValue(
                        label: day.formatted(
                            .verbatim(
                                "\(month: .twoDigits)/\(day: .twoDigits)",
                                timeZone: calendar.timeZone,
                                calendar: calendar
                            )
                        ),
                        value: Double((offset * 53) % 180 + 20),
                        valueDescription: "NT$\((offset * 53) % 180 + 20)"
                    )
                }
                
                let view = BLBarChart(data: bars, height: 200, isScrollEnabled: true)
                    .frame(width: 393)
                    .padding()
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func persistenceFailureViewBaseline() {
            TestDependencies.withFixedNow {
                let view = PersistenceFailureView(
                    store: Store(
                        initialState: PersistenceFailureFeature.State()
                    ) {
                        PersistenceFailureFeature()
                    }
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                // 復原按鈕的 prominent 玻璃樣式在離屏渲染會整張變黑，改於 key window 渲染
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
        
        @Test func quoteViewBaseline() {
            // 帶非零本金與目標毛利讓 hero 顯示真實數字而非破折號
            TestDependencies.withFixedNow {
                let state = QuoteFeature.State(
                    fromCurrency: .krw,
                    itemPrice: 100_000,
                    domesticShipping: 5_000,
                    internationalShippingTwd: 180,
                    cardFeePercent: 2.5,
                    paymentFeePercent: 1,
                    platformFeePercent: 1,
                    targetMarginPercent: 25,
                    snapshot: FxRateSnapshot.fallback
                )
                
                let view = QuoteView(
                    store: Store(initialState: state) { QuoteFeature() }
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
        
        @Test func quoteViewRateUnavailable() {
            // 驗證找不到匯率時顯示錯誤狀態
            TestDependencies.withFixedNow {
                let unavailableSnapshot = FxRateSnapshot(
                    date: Date(timeIntervalSince1970: 0),
                    base: .twd,
                    rates: [.twd: 1]
                )
                let state = QuoteFeature.State(
                    fromCurrency: .krw,
                    snapshot: unavailableSnapshot
                )
                
                let view = QuoteView(
                    store: Store(initialState: state) { QuoteFeature() }
                )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)
                
                assertSnapshot(of: view, as: .image)
            }
        }
    }
    
#endif
