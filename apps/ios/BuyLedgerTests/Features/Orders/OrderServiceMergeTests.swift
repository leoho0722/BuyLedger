//
//  OrderServiceMergeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋合併結果的寫入、來源狀態標記，以及失敗時的落盤範圍
struct OrderServiceMergeTests {

    /// 驗證合併兩筆來源訂單後，結果新增一筆並帶入兩個來源編號、草稿的類別、金額與狀態，兩筆來源改標為已合併，其餘訂單都不標為已合併
    ///
    /// - Throws: 合併時以 `OrderError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；未取得來源或合併後訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_合併訂單_新增結果並只標記已耗用來源() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let samples = LedgerOrder.sampleOrders
        try await OrderServiceTestSupport.seed(samples, database: database)
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
        let service = OrderServiceTestSupport.makeService(database: database)

        // When
        try await service.mergeOrders(merged, [primaryID, secondaryID, merged.id])

        // Then
        let stored = try await service.fetchOrders()
        #expect(stored.count == 9)
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

    /// 驗證合併結果的識別值撞到既有訂單時，合併丟出撞號錯誤，既有訂單的欄位與照片都不被覆寫，兩筆來源的狀態也維持原狀
    ///
    /// - Throws: 準備或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   合併未丟錯誤、錯誤不是 `.identifierCollision(id:)` 或未讀回既有與來源訂單時由
    ///   `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_結果識別值撞號_保留既有資料且不改來源狀態() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let samples = LedgerOrder.sampleOrders
        let existing = try #require(samples.first { $0.id == "BL-2604-011" })
        let primary = try #require(samples.first { $0.id == "BL-2604-018" })
        let secondary = try #require(samples.first { $0.id == "BL-2604-012" })
        try await OrderServiceTestSupport.seed(samples, database: database)
        let attempted = OrderServiceTestSupport.makeFullFieldOrder(
            id: existing.id,
            variant: .updated
        )
        let service = OrderServiceTestSupport.makeService(database: database)
        var actualError: OrderError?

        // When
        do {
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
        #expect(stored.count == 8)
        let storedExisting = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: existing.id, from: database)
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

    /// 驗證合併主體執行完成後寫入失敗，`mergeOrders` 丟出替身注入的錯誤，資料庫只保留來源訂單且其狀態不變，合併結果不落盤
    ///
    /// - Throws: `makeDiskFixture` 建立時丟出底層檔案或 SwiftData 錯誤；
    ///   讀取失敗時丟出 `.fetchFailed(underlying:)`；未取得合併錯誤、錯誤不是
    ///   `.storage(.fetchFailed(underlying:))` 或未讀回原訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_主體完成後寫入失敗_不落盤任何變更() async throws {
        // Given
        let initial = OrderServiceTestSupport.makeOrder(id: "ORDER-MERGE-FAIL-SOURCE")
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [initial])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .writeFailureAfterBody(
            error: OrderError.storage(
                .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "write failure")
                )
            )
        )
        let service = OrderServiceTestSupport.makeService(database: mock)
        var actualError: OrderError?

        // When
        do {
            try await service.mergeOrders(
                OrderServiceTestSupport.makeOrder(id: "ORDER-MERGE-FAIL-RESULT"),
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

    /// 驗證合併主體執行後磁碟 store 的存檔確實失敗時，`mergeOrders` 丟出儲存錯誤，資料庫只剩來源訂單且其狀態不變，不留下合併結果
    ///
    /// - Throws: `makeDiskFixture` 建立時丟出底層檔案或 SwiftData 錯誤；
    ///   讀取失敗時丟出 `.fetchFailed(underlying:)`；未取得合併錯誤、儲存錯誤或原訂單時由
    ///   `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_真正儲存失敗_不留下合併結果() async throws {
        // Given
        let source = OrderServiceTestSupport.makeOrder(id: "ORDER-MERGE-SAVE-FAIL-SOURCE")
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [source])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let service = OrderServiceTestSupport.makeService(database: mock)
        var actualError: OrderError?

        // When
        do {
            try await service.mergeOrders(
                OrderServiceTestSupport.makeOrder(id: "ORDER-MERGE-SAVE-FAIL-RESULT"),
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

    /// 驗證從五十筆訂單中合併兩筆時，兩筆來源標為已合併，其餘四十八筆仍為原狀態且照片完整保留
    ///
    /// - Throws: 合併時以 `OrderError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；未讀回來源或其餘訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_指定兩筆來源_保留其他訂單狀態與照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x31])
        let seeded = (0..<50).map {
            LedgerOrder.fixture(
                id: String(format: "BL-MERGEBULK-%03d", $0),
                status: .quoting,
                photos: [photo]
            )
        }
        try await OrderServiceTestSupport.seed(seeded, database: database)
        let primaryID = "BL-MERGEBULK-005"
        let secondaryID = "BL-MERGEBULK-010"
        let merged = OrderServiceTestSupport.makeOrder(id: "BL-MERGEBULK-NEW", photos: [photo])
        let service = OrderServiceTestSupport.makeService(database: database)

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
                try await OrderServiceTestSupport.fetchOrder(id: untouched.id, from: database)
            )
            #expect(persisted.photos == [photo])
        }
    }
}
