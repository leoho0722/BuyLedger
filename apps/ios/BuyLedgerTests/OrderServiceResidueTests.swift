//
//  OrderServiceResidueTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 驗證訂單寫入失敗後不會污染後續交易
struct OrderServiceResidueTests {

    // MARK: - Tests

    /// 刪除存檔失敗後再次刪除會移除原訂單
    ///
    /// - Throws: 建立 fixture 或獨立容器失敗時丟出 SwiftData 底層錯誤；
    ///   讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   刪除存檔失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件或預期值不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func removeOrder_刪除首次儲存失敗後重試_移除原訂單() async throws {
        // Given
        let environment = try Self.makeTestEnvironment()
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: environment.fixture.directoryURL)
        }
        try await Self.requireSeededOrder(in: environment.database)
        environment.mock.mode = .saveFailureAfterBody
        try await Self.requireRelationshipSaveFailure { () throws(PersistenceError) in
            try await environment.service.removeOrder("order-001")
        }
        environment.mock.mode = .passthrough

        // When
        try await environment.service.removeOrder("order-001")

        // Then
        let storedOrders = try await Self.fetchPersistedOrders(
            from: environment.fixture.directoryURL
        )
        #expect(storedOrders.isEmpty)
    }

    /// 刪除存檔失敗後同編號建立會回報撞號且只保留原訂單
    ///
    /// - Throws: 建立 fixture 或獨立容器失敗時丟出 SwiftData 底層錯誤；
    ///   讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   前置條件或預期值不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func createOrder_刪除儲存失敗後同編號建立_回報撞號並保留原訂單() async throws {
        // Given
        let environment = try Self.makeTestEnvironment()
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: environment.fixture.directoryURL)
        }
        try await Self.requireSeededOrder(in: environment.database)
        environment.mock.mode = .saveFailureAfterBody
        try await Self.requireRelationshipSaveFailure { () throws(PersistenceError) in
            try await environment.service.removeOrder("order-001")
        }
        environment.mock.mode = .passthrough
        var actualCollisionError: OrderPersistenceError?

        // When
        do throws(OrderPersistenceError) {
            try await environment.service.createOrder(
                LedgerOrder.fixture(id: "order-001", status: .quoting, notes: "新訂單")
            )
        } catch {
            actualCollisionError = error
        }

        // Then
        let collisionError = try #require(actualCollisionError)
        let actualCollisionID: String?
        switch collisionError {
        case .identifierCollision(let id):
            actualCollisionID = id

        case .storage:
            actualCollisionID = nil
        }
        let collisionID = try #require(actualCollisionID)
        #expect(collisionID == "order-001")
        let storedOrders = try await Self.fetchPersistedOrders(
            from: environment.fixture.directoryURL
        )
        #expect(storedOrders.count == 1)
        let storedOrder = try #require(storedOrders.first)
        #expect(storedOrder.id == "order-001")
        #expect(storedOrder.status == .confirmed)
    }

    /// 刪除存檔失敗後同編號更新仍只保留一筆並套用新欄位
    ///
    /// - Throws: 建立 fixture 或獨立容器失敗時丟出 SwiftData 底層錯誤；
    ///   讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   更新存檔失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件或預期值不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveOrder_刪除儲存失敗後同編號更新_只保留一筆更新訂單() async throws {
        // Given
        let photos = [Data([0x01])]
        let environment = try Self.makeTestEnvironment(photos: photos)
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: environment.fixture.directoryURL)
        }
        try await Self.requireSeededOrder(in: environment.database, photos: photos)
        environment.mock.mode = .saveFailureAfterBody
        try await Self.requireRelationshipSaveFailure { () throws(PersistenceError) in
            try await environment.service.removeOrder("order-001")
        }
        environment.mock.mode = .passthrough

        // When
        try await environment.service.saveOrder(
            LedgerOrder.fixture(
                id: "order-001",
                status: .shipping,
                chargedAmount: 2_500,
                paymentMethod: "後續付款",
                notes: "後續備註"
            )
        )

        // Then
        let database = try Self.makeIndependentDatabase(at: environment.fixture.directoryURL)
        let service = OrderServiceTests.makeService(database: database)
        let storedOrders = try await service.fetchOrders()
        let storedPhotos = try await service.fetchOrderPhotos("order-001")
        #expect(storedOrders.count == 1)
        let storedOrder = try #require(storedOrders.first)
        #expect(storedOrder.id == "order-001")
        #expect(storedOrder.status == .shipping)
        #expect(storedOrder.chargedAmount == 2_500)
        #expect(storedOrder.paymentMethod == "後續付款")
        #expect(storedOrder.notes == "後續備註")
        #expect(storedPhotos == [Data([0x01])])
    }

    /// 更新存檔失敗後改開團名稱不會帶入失敗欄位
    ///
    /// - Throws: 建立 fixture 或獨立容器失敗時丟出 SwiftData 底層錯誤；
    ///   讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   改名存檔失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件或預期值不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameOrderCampaign_欄位更新儲存失敗後_不帶入失敗欄位() async throws {
        // Given
        let environment = try Self.makeTestEnvironment()
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: environment.fixture.directoryURL)
        }
        try await Self.requireSeededOrder(in: environment.database)
        environment.mock.mode = .saveFailureAfterBody
        try await Self.requireRelationshipSaveFailure { () throws(PersistenceError) in
            try await environment.service.saveOrder(
                LedgerOrder.fixture(
                    id: "order-001",
                    status: .shipping,
                    chargedAmount: 9_999,
                    paymentMethod: "失敗付款",
                    notes: "失敗備註",
                    campaignNames: ["春團"]
                )
            )
        }
        environment.mock.mode = .passthrough

        // When
        try await environment.service.renameOrderCampaign("春團", "秋團")

        // Then
        let storedOrders = try await Self.fetchPersistedOrders(
            from: environment.fixture.directoryURL
        )
        #expect(storedOrders.count == 1)
        let storedOrder = try #require(storedOrders.first)
        #expect(storedOrder.id == "order-001")
        #expect(storedOrder.status == .confirmed)
        #expect(storedOrder.notes == "原始備註")
        #expect(storedOrder.paymentMethod == "原始付款")
        #expect(storedOrder.chargedAmount == 1_250)
        #expect(storedOrder.campaignNames == ["秋團"])
    }
}

