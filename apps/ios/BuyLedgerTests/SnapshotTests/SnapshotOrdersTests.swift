//
//  SnapshotOrdersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersCompactView` 與 `OrdersView` 的快照測試，涵蓋各尺寸分類與多選模式
@MainActor
struct SnapshotOrdersTests {

    /// 驗證 iPhone 寬度的訂單清單載入全部範例訂單後，畫面符合基準圖
    @Test
    func ordersCompactView_一般訂單清單_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.load.$hasLoaded.withLock {
                $0 = true
            }

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

    /// 驗證客戶名稱與商品類別很長時，訂單列不會把頁面撐寬，左右邊距維持正常，畫面符合基準圖
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

            var state = OrdersFeature.State(orders: [longOrder])
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.load.$hasLoaded.withLock {
                $0 = true
            }

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

    /// 驗證 iPhone 寬度的訂單清單進入多選並勾選第一筆時，顯示勾選狀態與多選工具列，畫面符合基準圖
    ///
    /// - Note: 窄版與寬版的勾選列與多選工具列是同一組畫面元件
    @Test
    func ordersCompactView_多選模式_顯示勾選與工具列() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.load.$hasLoaded.withLock {
                $0 = true
            }
            state.list.isSelecting = true
            state.list.selectedOrderIDs = [LedgerOrder.sampleOrders[0].id]

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

    /// 驗證寬版清單欄進入多選並勾選第一筆時，清單顯示選取列，畫面符合基準圖
    ///
    /// - Note: 只拍清單欄，三欄組合由 `OrderRegularColumnScopeTests` 守
    /// - Note: 離屏渲染畫不出工具列項目，筆數、「⋯」「+」與多選控制項由 `OrderRegularColumnScopeTests` 守
    /// - Note: 水平與垂直尺寸分類都設為 `.regular` 模擬 iPad 版面，不需要 iPad 模擬器
    /// - Note: 使用離屏快照，避免 key window 尺寸造成不穩定
    @Test
    func ordersView_寬版清單欄多選模式_顯示選取列() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.load.$hasLoaded.withLock {
                $0 = true
            }
            state.list.isSelecting = true
            state.list.selectedOrderIDs = [LedgerOrder.sampleOrders[0].id]

            // When
            let view = NavigationStack {
                OrdersView(
                    store: Store(initialState: state) {
                        OrdersFeature()
                    },
                    language: .traditionalChinese
                )
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .regular)
                .frame(width: 320, height: 768)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證寬版清單欄在最大輔助字級時，篩選膠囊不重疊，畫面符合基準圖
    ///
    /// - Note: 只拍清單欄，三欄組合由 `OrderRegularColumnScopeTests` 守
    /// - Note: 離屏渲染畫不出工具列項目，筆數、「⋯」「+」與多選控制項由 `OrderRegularColumnScopeTests` 守
    /// - Note: 水平與垂直尺寸分類都設為 `.regular` 模擬 iPad 版面，不需要 iPad 模擬器
    /// - Note: 使用離屏快照，避免 key window 尺寸造成不穩定
    @Test
    func ordersView_寬版清單欄最大輔助字級_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.load.$hasLoaded.withLock {
                $0 = true
            }

            // When
            let view = NavigationStack {
                OrdersView(
                    store: Store(initialState: state) {
                        OrdersFeature()
                    },
                    language: .traditionalChinese
                )
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .regular)
                .environment(\.dynamicTypeSize, .accessibility5)
                .frame(width: 320, height: 768)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證大尺寸 iPhone 橫向 (水平 `regular`、垂直 `compact`，956 × 440) 的訂單頁，維持單欄清單與整合篩選鈕，畫面符合基準圖
    ///
    /// - Note: 以 `OrdersView` 為受測的 `View` 才會依螢幕尺寸切換版面
    /// - Note: 畫面中沒有側邊詳情欄
    /// - Note: 使用離屏快照，避免 key window 是直向 iPhone 而裁切
    @Test
    func ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.load.$hasLoaded.withLock {
                $0 = true
            }

            // When
            let view = OrdersView(
                store: Store(initialState: state) {
                    OrdersFeature()
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
}
