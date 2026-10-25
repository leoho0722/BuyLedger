//
//  LookupServicePaymentMethodsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋付款方式主檔，以記憶體內資料庫逐項驗證讀取排序、新增、旗標保存與刪除
struct LookupServicePaymentMethodsTests {

    /// 驗證付款方式名稱含數字時，讀取結果依自然語言順序排序，Record 2 排在 Record 10 之前
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_付款方式多種名稱_依自然語言順序排序() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "Record 10", flags: .none)
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "Record 2", flags: .none)
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "Record 1", flags: .none)
        )

        // When
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods

        // Then
        #expect(paymentMethods.map(\.name) == ["Record 1", "Record 2", "Record 10"])
    }

    /// 驗證加入付款方式時，名稱前後的空白會被移除，只含空白與換行的名稱不寫入
    ///
    /// - Parameter scenario: 尚未正規化的付款方式名稱與預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [
        RawNameScenario(rawName: "  銀行匯款  ", expectedNames: ["銀行匯款"]),
        RawNameScenario(rawName: " \n\t ", expectedNames: []),
    ])
    func addItem_付款方式名稱含空白或為空_移除空白並略過空名稱(scenario: RawNameScenario) async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )

        // When
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: scenario.rawName, flags: .none)
        )

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods.map(\.name) == scenario.expectedNames)
    }

    /// 驗證加入貨到付款、銀行匯款與無卡存款三種旗標的付款方式後，讀回的名稱與旗標都與寫入時相同
    ///
    /// - Parameter scenario: 付款方式名稱與要儲存的付款方式旗標
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [
        PaymentMethodFlagsScenario(
            name: "orders.list.label.cashDelivery",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
        ),
        PaymentMethodFlagsScenario(
            name: "orders.edit.label.bankTransfer",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        ),
        PaymentMethodFlagsScenario(
            name: "無卡存款",
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        ),
    ])
    func addItem_付款方式各類旗標_讀回相同旗標(scenario: PaymentMethodFlagsScenario) async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        let expectedPaymentMethod = PaymentMethodInfo(name: scenario.name, flags: scenario.flags)

        // When
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: scenario.name, flags: scenario.flags)
        )

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [expectedPaymentMethod])
    }

    /// 驗證加入與既有付款方式同名的項目時，只保留一筆，旗標以新值覆寫為 `none`
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_付款方式名稱已存在_以新旗標覆寫舊值() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "綠界", flags: originalFlags)
        )

        // When
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "綠界", flags: .none))

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "綠界", flags: .none)])
    }

    /// 驗證付款方式名稱不變、只改旗標時，`applyPaymentMethodEdit` 仍把主檔旗標更新為新值
    ///
    /// - Throws: 主檔讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   主檔儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func applyPaymentMethodEdit_名稱不變_仍套用新旗標() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        let updatedFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "匯款", flags: originalFlags)
        )

        // When
        _ = try await service.applyPaymentMethodEdit("匯款", "匯款", updatedFlags)

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: updatedFlags)])
    }

    /// 驗證 `removeItem` 依名稱刪除相符的付款方式，同時保留其他項目
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_付款方式名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "保留項目", flags: .none))
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "待刪項目", flags: .none))

        // When
        try await service.removeItem(.paymentMethod, "待刪項目")

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "保留項目", flags: .none)])
    }

    /// 驗證刪除不存在的名稱時不丟錯，既有的付款方式原樣保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_付款方式名稱不存在_保留既有記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "保留項目", flags: .none))

        // When
        try await service.removeItem(.paymentMethod, "不存在的項目")

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "保留項目", flags: .none)])
    }
}

// MARK: - Nested Types

extension LookupServicePaymentMethodsTests {

    /// `addItem` 名稱正規化測試的參數案例，帶入原始名稱與預期讀回的名稱
    struct RawNameScenario: Sendable {

        /// 尚未正規化的名稱
        let rawName: String

        /// 預期讀回的名稱
        let expectedNames: [String]
    }

    /// `addItem` 旗標讀回測試的參數案例，帶入付款方式名稱與要儲存的旗標
    struct PaymentMethodFlagsScenario: Sendable {

        /// 付款方式名稱
        let name: String

        /// 要儲存的付款方式旗標
        let flags: PaymentMethodFlags
    }
}
