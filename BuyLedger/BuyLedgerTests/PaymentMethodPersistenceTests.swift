//
//  PaymentMethodPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

@MainActor
struct PaymentMethodPersistenceTests {

    // MARK: - Tests

    @Test func upsertPersistsBothFlagsRoundTrip() async throws {
        let persistence = try makePersistence()

        try await persistence.upsert(name: "銀行匯款", isCardless: false, isBankTransfer: true)
        try await persistence.upsert(name: "無卡存款", isCardless: true, isBankTransfer: false)

        let infos = try await persistence.fetchAllInfos()
        let bankTransfer = infos.first { $0.name == "銀行匯款" }
        let cardless = infos.first { $0.name == "無卡存款" }

        #expect(bankTransfer?.isBankTransfer == true)
        #expect(bankTransfer?.isCardless == false)
        #expect(cardless?.isCardless == true)
        #expect(cardless?.isBankTransfer == false)
    }

    @Test func upsertSameNameOverwritesFlags() async throws {
        let persistence = try makePersistence()

        try await persistence.upsert(name: "綠界", isCardless: false, isBankTransfer: false)
        // 二次新增同名：以新旗標覆寫 (使用者上次忘了勾選銀行匯款，這次更正)。
        try await persistence.upsert(name: "綠界", isCardless: false, isBankTransfer: true)

        let infos = try await persistence.fetchAllInfos()
        #expect(infos.count == 1)
        #expect(infos.first?.isBankTransfer == true)
    }

    @Test func renamePreservesBankTransferFlag() async throws {
        let persistence = try makePersistence()
        try await persistence.upsert(name: "匯款", isCardless: false, isBankTransfer: true)

        try await persistence.rename(from: "匯款", to: "銀行匯款")

        let infos = try await persistence.fetchAllInfos()
        let renamed = infos.first { $0.name == "銀行匯款" }
        #expect(infos.contains { $0.name == "匯款" } == false)
        #expect(renamed?.isBankTransfer == true, "更名應保留 isBankTransfer 旗標")
    }
}

// MARK: - Helpers

private extension PaymentMethodPersistenceTests {

    /// 用 in-memory 的 ``ModelContainer`` 建立每個測試獨立的 ``PaymentMethodPersistence``。
    /// - Returns: 不污染 production store 的測試 actor。
    func makePersistence() throws -> PaymentMethodPersistence {
        let container = try PersistenceContainer.make(inMemoryOnly: true)
        return PaymentMethodPersistence(modelContainer: container)
    }
}
