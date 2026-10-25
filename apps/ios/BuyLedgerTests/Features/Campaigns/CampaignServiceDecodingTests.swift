//
//  CampaignServiceDecodingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `CampaignService` 的單元測試，以記憶體資料庫寫入開團紀錄後，檢查讀取時的狀態解碼
struct CampaignServiceDecodingTests {

    /// 驗證開團狀態原始值無法解碼時，讀取丟出 `.fetchFailed`，底層 `RecordDecodingError` 保留實體、識別值、欄位與原始值
    ///
    /// - Throws: 資料寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   `fetchCampaigns` 沒有丟出錯誤、錯誤不是 `.fetchFailed`，或底層錯誤不是
    ///   `RecordDecodingError` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchCampaigns_狀態無法解碼_保留四個診斷欄位() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let record = CampaignRecord(
                campaign: Campaign.fixture(
                    id: "campaign-001",
                    name: "測試開團",
                    openDate: Date(timeIntervalSince1970: 1_775_779_200)
                )
            )
            record.statusRaw = "legacy-status"
            context.insert(record)
        }
        let service = CampaignServiceTestSupport.makeService(database: database)
        var actualError: PersistenceError?

        // When
        do {
            _ = try await service.fetchCampaigns()
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualUnderlying: (any Error & Sendable)?
        switch error {
        case .fetchFailed(let underlying):
            actualUnderlying = underlying

        case .saveFailed, .containerCreationFailed:
            actualUnderlying = nil
        }
        let underlying = try #require(actualUnderlying)
        let decodingError = try #require(underlying as? RecordDecodingError)
        #expect(decodingError.entity == "CampaignRecord")
        #expect(decodingError.identifier == "campaign-001")
        #expect(decodingError.field == "status")
        #expect(decodingError.rawValue == "legacy-status")
    }

    /// 驗證合法的開團狀態原始值讀取後，還原為相同的領域值，進行中與已結束各自對應正確
    ///
    /// - Throws: 資料寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   資料讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    @Test
    func fetchCampaigns_合法狀態原始值_還原相同領域值() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let ongoingCampaign = CampaignRecord(
                campaign: Campaign.fixture(
                    id: "campaign-ongoing",
                    name: "測試開團",
                    openDate: Date(timeIntervalSince1970: 1_775_779_200)
                )
            )
            ongoingCampaign.statusRaw = "ongoing"
            let closedCampaign = CampaignRecord(
                campaign: Campaign.fixture(
                    id: "campaign-closed",
                    name: "測試開團",
                    openDate: Date(timeIntervalSince1970: 1_775_779_200),
                    status: .closed
                )
            )
            closedCampaign.statusRaw = "closed"
            context.insert(ongoingCampaign)
            context.insert(closedCampaign)
        }
        let service = CampaignServiceTestSupport.makeService(database: database)

        // When
        let campaigns = try await service.fetchCampaigns()

        // Then
        let campaignStatuses = Dictionary(
            uniqueKeysWithValues: campaigns.map { ($0.id, $0.status) }
        )
        #expect(campaignStatuses["campaign-ongoing"] == .ongoing)
        #expect(campaignStatuses["campaign-closed"] == .closed)
    }
}
