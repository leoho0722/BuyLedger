//
//  LookupCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Testing

@testable import BuyLedger

/// `LookupCatalog` 的單元測試，涵蓋新增、移除、改名與旗標查詢規則
struct LookupCatalogTests {

    // MARK: - Properties

    /// 只含銀行匯款旗標的付款方式旗標
    private static let bankTransferFlags = PaymentMethodFlags(
        isCardless: false,
        isBankTransfer: true,
        isCashOnDelivery: false
    )

    /// 只含無卡旗標的付款方式旗標
    private static let cardlessFlags = PaymentMethodFlags(
        isCardless: true,
        isBankTransfer: false,
        isCashOnDelivery: false
    )

    /// 規格範例表列出的三種付款方式旗標查詢情境
    private static let paymentMethodFlagLookupExamples: [PaymentMethodFlagLookupExample] = [
        PaymentMethodFlagLookupExample(
            entries: [
                PaymentMethodInfo(name: "匯款", flags: Self.bankTransferFlags),
                PaymentMethodInfo(name: "匯款", flags: Self.cardlessFlags),
            ],
            name: "匯款",
            expectedFlags: Self.bankTransferFlags
        ),
        PaymentMethodFlagLookupExample(
            entries: [PaymentMethodInfo(name: "信用卡", flags: .none)],
            name: "信用卡",
            expectedFlags: .none
        ),
        PaymentMethodFlagLookupExample(
            entries: [PaymentMethodInfo(name: "信用卡", flags: .none)],
            name: "orders.list.label.cashDelivery",
            expectedFlags: .none
        ),
    ]

    /// 四種主檔各自替換時的預期結果，只有指定種類更新，其餘清單保留舊值
    private static let replaceItemsScenarios: [ReplaceItemsScenario] = [
        ReplaceItemsScenario(
            kind: .orderSource,
            expectedOrderSources: ["新來源"],
            expectedCategories: ["舊分類"],
            expectedPaymentMethods: [PaymentMethodInfo(name: "舊付款", flags: .none)],
            expectedReconciliationStatuses: ["舊狀態"]
        ),
        ReplaceItemsScenario(
            kind: .category,
            expectedOrderSources: ["舊來源"],
            expectedCategories: ["新分類"],
            expectedPaymentMethods: [PaymentMethodInfo(name: "舊付款", flags: .none)],
            expectedReconciliationStatuses: ["舊狀態"]
        ),
        ReplaceItemsScenario(
            kind: .paymentMethod,
            expectedOrderSources: ["舊來源"],
            expectedCategories: ["舊分類"],
            expectedPaymentMethods: [PaymentMethodInfo(name: "新付款", flags: .none)],
            expectedReconciliationStatuses: ["舊狀態"]
        ),
        ReplaceItemsScenario(
            kind: .reconciliationStatus,
            expectedOrderSources: ["舊來源"],
            expectedCategories: ["舊分類"],
            expectedPaymentMethods: [PaymentMethodInfo(name: "舊付款", flags: .none)],
            expectedReconciliationStatuses: ["新狀態"]
        ),
    ]

    /// 驗證只有名稱的主檔已有一個項目時，再新增另一個名稱，兩者依繁體中文排序呈現
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func add_只有名稱的種類_依本地排序插入(kind: LookupKind) {
        // Given
        var catalog = LookupCatalog()
        catalog.add(name: "蘋果", kind: kind)

        // When
        catalog.add(name: "香蕉", kind: kind)

        // Then
        #expect(catalog.names(for: kind) == ["香蕉", "蘋果"])
    }

    /// 驗證只有名稱的主檔沒有項目時，新增只有空白的名稱，該種類仍是空清單
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func add_空白名稱_不新增項目(kind: LookupKind) {
        // Given
        var catalog = LookupCatalog()

        // When
        catalog.add(name: "   ", kind: kind)

        // Then
        #expect(catalog.names(for: kind).isEmpty)
    }

    /// 驗證只有名稱的主檔已有一個項目時，移除後該種類不再包含該項目
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func remove_只有名稱的種類_刪除該項目(kind: LookupKind) {
        // Given
        var catalog = LookupCatalog()
        catalog.add(name: "既有", kind: kind)

        // When
        catalog.remove(name: "既有", kind: kind)

        // Then
        #expect(catalog.names(for: kind).isEmpty)
    }

    /// 驗證只有名稱的主檔改名後，目錄只保留新名稱
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func rename_只有名稱的種類_以新名稱取代舊名稱(kind: LookupKind) {
        // Given
        var catalog = LookupCatalog()
        catalog.add(name: "舊名", kind: kind)

        // When
        catalog.rename(from: "舊名", to: "新名", kind: kind)

        // Then
        #expect(catalog.names(for: kind) == ["新名"])
    }

    /// 驗證目錄尚無付款方式時，新增帶無卡旗標的付款方式，目錄保存該付款方式與旗標
    @Test
    func add_付款方式_保存分類旗標() {
        // Given
        var catalog = LookupCatalog()

        // When
        catalog.add(
            name: "無卡存款",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        )

        // Then
        #expect(
            catalog.paymentMethods == [
                PaymentMethodInfo(
                    name: "無卡存款",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ]
        )
    }

    /// 驗證目錄已有同名的無旗標付款方式時，以銀行匯款旗標再次新增，目錄只留一筆且採用新旗標
    @Test
    func add_付款方式同名_以新旗標覆寫() {
        // Given
        var catalog = LookupCatalog()
        catalog.add(name: "綠界", kind: .paymentMethod, flags: .none)

        // When
        catalog.add(
            name: "綠界",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )

        // Then
        #expect(catalog.paymentMethods.count == 1)
        #expect(catalog.paymentMethods.first?.isBankTransfer == true)
    }

