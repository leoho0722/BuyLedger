//
//  SnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//
//  Snapshot baseline 用於檢查視覺迴歸；第一次跑會自動寫入 baseline，之後改動視覺時若與 baseline 不符會失敗。
//
//  - 圖片檔放在 BuyLedgerTests/__Snapshots__/ (相對於本檔)
//  - 升級設計時請刪掉對應的 baseline 檔案，下次跑測試會自動重建
//  - 所有 view 統一透過 ``TestDependencies/withFixedNow(_:)`` 包住，避免跨日跑出不同結果
//

#if canImport(SnapshotTesting) && os(iOS)

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing
@testable import BuyLedger

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
                store: Store(initialState: state) { OrdersFeature() }
            )
                .frame(width: 393, height: 852)

            assertSnapshot(of: view, as: .image)
        }
    }

    @Test func ordersCompactViewLongContentBaseline() {
        // 迴歸守護：無法換行的長客戶名稱與長商品類別不可把訂單列 (進而整個垂直 ScrollView 內容) 撐得比畫面還寬，
        // 否則 Dashboard / 訂單頁左右邊距會整個跑掉。見 OrderRowView 名稱截斷與 BLTagPill 改 lineLimit 的修正。
        TestDependencies.withFixedNow {
            let longOrder = LedgerOrder(
                id: "BL-LONG-0001",
                customer: LedgerCustomer(name: "line19991030_verylongusername", initials: "LI", tier: .vip),
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
                category: "aespa Lemonade QQ 音樂限定禮包",
                paymentMethod: "信用卡",
                notes: "",
                verificationStatus: "",
                campaignName: "",
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: []
            )

            let state: OrdersFeature.State = {
                var s = OrdersFeature.State()
                s.orders = [longOrder]
                s.hasLoaded = true
                return s
            }()

            let view = OrdersCompactView(
                store: Store(initialState: state) { OrdersFeature() }
            )
                .frame(width: 393, height: 852)

            assertSnapshot(of: view, as: .image)
        }
    }

    @Test func dashboardViewBaseline() {
        TestDependencies.withFixedNow {
            let state: RootFeature.State = {
                var s = RootFeature.State()
                s.orders.orders = LedgerOrder.sampleOrders
                s.orders.hasLoaded = true
                return s
            }()

            let view = DashboardView(
                store: Store(initialState: state) { RootFeature() }
            )
                .frame(width: 393, height: 852)

            assertSnapshot(of: view, as: .image)
        }
    }

    @Test func insightsViewBaseline() {
        TestDependencies.withFixedNow {
            let state: RootFeature.State = {
                var s = RootFeature.State()
                s.orders.orders = LedgerOrder.sampleOrders
                s.orders.hasLoaded = true
                return s
            }()

            let view = InsightsView(
                store: Store(initialState: state) { RootFeature() }
            )
                .frame(width: 393, height: 852)

            assertSnapshot(of: view, as: .image)
        }
    }

    @Test func orderEditViewBaseline() {
        TestDependencies.withFixedNow {
            let state = OrderEditFeature.State(original: LedgerOrder.sampleOrders[0])

            let view = OrderEditView(
                store: Store(initialState: state) { OrderEditFeature() }
            )
                .frame(width: 393, height: 852)

            assertSnapshot(of: view, as: .image)
        }
    }

    @Test func orderDetailCostBreakdownBaseline() {
        TestDependencies.withFixedNow {
            // 同時帶有刷卡、平台與金流手續費的訂單，用於驗證成本拆解 chart 將三種手續費分別列出。
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
                cardFeeRate: Decimal(string: "0.015") ?? 0,
                platformFeeRate: Decimal(string: "0.03") ?? 0,
                paymentFeeRate: Decimal(string: "0.005") ?? 0,
                chargedAmount: Decimal(10_000),
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "示範",
                category: "美妝",
                paymentMethod: "信用卡",
                notes: "",
                verificationStatus: "",
                campaignName: "",
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: []
            )

            let view = OrderDetailView(order: order)
                .frame(width: 393, height: 852)

            assertSnapshot(of: view, as: .image)
        }
    }

    @Test func blBarChartThirtyDaysBaseline() {
        TestDependencies.withFixedNow {
            // 模擬分析頁「30 天」逐日資料：30 根長條、X 軸帶日數字標籤。
            // 用於守護 BLBarChart 在標籤過多時的寬度感知抽稀，避免 X 軸標籤重疊。
            // 以固定曆法產生 30 天逐日資料 (MM/dd 標籤)，對齊真實 trendBars 格式並驗證逐日標籤與捲動邊緣。
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
                    value: Double((offset * 53) % 180 + 20)
                )
            }

            let view = BLBarChart(data: bars, height: 200, isScrollEnabled: true)
                .frame(width: 393)
                .padding()

            assertSnapshot(of: view, as: .image)
        }
    }
}

#endif
