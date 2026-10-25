//
//  OrderServiceResidueTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import CoreData
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 提供寫入失敗測試共用的磁碟查詢與錯誤驗證操作
enum OrderServiceResidueTestSupport {}

// MARK: - Internal Method

extension OrderServiceResidueTestSupport {

    /// 從同一個磁碟 store 建立另一個資料庫後讀回全部訂單
    ///
    /// - Parameter directoryURL: 原始 store 的暫存目錄
    /// - Returns: 另一個資料庫讀到的訂單，不含照片位元組
    /// - Throws: 獨立容器建立失敗時丟出 SwiftData 底層錯誤；
    ///   查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchPersistedOrders(from directoryURL: URL) async throws -> [LedgerOrder] {
        let database = try OrderServiceResidueTestSupport.makeIndependentDatabase(at: directoryURL)
        let service = OrderServiceTestSupport.makeService(database: database)
        return try await service.fetchOrders()
    }

    /// 執行指定寫入，並要求它以違規 relationship 的保存失敗結束
    ///
    /// - Parameter operation: 會觸發注入失敗的寫入
    /// - Throws: 沒有失敗或錯誤不是指定 relationship 限制時由 `#require` 丟出測試斷言錯誤
    static func requireRelationshipSaveFailure(
        _ operation: () async throws(PersistenceError) -> Void
    ) async throws {
        var actualError: PersistenceError?
        do {
            try await operation()
        } catch {
            actualError = error
        }
        let error = try #require(actualError)
        let underlyingError: (any Error & Sendable)?
        switch error {
        case .saveFailed(let underlying):
            underlyingError = underlying

        case .fetchFailed, .containerCreationFailed:
            underlyingError = nil
        }
        let underlying = try #require(underlyingError)
        try #require((underlying as NSError).domain == NSCocoaErrorDomain)
        try #require(
            (underlying as NSError).code == NSValidationRelationshipExceedsMaximumCountError
        )
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
