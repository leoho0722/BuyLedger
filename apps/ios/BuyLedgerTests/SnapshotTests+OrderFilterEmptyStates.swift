//
//  SnapshotTests+OrderFilterEmptyStates.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/19.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 寬版清單欄在主檔與訂單都沒有付款方式與類別時，不顯示付款方式 Menu 與類別觸發鈕
    ///
    /// - Note: 只拍清單欄，三欄組合由 `OrderRegularColumnScopeTests` 守
    /// - Note: 離屏渲染畫不出工具列項目，筆數、「⋯」「+」與多選控制項由 `OrderRegularColumnScopeTests` 守
    @Test
    func ordersView_寬版清單欄無付款方式與類別_符合基準圖() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                let order = Self.makeOptionlessOrder()
                var state = OrdersFeature.State(orders: [order])
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
                .environment(\.calendar, TestDependencies.fixedCalendar)
                .environment(\.timeZone, TestDependencies.fixedCalendar.timeZone)
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .regular)
                .frame(width: 320, height: 768)

                // Then
                assertSnapshot(of: view, as: .image)
            }
        }
    }

    /// iPhone 篩選 sheet 搜尋不命中任何類別時，只剩「全部」列與沒有符合的類別空狀態列
    @Test
    func orderFilterSheet_搜尋無符合類別_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = Self.makeFilterState(categories: ["beauty", "snacks"])
            state.filterSheetSearchText = "無此類別"

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

    /// iPad 類別選擇器搜尋不命中任何類別時，只剩「全部」列與沒有符合的類別空狀態列
    @Test
    func orderCategoryPickerSheet_搜尋無符合類別_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = Self.makeCategoryPickerState(categories: ["beauty", "snacks"])
            state.searchText = "無此類別"

            // When
            let view = OrderCategoryPickerSheet(
                store: Store(initialState: state) {
                    OrderCategoryPickerFeature()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.calendar, TestDependencies.fixedCalendar)
                .environment(\.timeZone, TestDependencies.fixedCalendar.timeZone)
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .regular)
                .frame(width: 540, height: 620)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立沒有付款方式與類別的固定訂單，供寬版清單的隱藏篩選觸發鈕測試使用
    ///
    /// - Returns: 不讀取系統時間或隨機識別值的訂單
    static func makeOptionlessOrder() -> LedgerOrder {
        LedgerOrder(
            id: "BL-ORDERS-OPTIONLESS-001",
            customer: LedgerCustomer(name: "", initials: "", tier: .regular),
            status: .purchased,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立只含指定類別、沒有訂單與開團的篩選狀態
    ///
    /// - Parameter categories: 主檔的類別
    /// - Returns: 篩選狀態，未套用任何條件
    static func makeFilterState(categories: [String]) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(
                value: LookupCatalog(categories: categories, paymentMethods: [])
            ),
            committedFilterSelection: OrderFilterSelection(),
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }

    /// 建立只含指定類別、沒有訂單與開團的類別選擇器狀態
    ///
    /// - Parameter categories: 主檔的類別
    /// - Returns: 類別選擇器狀態，未選取任何類別
    static func makeCategoryPickerState(categories: [String]) -> OrderCategoryPickerFeature.State {
        OrderCategoryPickerFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(
                value: LookupCatalog(categories: categories, paymentMethods: [])
            ),
            committedCategories: [],
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }
}
