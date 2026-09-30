//
//  LookupCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Testing

@testable import BuyLedger

/// 驗證主檔目錄的新增、移除、改名與旗標查詢規則
struct LookupCatalogTests {

    // MARK: - Properties

    /// 第一筆付款方式只有銀行匯款旗標
    private static let bankTransferFlags = PaymentMethodFlags(
        isCardless: false,
        isBankTransfer: true,
        isCashOnDelivery: false
    )

    /// 第二筆付款方式只有無卡旗標
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
            name: "貨到付款",
            expectedFlags: .none
        ),
    ]

    // MARK: - Tests

    /// 新增名稱只有主檔的項目後依本地排序呈現
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func addingNameOnlyKindInsertsSorted(kind: LookupKind) {
        // Given：目錄尚無此種類的項目
        var catalog = LookupCatalog()

        // When：加入兩個不同名稱
        catalog.add(name: "蘋果", kind: kind)
        catalog.add(name: "香蕉", kind: kind)

        // Then：名稱依繁體中文排序
        #expect(catalog.names(for: kind) == ["香蕉", "蘋果"])
    }

    /// 空白名稱不會新增到只有名稱的主檔
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func addingBlankNameIsNoOp(kind: LookupKind) {
        // Given：目錄沒有該種類的項目
        var catalog = LookupCatalog()

        // When：新增只有空白的名稱
        catalog.add(name: "   ", kind: kind)

        // Then：該種類仍是空清單
        #expect(catalog.names(for: kind).isEmpty)
    }

    /// 移除只有名稱的主檔項目
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func removingNameOnlyKindDeletesEntry(kind: LookupKind) {
        // Given：目錄已有一個項目
        var catalog = LookupCatalog()
        catalog.add(name: "既有", kind: kind)

        // When：移除該項目
        catalog.remove(name: "既有", kind: kind)

        // Then：該種類不再包含項目
        #expect(catalog.names(for: kind).isEmpty)
    }

    /// 更名只有名稱的主檔項目
    ///
    /// - Parameter kind: 要測試的主檔種類
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func renamingNameOnlyKindReplacesOldName(kind: LookupKind) {
        // Given：目錄已有舊名稱
        var catalog = LookupCatalog()
        catalog.add(name: "舊名", kind: kind)

        // When：將舊名稱改為新名稱
        catalog.rename(from: "舊名", to: "新名", kind: kind)

        // Then：目錄只保留新名稱
        #expect(catalog.names(for: kind) == ["新名"])
    }

    /// 新增付款方式時保存其分類旗標
    @Test
    func addingPaymentMethodStoresFlags() {
        // Given：目錄尚無付款方式
        var catalog = LookupCatalog()

        // When：新增帶無卡旗標的付款方式
        catalog.add(
            name: "無卡存款",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        )

        // Then：目錄保存該付款方式與旗標
        #expect(
            catalog.paymentMethods == [
                PaymentMethodInfo(
                    name: "無卡存款",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                )
            ]
        )
    }

    /// 同名付款方式再次新增時以新旗標覆寫原項目
    @Test
    func addingPaymentMethodSameNameOverwritesFlags() {
        // Given：目錄已存在沒有旗標的付款方式
        var catalog = LookupCatalog()
        catalog.add(
            name: "綠界",
            kind: .paymentMethod,
            flags: .none
        )

        // When：以銀行匯款旗標再次新增同名項目
        catalog.add(
            name: "綠界",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )

        // Then：目錄只有一筆且採用新旗標
        #expect(catalog.paymentMethods.count == 1)
        #expect(catalog.paymentMethods.first?.isBankTransfer == true)
    }

    /// 移除付款方式時刪除對應項目
    @Test
    func removingPaymentMethodDeletesEntry() {
        // Given：目錄已有貨到付款
        var catalog = LookupCatalog()
        catalog.add(
            name: "貨到付款",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
        )

        // When：移除貨到付款
        catalog.remove(name: "貨到付款", kind: .paymentMethod)

        // Then：目錄不再包含付款方式
        #expect(catalog.paymentMethods.isEmpty)
    }

    /// 重新命名付款方式時，任一方為真的旗標都應保留下來
    ///
    /// - Throws: 合併後付款方式不存在時拋出測試錯誤
    @Test
    func renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue() throws {
        // Given：同一付款方式的新舊名稱各有不同旗標
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
            name: "銀行匯款",
            kind: .paymentMethod,
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
        )

        // When：將舊付款方式名稱改成已存在的新名稱
        catalog.rename(from: "匯款", to: "銀行匯款", kind: .paymentMethod)

        // Then：合併後保留任一來源曾設定的每個旗標
        #expect(catalog.names(for: .paymentMethod) == ["銀行匯款"])
        let renamed = try #require(catalog.paymentMethods.first { $0.name == "銀行匯款" })
        #expect(renamed.isCardless)
        #expect(renamed.isBankTransfer)
        #expect(renamed.isCashOnDelivery)
    }

    /// 查詢重複名稱時採用第一筆的分類旗標
    ///
    /// - Parameter example: 目錄內容、查詢名稱與預期旗標
    @Test(arguments: LookupCatalogTests.paymentMethodFlagLookupExamples)
    func paymentMethodFlagsUsesFirstMatchingEntry(example: PaymentMethodFlagLookupExample) {
        // Given：目錄包含指定順序的付款方式
        let catalog = LookupCatalog(paymentMethods: example.entries)

        // When：依名稱查詢分類旗標
        let flags = catalog.paymentMethodFlags(named: example.name)

        // Then：回傳第一筆同名項目的旗標或沒有旗標
        #expect(flags == example.expectedFlags)
    }

    /// 只替換指定主檔種類的清單
    ///
    /// - Parameter kind: 要替換的主檔種類
    @Test(arguments: LookupKind.allCases)
    func replaceItemsChangesOnlyRequestedKind(kind: LookupKind) {
        // Given：原目錄與載入完成的新目錄都有四種主檔項目
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
        let expectedPaymentMethods = kind == .paymentMethod
            ? fetchedCatalog.paymentMethods
            : [PaymentMethodInfo(name: "舊付款", flags: .none)]

        // When：以新目錄替換指定種類
        catalog.replaceItems(of: kind, from: fetchedCatalog)

        // Then：只有指定種類更新，其餘清單保留舊值
        #expect(catalog.orderSources == (kind == .orderSource ? ["新來源"] : ["舊來源"]))
        #expect(catalog.categories == (kind == .category ? ["新分類"] : ["舊分類"]))
        #expect(
            catalog.paymentMethods == expectedPaymentMethods
        )
        #expect(
            catalog.reconciliationStatuses
                == (kind == .reconciliationStatus ? ["新狀態"] : ["舊狀態"])
        )
    }

    /// 新名稱為空白時不更動原項目
    @Test
    func renamingToBlankNameIsNoOp() {
        // Given：目錄已有舊名稱
        var catalog = LookupCatalog()
        catalog.add(name: "舊名", kind: .category)

        // When：使用空白名稱更名
        catalog.rename(from: "舊名", to: "   ", kind: .category)

        // Then：原名稱仍保留
        #expect(catalog.names(for: .category) == ["舊名"])
    }

    /// 新名稱與原名稱相同時不更動項目
    @Test
    func renamingToSameNameIsNoOp() {
        // Given：目錄已有一個名稱
        var catalog = LookupCatalog()
        catalog.add(name: "同名", kind: .category)

        // When：以相同名稱更名
        catalog.rename(from: "同名", to: "同名", kind: .category)

        // Then：原名稱保持不變
        #expect(catalog.names(for: .category) == ["同名"])
    }
}

// MARK: - Nested Types

extension LookupCatalogTests {

    /// 一筆付款方式旗標查詢測試資料
    struct PaymentMethodFlagLookupExample: Sendable {

        /// 查詢目錄中的付款方式
        let entries: [PaymentMethodInfo]

        /// 要查詢的付款方式名稱
        let name: String

        /// 預期取得的付款方式旗標
        let expectedFlags: PaymentMethodFlags
    }
}
