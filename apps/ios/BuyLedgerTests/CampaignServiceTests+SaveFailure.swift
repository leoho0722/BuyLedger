//
//  CampaignServiceTests+SaveFailure.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/30.
//

import CoreData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension CampaignServiceTests {

    /// 更新開團時儲存失敗會丟出保留 SwiftData 底層錯誤網域與代碼的儲存錯誤，原有開團維持原內容
    ///
    /// - Throws: fixture 建立失敗時丟出底層檔案或 SwiftData 錯誤；原有開團寫入或讀回失敗時丟出
    ///   `PersistenceError.fetchFailed(underlying:)` 或 `PersistenceError.saveFailed(underlying:)`；
    ///   `saveCampaign` 沒有丟出錯誤，或錯誤不是 `.saveFailed(underlying:)` 時由 `#require`
    ///   丟出測試斷言錯誤
    @Test
    func saveCampaign_儲存失敗_丟出儲存錯誤並保留原有開團() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let campaignService = Self.makeService(database: database)
        let originalCampaign = Self.makeCampaign(id: "C1", name: "四月團", status: .ongoing)
        try await campaignService.saveCampaign(originalCampaign)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let failingService = Self.makeService(database: mock)
        var updatedCampaign = originalCampaign
        updatedCampaign.name = "四月團 (補)"
        updatedCampaign.status = .closed
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await failingService.saveCampaign(updatedCampaign)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualUnderlying: (any Error & Sendable)?
        switch error {
        case .saveFailed(let underlying):
            actualUnderlying = underlying

        case .fetchFailed, .containerCreationFailed:
            actualUnderlying = nil
        }
        let underlying = try #require(actualUnderlying) as NSError
        #expect(underlying.domain == NSCocoaErrorDomain)
        #expect(underlying.code == NSValidationRelationshipExceedsMaximumCountError)
        let remainingCampaigns = try await campaignService.fetchCampaigns()
        #expect(remainingCampaigns == [originalCampaign])
    }
}
