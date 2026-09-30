//
//  OrderServiceTests+Merge.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 合併新增訂單並標記來源且保留其他樣本
    ///
    /// - Throws: 合併時以 `OrderPersistenceError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；未取得來源或合併後訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_合併訂單_新增結果並只標記已耗用來源() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let samples = LedgerOrder.sampleOrders
        try await Self.seed(samples, database: database)
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let primary = try #require(samples.first { $0.id == primaryID })
        let secondary = try #require(samples.first { $0.id == secondaryID })
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Date(timeIntervalSince1970: 1_777_000_000),
            isCardless: { _ in false }
        )
        let merged = LedgerOrder(
            id: "BL-MERGED-001",
            customer: draft.customer,
            status: draft.status,
            currency: draft.currency,
            date: draft.date,
            items: draft.items,
            itemCost: draft.itemCost,
            domesticShipping: draft.domesticShipping,
            internationalShipping: draft.internationalShipping,
            foreignDomesticShipping: draft.foreignDomesticShipping,
            cardFeeRate: draft.cardFeeRate,
            platformFeeRate: draft.platformFeeRate,
            paymentFeeRate: draft.paymentFeeRate,
            chargedAmount: draft.chargedAmount,
            cardlessDeductionAmount: draft.cardlessDeductionAmount,
            cardlessSupplementAmount: draft.cardlessSupplementAmount,
            orderSource: draft.orderSource,
            categories: draft.categories,
            paymentMethod: draft.paymentMethod,
            notes: draft.notes,
            reconciliationStatus: draft.reconciliationStatus,
            campaignNames: draft.campaignNames,
            paymentReceiptStatus: draft.paymentReceiptStatus,
            isCashOnDelivery: draft.isCashOnDelivery,
            photos: draft.photos,
            mergedSourceIDs: draft.mergeSourceIDs
        )
        let service = Self.makeService(database: database)

        // When
        try await service.mergeOrders(merged, [primaryID, secondaryID, merged.id])

        // Then
        let stored = try await service.fetchOrders()
        #expect(stored.count == samples.count + 1)
        let storedMerged = try #require(stored.first { $0.id == "BL-MERGED-001" })
        #expect(storedMerged.mergedSourceIDs == ["BL-2604-018", "BL-2604-012"])
        #expect(storedMerged.categories == ["美妝", "服飾"])
        #expect(storedMerged.chargedAmount == 17_480)
        #expect(storedMerged.status == .shipping)
        let storedPrimary = try #require(stored.first { $0.id == primaryID })
        let storedSecondary = try #require(stored.first { $0.id == secondaryID })
        #expect(storedPrimary.status == .merged)
        #expect(storedSecondary.status == .merged)
        let untouched = stored.filter {
            ![primaryID, secondaryID, "BL-MERGED-001"].contains($0.id)
        }
        #expect(untouched.allSatisfy { $0.status != .merged })
    }

    /// 合併結果編號撞號時逐欄保留既有資料且不改兩筆來源狀態
    ///
    /// - Throws: 準備或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   合併未丟錯誤、錯誤不是 `.identifierCollision(id:)` 或未讀回既有與來源訂單時由
    ///   `#require` 丟出測試斷言錯誤；合併失敗時以 `OrderPersistenceError` 丟出
    ///   `.identifierCollision(id:)`、`.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`
    @Test
    func mergeOrders_結果識別值撞號_保留既有資料且不改來源狀態() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let samples = LedgerOrder.sampleOrders
        let existing = try #require(samples.first { $0.id == "BL-2604-011" })
        let primary = try #require(samples.first { $0.id == "BL-2604-018" })
        let secondary = try #require(samples.first { $0.id == "BL-2604-012" })
        try await Self.seed(samples, database: database)
        let attempted = Self.makeFullFieldOrder(id: existing.id, variant: .updated)
        let service = Self.makeService(database: database)
        var actualError: OrderPersistenceError?

        // When
        do throws(OrderPersistenceError) {
            try await service.mergeOrders(attempted, [primary.id, secondary.id])
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualCollisionID: String?
        switch error {
        case .identifierCollision(let id):
            actualCollisionID = id

        case .storage:
            actualCollisionID = nil
        }
        let storedCollisionID = try #require(actualCollisionID)
        #expect(storedCollisionID == existing.id)
        let stored = try await service.fetchOrders()
        #expect(stored.count == samples.count)
        let storedExisting = try #require(
            try await Self.fetchOrder(id: existing.id, from: database)
        )
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedExisting)
                == LedgerOrder.normalizingItemIdentifiers(existing)
        )
        #expect(storedExisting.photos == existing.photos)
        let storedPrimary = try #require(stored.first { $0.id == primary.id })
        let storedSecondary = try #require(stored.first { $0.id == secondary.id })
        #expect(storedPrimary.status == primary.status)
        #expect(storedSecondary.status == secondary.status)
    }

    /// 合併主體完成後資料庫失敗時不會落盤任何變更
    ///
    /// - Throws: 寫入失敗時以 `OrderPersistenceError` 丟出 `.storage(.fetchFailed(underlying:))`；
    ///   讀取失敗時丟出 `.fetchFailed(underlying:)`；未取得合併錯誤、預期的查詢失敗或原訂單時
    ///   由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_主體完成後寫入失敗_不落盤任何變更() async throws {
        // Given
        let initial = Self.makeOrder(id: "ORDER-MERGE-FAIL-SOURCE")
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [initial])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .writeFailureAfterBody(
            error: OrderPersistenceError.storage(
                .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "write failure")
                )
            )
        )
        let service = Self.makeService(database: mock)
        var actualError: OrderPersistenceError?

        // When
        do throws(OrderPersistenceError) {
            try await service.mergeOrders(
                Self.makeOrder(id: "ORDER-MERGE-FAIL-RESULT"),
                [initial.id]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualFailureDescription: String?
        switch error {
        case .identifierCollision:
            actualFailureDescription = nil

        case .storage(.fetchFailed(let underlying)):
            actualFailureDescription = underlying.localizedDescription

        case .storage(.saveFailed), .storage(.containerCreationFailed):
            actualFailureDescription = nil
        }
        let failureDescription = try #require(actualFailureDescription)
        #expect(failureDescription == "write failure")
        let stored = try await service.fetchOrders()
        #expect(stored.map(\.id) == [initial.id])
        let storedSource = try #require(stored.first)
        #expect(storedSource.status == initial.status)
    }

    /// 合併操作真實存檔失敗時不會留下合併結果
    ///
    /// - Throws: `makeDiskFixture` 建立時丟出底層檔案或 SwiftData 錯誤；合併失敗時以
    ///   `OrderPersistenceError` 丟出
    ///   `.identifierCollision(id:)`、`.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；
    ///   讀取失敗時丟出 `.fetchFailed(underlying:)`；未取得預期合併錯誤、儲存錯誤或原訂單時由
    ///   `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_真正儲存失敗_不留下合併結果() async throws {
        // Given
        let source = Self.makeOrder(id: "ORDER-MERGE-SAVE-FAIL-SOURCE")
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [source])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let service = Self.makeService(database: mock)
        var actualError: OrderPersistenceError?

        // When
        do throws(OrderPersistenceError) {
            try await service.mergeOrders(
                Self.makeOrder(id: "ORDER-MERGE-SAVE-FAIL-RESULT"),
                [source.id]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualStorageError: PersistenceError?
        switch error {
        case .storage(let storageError):
            actualStorageError = storageError

        case .identifierCollision:
            actualStorageError = nil
        }
        let storageError = try #require(actualStorageError)
        let isSaveFailure: Bool
        switch storageError {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        #expect(isSaveFailure)
        let stored = try await service.fetchOrders()
        #expect(stored.map(\.id) == [source.id])
        let storedSource = try #require(stored.first)
        #expect(storedSource.status == source.status)
    }

    /// 合併僅標記兩筆來源且保留其餘四十八筆訂單狀態與照片
    ///
    /// - Throws: 合併時以 `OrderPersistenceError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；未讀回來源或其餘訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_指定兩筆來源_保留其他訂單狀態與照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x31])
        let seeded = (0..<50).map {
            LedgerOrder.fixture(
                id: String(format: "BL-MERGEBULK-%03d", $0),
                status: .quoting,
                photos: [photo]
            )
        }
        try await Self.seed(seeded, database: database)
        let primaryID = "BL-MERGEBULK-005"
        let secondaryID = "BL-MERGEBULK-010"
        let merged = Self.makeOrder(id: "BL-MERGEBULK-NEW", photos: [photo])
        let service = Self.makeService(database: database)

        // When
        try await service.mergeOrders(merged, [primaryID, secondaryID])

        // Then
        let stored = try await service.fetchOrders()
        #expect(stored.count == 51)
        let primary = try #require(stored.first { $0.id == primaryID })
        let secondary = try #require(stored.first { $0.id == secondaryID })
        #expect(primary.status == .merged)
        #expect(secondary.status == .merged)
        let storedUntouched = stored.filter {
            $0.id != primaryID && $0.id != secondaryID && $0.id != merged.id
        }
        #expect(storedUntouched.count == 48)
        for untouched in storedUntouched {
            #expect(untouched.status == .quoting)
            let persisted = try #require(
                try await Self.fetchOrder(id: untouched.id, from: database)
            )
            #expect(persisted.photos == [photo])
        }
    }
}
