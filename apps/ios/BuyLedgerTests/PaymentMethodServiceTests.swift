//
//  PaymentMethodServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 驗證付款方式 Service 的主檔操作
struct PaymentMethodServiceTests {

    // MARK: - Tests

    /// 讀取付款方式時依自然語言順序排序
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchPaymentMethodInfos_多種名稱_依自然語言順序排序() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addPaymentMethod("Record 10", .none)
        try await service.addPaymentMethod("Record 2", .none)
        try await service.addPaymentMethod("Record 1", .none)

        // When
        let paymentMethods = try await service.fetchPaymentMethodInfos()

        // Then
        #expect(paymentMethods.map(\.name) == ["Record 1", "Record 2", "Record 10"])
    }

    /// 加入付款方式時移除空白並略過空名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未正規化的付款方式名稱
    ///   - expectedNames: 預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [("  銀行匯款  ", ["銀行匯款"]), (" \n\t ", [])])
    func addPaymentMethod_名稱含空白或為空_移除空白並略過空名稱(
        rawName: String,
        expectedNames: [String]
    ) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addPaymentMethod(rawName, .none)

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods.map(\.name) == expectedNames)
    }

    /// 加入付款方式後可讀回各類旗標
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - flags: 要儲存的付款方式旗標
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [
        (
            "貨到付款",
            PaymentMethodFlags(isCardless: false, isBankTransfer: false, isCashOnDelivery: true)
        ),
        (
            "銀行匯款",
            PaymentMethodFlags(isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
        ),
        (
            "無卡存款",
            PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
        ),
    ])
    func addPaymentMethod_各類旗標_讀回相同旗標(name: String, flags: PaymentMethodFlags) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let expectedPaymentMethod = PaymentMethodInfo(name: name, flags: flags)

        // When
        try await service.addPaymentMethod(name, flags)

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods == [expectedPaymentMethod])
    }

    /// 同名新增會以新旗標覆寫舊值
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addPaymentMethod_名稱已存在_以新旗標覆寫舊值() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        try await service.addPaymentMethod("綠界", originalFlags)

        // When
        try await service.addPaymentMethod("綠界", .none)

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods == [PaymentMethodInfo(name: "綠界", flags: .none)])
    }

    /// 同名編輯仍套用新的旗標
    ///
    /// - Throws: 主檔讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   主檔儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   編輯讀取失敗時丟出 `PaymentMethodPersistenceError.storage(.fetchFailed(underlying:))`；
    ///   編輯儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    @Test
    func applyPaymentMethodEdit_名稱不變_仍套用新旗標() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
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
        try await service.addPaymentMethod("匯款", originalFlags)

        // When
        try await service.applyPaymentMethodEdit(
            "匯款",
            "匯款",
            updatedFlags,
            []
        )

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: updatedFlags)])
    }

    /// 刪除符合名稱的付款方式
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removePaymentMethod_名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addPaymentMethod("保留項目", .none)
        try await service.addPaymentMethod("待刪項目", .none)

        // When
        try await service.removePaymentMethod("待刪項目")

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods == [PaymentMethodInfo(name: "保留項目", flags: .none)])
    }

    /// 刪除不存在的付款方式不影響既有記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removePaymentMethod_名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addPaymentMethod("保留項目", .none)

        // When
        try await service.removePaymentMethod("不存在的項目")

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods == [PaymentMethodInfo(name: "保留項目", flags: .none)])
    }
}

// MARK: - Internal Method

extension PaymentMethodServiceTests {

    /// 以注入的資料庫建立正式 `PaymentMethodService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的 `PaymentMethodService`
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> PaymentMethodService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            PaymentMethodService.liveValue
        }
    }

    /// 建立付款方式編輯測試使用的訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - paymentMethod: 付款方式名稱
    ///   - photos: 訂單照片
    ///   - cardlessDeductionAmount: 無卡折讓金額
    ///   - cardlessSupplementAmount: 無卡補貼金額
    ///   - reconciliationStatus: 對帳狀態
    ///   - isCashOnDelivery: 是否為貨到付款
    /// - Returns: 建立的訂單
    static func makePaymentOrder(
        id: String,
        paymentMethod: String,
        photos: [Data] = [],
        cardlessDeductionAmount: Decimal = 750,
        cardlessSupplementAmount: Decimal = 250,
        reconciliationStatus: String = "待對帳",
        isCashOnDelivery: Bool = true
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "付款測試", initials: "PM", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "商品", quantity: 1, unitPrice: 5_000)],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: []
        )
    }

    /// 以新的 Database read context 讀回指定訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - database: 要讀取的資料庫
    /// - Returns: 找到時轉成領域型別的訂單
    /// - Throws: 查詢或記錄轉換失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchOrder(
        id: String,
        from database: any BuyLedgerDatabaseProtocol
    ) async throws(PersistenceError) -> LedgerOrder? {
        try await database.read { context throws(PersistenceError) in
            let descriptor = FetchDescriptor<OrderRecord>(
                predicate: #Predicate {
                    $0.id == id
                }
            )
            let record = try PersistenceError.mapFetch {
                try context.fetch(descriptor).first
            }
            return try record?.toDomain()
        }
    }
}
