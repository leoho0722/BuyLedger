//
//  OrderFilterFeatureTests+Queries.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderFilterFeatureTests {

    /// 任一暫存欄位不同時才視為未套用變更
    ///
    /// - Parameters:
    ///   - date: 暫存日期
    ///   - category: 暫存類別
    ///   - paymentMethod: 暫存付款方式
    ///   - hasUnappliedChanges: 是否應視為未套用變更
    @Test(arguments: [
        (OrderDatePeriod.all, nil as String?, nil as String?, false),
        (.thisMonth, nil, nil, true),
        (.all, "美妝", nil, true),
        (.all, nil, "信用卡", true),
        (.all, "", nil, true),
    ])
    func hasUnappliedFilterChanges_比較三欄暫存_判斷是否有變更(
        date: OrderDatePeriod,
        category: String?,
        paymentMethod: String?,
        hasUnappliedChanges: Bool
    ) {
        // Given
        var state = Self.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: date,
            category: category,
            paymentMethod: paymentMethod
        )

        // When
        let hasUnappliedFilterChanges = state.hasUnappliedFilterChanges

        // Then
        #expect(hasUnappliedFilterChanges == hasUnappliedChanges)
    }

    /// 類別合併主檔與訂單使用值後，以原規則搜尋
    ///
    /// - Parameters:
    ///   - searchText: 面板搜尋文字
    ///   - expectedCategories: 獨立字面值的相符類別
    @Test(arguments: [
        ("BOO", ["books"]),
        ("  boo \n", ["books"]),
        ("", ["beauty", "books", "snacks"]),
        ("不存在", []),
    ])
    func filterSheetFilteredCategories_搜尋主檔與訂單類別_回傳相符名稱(
        searchText: String,
        expectedCategories: [String]
    ) {
        // Given
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                OrdersFeatureTests.makeOrder(id: "A", category: " books "),
            ]),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: ["beauty", "snacks"])),
            committedFilterSelection: OrderFilterSelection()
        )
        state.filterSheetSearchText = searchText

        // When
        let categories = state.filterSheetFilteredCategories

        // Then
        #expect(categories == expectedCategories)
    }

    /// 付款方式沿用去除搜尋空白與不分大小寫的比對
    ///
    /// - Parameters:
    ///   - searchText: 面板搜尋文字
    ///   - expectedPaymentMethods: 獨立字面值的相符付款方式
    @Test(arguments: [
        ("CAR", ["Card"]),
        ("  car \n", ["Card"]),
        ("", ["Card", "Cash"]),
        ("不存在", []),
    ])
    func filterSheetFilteredPaymentMethods_搜尋付款方式_回傳相符名稱(
        searchText: String,
        expectedPaymentMethods: [String]
    ) {
        // Given
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                OrdersFeatureTests.makeOrder(id: "A", category: "美妝", paymentMethod: " Cash "),
            ]),
            lookupCatalog: SharedReader(
                value: LookupCatalog(paymentMethods: [
                    PaymentMethodInfo(
                        name: "Card",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ])
            ),
            committedFilterSelection: OrderFilterSelection()
        )
        state.filterSheetSearchText = searchText

        // When
        let paymentMethods = state.filterSheetFilteredPaymentMethods

        // Then
        #expect(paymentMethods == expectedPaymentMethods)
    }

    /// 開啟後更新共用主檔時，子層讀到更新後的選項
    @Test
    func filterSheetFilteredCategories_共用主檔更新_讀取最新選項() {
        // Given
        let catalog = Shared<LookupCatalog>(value: LookupCatalog())
        catalog.withLock {
            $0.categories = ["beauty"]
        }
        let state = OrderFilterFeature.State(
            orders: SharedReader(value: []),
            lookupCatalog: SharedReader(catalog),
            committedFilterSelection: OrderFilterSelection()
        )

        // When
        catalog.withLock {
            $0.categories = ["books"]
        }

        // Then
        #expect(state.filterSheetFilteredCategories == ["books"])
    }

    /// 搜尋欄的雙向繫結只更新子層搜尋文字
    @Test
    func binding_輸入篩選搜尋文字_更新子層搜尋() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderFilterFeature()
        }

        // When
        await store.send(\.binding.filterSheetSearchText, "boo") {
            $0.filterSheetSearchText = "boo"
        }

        // Then
        #expect(store.state.filterSheetSearchText == "boo")
        #expect(store.state.hasUnappliedFilterChanges == false)
    }

    /// 面板沿用共用訂單引用，載入或寫入後的類別立即反映
    @Test
    func filterSheetFilteredCategories_共用訂單更新_讀取最新選項() {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [OrdersFeatureTests.makeOrder(id: "A", category: "beauty")]
        }
        let state = OrderFilterFeature.State(
            orders: SharedReader(orders),
            lookupCatalog: SharedReader(value: LookupCatalog()),
            committedFilterSelection: OrderFilterSelection()
        )

        // When
        orders.withLock {
            $0 = [OrdersFeatureTests.makeOrder(id: "B", category: "books")]
        }

        // Then
        #expect(state.filterSheetFilteredCategories == ["books"])
    }
}
