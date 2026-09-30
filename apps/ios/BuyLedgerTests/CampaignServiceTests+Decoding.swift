//
//  CampaignServiceTests+Decoding.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension CampaignServiceTests {

    /// 開團狀態的原始值無法解碼時，讀取丟出 `.fetchFailed`，底層 `RecordDecodingError`
    /// 保留實體名稱、識別值、欄位名稱與原始值
    ///
    /// - Throws: 資料寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   `fetchCampaigns` 沒有丟出錯誤、錯誤不是 `.fetchFailed`，或底層錯誤不是
    ///   `RecordDecodingError` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchCampaigns_狀態無法解碼_保留四個診斷欄位() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let record = CampaignRecord(
                campaign: Self.makeCampaign(id: "campaign-001", name: "測試開團")
            )
            record.statusRaw = "legacy-status"
            context.insert(record)
        }
        let service = Self.makeService(database: database)
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
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

    /// 合法的開團狀態 raw value 原樣轉回領域值
    ///
    /// - Throws: 資料寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   資料讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    @Test
    func fetchCampaigns_合法狀態原始值_還原相同領域值() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let ongoingCampaign = CampaignRecord(
                campaign: Self.makeCampaign(id: "campaign-ongoing", name: "測試開團")
            )
            ongoingCampaign.statusRaw = CampaignStatus.ongoing.rawValue
            let closedCampaign = CampaignRecord(
                campaign: Self.makeCampaign(id: "campaign-closed", name: "測試開團", status: .closed)
            )
            closedCampaign.statusRaw = CampaignStatus.closed.rawValue
            context.insert(ongoingCampaign)
            context.insert(closedCampaign)
        }
        let service = Self.makeService(database: database)

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
