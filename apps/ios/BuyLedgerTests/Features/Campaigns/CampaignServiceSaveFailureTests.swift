//
//  CampaignServiceSaveFailureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/30.
//

import CoreData
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignService` 的單元測試，以磁碟資料庫搭配寫入失敗的替身，檢查儲存失敗時的錯誤保留與復原
struct CampaignServiceSaveFailureTests {

    /// 驗證更新開團時儲存失敗，丟出保留 SwiftData 底層錯誤網域與代碼的儲存錯誤，原有開團維持原內容
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
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let campaignService = CampaignServiceTestSupport.makeService(database: database)
        let originalCampaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .ongoing
        )
        try await campaignService.saveCampaign(originalCampaign)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let failingService = CampaignServiceTestSupport.makeService(database: mock)
        var updatedCampaign = originalCampaign
        updatedCampaign.name = "四月團 (補)"
        updatedCampaign.status = .closed
        var actualError: PersistenceError?

        // When
        do {
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
