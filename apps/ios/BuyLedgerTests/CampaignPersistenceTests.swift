//
//  CampaignPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

@MainActor
struct CampaignPersistenceTests {

    // MARK: - Tests

    @Test func fetchAllOnFreshContainerReturnsEmpty() async throws {
        let persistence = try makePersistence()
        let stored = try await persistence.fetchAll()
        #expect(stored.isEmpty)
    }

    @Test func upsertInsertsNewCampaignThenUpdatesInPlace() async throws {
        let persistence = try makePersistence()
        let campaign = makeCampaign(id: "C1", name: "四月韓國團", status: .ongoing)

        try await persistence.upsert(campaign)
        let afterInsert = try await persistence.fetchAll()
        #expect(afterInsert.count == 1)
        #expect(afterInsert.first?.name == "四月韓國團")
        #expect(afterInsert.first?.status == .ongoing)

        var renamedClosed = campaign
        renamedClosed.name = "四月韓國團 (補)"
        renamedClosed.status = .closed
        try await persistence.upsert(renamedClosed)

        let afterUpdate = try await persistence.fetchAll()
        #expect(afterUpdate.count == 1, "相同 id 應 upsert 更新而非新增")
        #expect(afterUpdate.first?.name == "四月韓國團 (補)")
        #expect(afterUpdate.first?.status == .closed)
    }

    @Test func fetchAllReturnsCampaignsSortedByOpenDateDescending() async throws {
        let persistence = try makePersistence()
        try await persistence.upsert(makeCampaign(id: "old", name: "三月團", openDay: 1))
        try await persistence.upsert(makeCampaign(id: "new", name: "四月團", openDay: 30))

        let fetched = try await persistence.fetchAll()
        #expect(fetched.map(\.id) == ["new", "old"])
    }

    @Test func deleteRemovesCampaignById() async throws {
        let persistence = try makePersistence()
        try await persistence.upsert(makeCampaign(id: "C1", name: "團一"))
        try await persistence.upsert(makeCampaign(id: "C2", name: "團二"))

        try await persistence.delete(id: "C1")

        let fetched = try await persistence.fetchAll()
        #expect(fetched.map(\.id) == ["C2"])
    }

    @Test func roundTripPreservesCloseAndSettledDates() async throws {
        let persistence = try makePersistence()
        let close = Date(timeIntervalSince1970: 1_700_000_000)
        let settled = Date(timeIntervalSince1970: 1_800_000_000)
        var campaign = makeCampaign(id: "C1", name: "團", status: .closed)
        campaign.closeDate = close
        campaign.settledDate = settled

        try await persistence.upsert(campaign)
        let fetched = try await persistence.fetchAll().first

        #expect(fetched?.closeDate == close)
        #expect(fetched?.settledDate == settled)
        #expect(fetched?.isSettled == true)
    }

    // MARK: - Helper

    /// 用 in-memory 的 ``ModelContainer`` 建立每個測試獨立的 ``CampaignPersistence``
    private func makePersistence() throws -> CampaignPersistence {
        let container = try PersistenceContainer.make(inMemoryOnly: true)
        return CampaignPersistence(modelContainer: container)
    }

    /// 建立測試用開團；日期以 2026 年 4 月的固定日帶入，方便驗證排序
    private func makeCampaign(
        id: String,
        name: String,
        status: CampaignStatus = .ongoing,
        openDay: Int = 10
    ) -> Campaign {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 4
        components.day = openDay

        return Campaign(
            id: id,
            name: name,
            openDate: components.date ?? Date(timeIntervalSince1970: 0),
            closeDate: nil,
            status: status,
            settledDate: nil,
            notes: ""
        )
    }
}