// MARK: - Nested Types

private extension OrderServiceResidueTests {

    /// 單次殘留測試共用的 store、資料庫、mock 與 Service
    struct TestEnvironment {

        /// 暫存磁碟 fixture
        let fixture: ResidueProbeModels.DiskFixture

        /// 連接暫存 store 的正式資料庫
        let database: BuyLedgerDatabase

        /// 控制後續寫入行為的資料庫 mock
        let mock: MockBuyLedgerDatabase

        /// 透過 mock 操作訂單的 Service
        let service: OrderService
    }
}

// MARK: - Private Method

private extension OrderServiceResidueTests {

    /// 建立已寫入初始訂單並可注入存檔失敗的測試環境
    ///
    /// - Parameter photos: 要先存入初始訂單的照片
    /// - Returns: fixture、正式資料庫、失敗控制 mock 與訂單 Service
    /// - Throws: 建立暫存 store 或寫入初始資料失敗時丟出底層錯誤
    static func makeTestEnvironment(photos: [Data] = []) throws -> TestEnvironment {
        let order = Self.initialOrder(photos: photos)
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [order])
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        let service = OrderServiceTests.makeService(database: mock)
        return TestEnvironment(
            fixture: fixture,
            database: database,
            mock: mock,
            service: service
        )
    }

    /// 建立寫入失敗案例使用的初始訂單
    ///
    /// - Parameter photos: 要存入訂單的照片
    /// - Returns: 尚未寫入資料庫的範例訂單
    static func initialOrder(photos: [Data] = []) -> LedgerOrder {
        LedgerOrder.fixture(
            id: "order-001",
            status: .confirmed,
            chargedAmount: 1_250,
            paymentMethod: "原始付款",
            notes: "原始備註",
            campaignNames: ["春團"],
            photos: photos
        )
    }

    /// 驗證寫入交易前 store 已包含範例訂單的原始欄位
    ///
    /// - Parameters:
    ///   - database: 含初始訂單的資料庫
    ///   - photos: 預期的初始照片
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   前置條件或預期值不成立時由 `#require` 丟出測試斷言錯誤
    static func requireSeededOrder(
        in database: BuyLedgerDatabase,
        photos: [Data] = []
    ) async throws {
        let service = OrderServiceTests.makeService(database: database)
        let orders = try await service.fetchOrders()
        try #require(orders.count == 1)
        let order = try #require(orders.first)
        try #require(order.id == "order-001")
        try #require(order.status == .confirmed)
        try #require(order.notes == "原始備註")
        try #require(order.paymentMethod == "原始付款")
        try #require(order.chargedAmount == 1_250)
        try #require(order.campaignNames == ["春團"])
        let storedPhotos = try await service.fetchOrderPhotos("order-001")
        try #require(storedPhotos == photos)
    }

    /// 從同一個磁碟 store 建立另一個資料庫後讀回全部訂單
    ///
    /// - Parameter directoryURL: 原始 store 的暫存目錄
    /// - Returns: 另一個資料庫讀到的完整訂單
    /// - Throws: 獨立容器建立失敗時丟出 SwiftData 底層錯誤；
    ///   查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchPersistedOrders(from directoryURL: URL) async throws -> [LedgerOrder] {
        let database = try Self.makeIndependentDatabase(at: directoryURL)
        let service = OrderServiceTests.makeService(database: database)
        return try await service.fetchOrders()
    }

    /// 以原 fixture 的 store URL 建立獨立 `ModelContainer` 與資料庫
    ///
    /// - Parameter directoryURL: 原 fixture 的暫存 store 目錄
    /// - Returns: 連接相同 store URL 的另一個資料庫
    /// - Throws: SwiftData 容器建立失敗時丟出底層錯誤
    static func makeIndependentDatabase(at directoryURL: URL) throws -> BuyLedgerDatabase {
        let configuration = ModelConfiguration(
            url: ResidueProbeModels.storeURL(in: directoryURL),
            cloudKitDatabase: .none
        )
        let container = try TestContainerCreationLock.withLock {
            try ModelContainer(for: ResidueProbeModels.schema, configurations: [configuration])
        }
        return BuyLedgerDatabase(modelContainer: container, storeLocation: .directory(directoryURL))
    }
}
