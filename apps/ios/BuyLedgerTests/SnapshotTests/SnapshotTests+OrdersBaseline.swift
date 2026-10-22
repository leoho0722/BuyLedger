//
//  SnapshotTests+OrdersBaseline.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 驗證 iPhone 推入含成本明細的訂單後，保留詳情導覽列與操作工具列
    @Test
    func ordersCompactView_推入含成本明細訂單_符合基準圖() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                let order = Self.makeOrdersBaselineOrder()
                var state = OrdersFeature.State(orders: [order])
                state.refreshDateContext(
                    now: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
                state.load.$hasLoaded.withLock {
                    $0 = true
                }
                state.detail.showDetail(orderID: order.id)

                // When
                let view = OrdersCompactView(
                    store: Store(initialState: state) {
                        OrdersFeature()
                    },
                    language: .traditionalChinese
                )
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .environment(\.calendar, TestDependencies.fixedCalendar)
                    .environment(\.timeZone, TestDependencies.fixedCalendar.timeZone)
                    .environment(\.horizontalSizeClass, .compact)
                    .environment(\.verticalSizeClass, .regular)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
    }

    /// 驗證篩選畫面顯示已選取的本月、美妝與信用卡條件，以及取消與套用按鈕
    @Test
    func orderFilterSheet_已選日期類別付款方式_符合基準圖() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                let filterState = OrderFilterPreviewFixtures.makeState(
                    selection: OrderFilterSelection(
                        datePeriod: .thisMonth,
                        categories: ["美妝"],
                        paymentMethod: "信用卡"
                    )
                )

                // When
                let view = OrderFilterSheet(
                    store: Store(initialState: filterState) {
                        OrderFilterFeature()
                    }
                )
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .environment(\.calendar, TestDependencies.fixedCalendar)
                    .environment(\.timeZone, TestDependencies.fixedCalendar.timeZone)
                    .environment(\.horizontalSizeClass, .compact)
                    .environment(\.verticalSizeClass, .regular)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            }
        }
    }

    /// 驗證兩組同時展開時，長類別名稱完整換行且保留多選標記
    @Test
    func orderFilterSheet_已收單展開含長名稱_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let state = OrderFilterPreviewFixtures.makeState(
                selection: OrderFilterSelection(
                    datePeriod: .thisMonth,
                    categories: ["美妝", "書籍"],
                    paymentMethod: "信用卡"
                )
            )

            // When
            let view = OrderFilterSheet(
                store: Store(initialState: state) {
                    OrderFilterFeature()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.calendar, TestDependencies.fixedCalendar)
                .environment(\.timeZone, TestDependencies.fixedCalendar.timeZone)
                .environment(\.horizontalSizeClass, .compact)
                .environment(\.verticalSizeClass, .regular)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立包含運費與三種手續費的固定訂單，供詳情基準畫面使用
    ///
    /// - Returns: 不讀取系統時間或隨機識別值的訂單
    static func makeOrdersBaselineOrder() -> LedgerOrder {
        LedgerOrder(
            id: "BL-ORDERS-BASELINE-001",
            customer: LedgerCustomer(name: "林書宇", initials: "SY", tier: .vip),
            status: .shipping,
            currency: .jpy,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "示範商品",
                    quantity: 1,
                    unitPrice: 30_000
                ),
            ],
            itemCost: 6_000,
            domesticShipping: 80,
            internationalShipping: 320,
            foreignDomesticShipping: 120,
            cardFeeRate: Decimal(sign: .plus, exponent: -3, significand: 15),
            platformFeeRate: Decimal(sign: .plus, exponent: -2, significand: 3),
            paymentFeeRate: Decimal(sign: .plus, exponent: -3, significand: 5),
            chargedAmount: 10_000,
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
    }
}
