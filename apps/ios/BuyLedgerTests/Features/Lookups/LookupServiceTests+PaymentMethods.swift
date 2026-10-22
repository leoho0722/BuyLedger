//
//  LookupServiceTests+PaymentMethods.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

extension LookupServiceTests {

    /// 讀取付款方式時依自然語言順序排序
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_付款方式多種名稱_依自然語言順序排序() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
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

    /// 加入付款方式時移除空白並略過空名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未正規化的付款方式名稱
    ///   - expectedNames: 預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [("  銀行匯款  ", ["銀行匯款"]), (" \n\t ", [])])
    func addItem_付款方式名稱含空白或為空_移除空白並略過空名稱(rawName: String, expectedNames: [String]) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addItem(.paymentMethod, LookupItemAddition(name: rawName, flags: .none))

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
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
            "orders.list.label.cashDelivery",
            PaymentMethodFlags(isCardless: false, isBankTransfer: false, isCashOnDelivery: true)
        ),
        (
            "orders.edit.label.bankTransfer",
            PaymentMethodFlags(isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
        ),
        (
            "無卡存款",
            PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
        ),
    ])
    func addItem_付款方式各類旗標_讀回相同旗標(name: String, flags: PaymentMethodFlags) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let expectedPaymentMethod = PaymentMethodInfo(name: name, flags: flags)

        // When
        try await service.addItem(.paymentMethod, LookupItemAddition(name: name, flags: flags))

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [expectedPaymentMethod])
    }

    /// 同名新增會以新旗標覆寫舊值
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_付款方式名稱已存在_以新旗標覆寫舊值() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
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

    /// 同名編輯仍套用新的旗標
    ///
    /// - Throws: 主檔讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   主檔儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
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

    /// 刪除符合名稱的付款方式
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_付款方式名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "保留項目", flags: .none))
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "待刪項目", flags: .none))

        // When
        try await service.removeItem(.paymentMethod, "待刪項目")

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "保留項目", flags: .none)])
    }

    /// 刪除不存在的付款方式不影響既有記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_付款方式名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "保留項目", flags: .none))

        // When
        try await service.removeItem(.paymentMethod, "不存在的項目")

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "保留項目", flags: .none)])
    }
}