    /// 驗證目錄已有貨到付款方式時，移除後 `paymentMethods` 為空
    @Test
    func remove_付款方式_刪除對應項目() {
        // Given
        var catalog = LookupCatalog()
        catalog.add(
            name: "orders.list.label.cashDelivery",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
        )

        // When
        catalog.remove(name: "orders.list.label.cashDelivery", kind: .paymentMethod)

        // Then
        #expect(catalog.paymentMethods.isEmpty)
    }

    /// 驗證付款方式改名到已存在的名稱時，合併結果保留新舊兩側任一為真的旗標
    ///
    /// - Throws: 合併後付款方式不存在時丟出測試錯誤
    @Test
    func rename_付款方式合併_保留任一方為真的旗標() throws {
        // Given
        var catalog = LookupCatalog()
        catalog.add(
            name: "匯款",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )
        catalog.add(
            name: "orders.edit.label.bankTransfer",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
        )

        // When
        catalog.rename(from: "匯款", to: "orders.edit.label.bankTransfer", kind: .paymentMethod)

        // Then
        #expect(catalog.names(for: .paymentMethod) == ["orders.edit.label.bankTransfer"])
        let renamed = try #require(
            catalog.paymentMethods.first { $0.name == "orders.edit.label.bankTransfer" }
        )
        #expect(renamed.isCardless)
        #expect(renamed.isBankTransfer)
        #expect(renamed.isCashOnDelivery)
    }

    /// 驗證目錄包含重複名稱時，`paymentMethodFlags(named:)` 回傳第一筆同名項目的旗標
    ///
    /// - Parameter example: 目錄內容、查詢名稱與預期旗標
    @Test(arguments: LookupCatalogTests.paymentMethodFlagLookupExamples)
    func paymentMethodFlags_重複名稱_採用第一筆的旗標(example: PaymentMethodFlagLookupExample) {
        // Given
        let catalog = LookupCatalog(paymentMethods: example.entries)

        // When
        let flags = catalog.paymentMethodFlags(named: example.name)

        // Then
        #expect(flags == example.expectedFlags)
    }

    /// 驗證原目錄與新目錄都有四種主檔項目時，`replaceItems(of:from:)` 只替換指定種類，其餘清單保留舊值
    ///
    /// - Parameter scenario: 要替換的主檔種類與替換後四種清單的預期值
    @Test(arguments: LookupCatalogTests.replaceItemsScenarios)
    func replaceItems_指定種類_只更新該種類(scenario: ReplaceItemsScenario) {
        // Given
        var catalog = LookupCatalog(
            orderSources: ["舊來源"],
            categories: ["舊分類"],
            paymentMethods: [PaymentMethodInfo(name: "舊付款", flags: .none)],
            reconciliationStatuses: ["舊狀態"]
        )
        let fetchedCatalog = LookupCatalog(
            orderSources: ["新來源"],
            categories: ["新分類"],
            paymentMethods: [PaymentMethodInfo(name: "新付款", flags: .none)],
            reconciliationStatuses: ["新狀態"]
        )

        // When
        catalog.replaceItems(of: scenario.kind, from: fetchedCatalog)

        // Then
        #expect(catalog.orderSources == scenario.expectedOrderSources)
        #expect(catalog.categories == scenario.expectedCategories)
        #expect(catalog.paymentMethods == scenario.expectedPaymentMethods)
        #expect(catalog.reconciliationStatuses == scenario.expectedReconciliationStatuses)
    }

    /// 驗證目錄已有舊名稱時，以空白名稱更名，原名稱仍保留
    @Test
    func rename_新名稱為空白_不更動原項目() {
        // Given
        var catalog = LookupCatalog()
        catalog.add(name: "舊名", kind: .category)

        // When
        catalog.rename(from: "舊名", to: "   ", kind: .category)

        // Then
        #expect(catalog.names(for: .category) == ["舊名"])
    }

    /// 驗證目錄已有一個名稱時，以相同名稱更名，項目保持不變
    @Test
    func rename_新名稱與原名稱相同_不更動項目() {
        // Given
        var catalog = LookupCatalog()
        catalog.add(name: "同名", kind: .category)

        // When
        catalog.rename(from: "同名", to: "同名", kind: .category)

        // Then
        #expect(catalog.names(for: .category) == ["同名"])
    }
}

// MARK: - Nested Types

extension LookupCatalogTests {

    /// 一筆付款方式旗標查詢測試資料
    struct PaymentMethodFlagLookupExample: Sendable {

        /// 目錄內的付款方式項目
        let entries: [PaymentMethodInfo]

        /// 查詢用的付款方式名稱
        let name: String

        /// 預期的付款方式旗標
        let expectedFlags: PaymentMethodFlags
    }

    /// 一組要替換的主檔種類與替換後四種清單的預期值
    struct ReplaceItemsScenario: Sendable {

        /// 要替換的主檔種類
        let kind: LookupKind

        /// 替換後的訂單來源清單
        let expectedOrderSources: [String]

        /// 替換後的商品類別清單
        let expectedCategories: [String]

        /// 替換後的付款方式清單
        let expectedPaymentMethods: [PaymentMethodInfo]

        /// 替換後的對帳狀態清單
        let expectedReconciliationStatuses: [String]
    }
}
