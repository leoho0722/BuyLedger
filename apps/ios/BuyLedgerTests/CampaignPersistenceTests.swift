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

/// 驗證開團持久化
@MainActor
struct CampaignPersistenceTests {
    
    // MARK: - Tests
    
    @Test func fetchAllOnFreshContainerReturnsEmpty() async throws(any Error) {
        let persistence = try makePersistence()
        let stored = try await persistence.fetchAll()
        #expect(stored.isEmpty)
    }
    
    @Test func upsertInsertsNewCampaignThenUpdatesInPlace() async throws(any Error) {
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
    
    @Test func fetchAllReturnsCampaignsSortedByOpenDateDescending() async throws(any Error) {
        let persistence = try makePersistence()
        try await persistence.upsert(makeCampaign(id: "old", name: "三月團", openDay: 1))
        try await persistence.upsert(makeCampaign(id: "new", name: "四月團", openDay: 30))
        
        let fetched = try await persistence.fetchAll()
        #expect(fetched.map(\.id) == ["new", "old"])
    }
    
    @Test func deleteRemovesCampaignById() async throws(any Error) {
        let persistence = try makePersistence()
        try await persistence.upsert(makeCampaign(id: "C1", name: "團一"))
        try await persistence.upsert(makeCampaign(id: "C2", name: "團二"))
        
        _ = try await persistence.delete(id: "C1", name: "團一")
        
        let fetched = try await persistence.fetchAll()
        #expect(fetched.map(\.id) == ["C2"])
    }
    
    @Test func deletingACampaignStripsItsNameFromOrdersAndRemovesTheReminderLink() async throws(any Error) {
        // 同一交易移除開團、訂單連結與提醒。
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let campaignPersistence = CampaignPersistence(modelContainer: container)
        let orderPersistence = OrderPersistence(modelContainer: container)
        let reminderPersistence = CampaignReminderPersistence(modelContainer: container)
        
        try await campaignPersistence.upsert(makeCampaign(id: "C1", name: "四月團"))
        try await orderPersistence.create(makeOrder(id: "O1", campaignNames: ["四月團", "五月團"]))
        let reminderTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        try await reminderPersistence.upsert(
            campaignID: "C1",
            link: CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: reminderTimestamp
            )
        )
        
        let removedIdentifier = try await campaignPersistence.delete(id: "C1", name: "四月團")
        
        #expect(removedIdentifier == "EVT-1")
        let remainingCampaigns = try await campaignPersistence.fetchAll()
        #expect(remainingCampaigns.isEmpty)
        let remainingOrder = try await orderPersistence.fetch(id: "O1")
        #expect(remainingOrder?.campaignNames == ["五月團"])
        let remainingLinks = try await reminderPersistence.fetchAll()
        #expect(remainingLinks["C1"] == nil)
    }
    
    @Test func deletingACampaignWithoutReminderReturnsNil() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let campaignPersistence = CampaignPersistence(modelContainer: container)
        
        try await campaignPersistence.upsert(makeCampaign(id: "C1", name: "無提醒團"))
        
        let removedIdentifier = try await campaignPersistence.delete(id: "C1", name: "無提醒團")
        
        #expect(removedIdentifier == nil)
        #expect(try await campaignPersistence.fetchAll().isEmpty)
    }
    
    @Test func deleteIsAllOrNothingWhenSaveFails() async throws(any Error) {
        // 刪除開團、訂單歸屬與提醒連結時，儲存失敗也不可留下部分變更
        let campaign = makeCampaign(id: "C1", name: "四月團")
        let order = makeOrder(id: "O1", campaignNames: ["四月團"])
        let reminderTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let storeURL = try await Self.seedUnsavableStore(
            campaign: campaign, order: order, reminderTimestamp: reminderTimestamp)
        
        let failingContainer = try Self.makeReadOnlyContainer(at: storeURL)
        let failingCampaignPersistence = CampaignPersistence(modelContainer: failingContainer)
        
        await #expect(throws: PersistenceError.self) {
            _ = try await failingCampaignPersistence.delete(id: "C1", name: "四月團")
        }
        
        let verifyContainer = try Self.makeReadOnlyContainer(at: storeURL)
        let verifyCampaignPersistence = CampaignPersistence(modelContainer: verifyContainer)
        let verifyOrderPersistence = OrderPersistence(modelContainer: verifyContainer)
        let verifyReminderPersistence = CampaignReminderPersistence(modelContainer: verifyContainer)
        
        let remainingCampaigns = try await verifyCampaignPersistence.fetchAll()
        #expect(remainingCampaigns.map(\.id) == ["C1"], "save 失敗時開團仍應存在")
        let remainingOrder = try await verifyOrderPersistence.fetch(id: "O1")
        #expect(remainingOrder?.campaignNames == ["四月團"], "save 失敗時訂單的開團名稱不應被剝除")
        let remainingLinks = try await verifyReminderPersistence.fetchAll()
        #expect(remainingLinks["C1"] != nil, "save 失敗時提醒連結不應被移除")
    }
    
    @Test func deletingAnAbsentCampaignRemainsANoOp() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let campaignPersistence = CampaignPersistence(modelContainer: container)
        let orderPersistence = OrderPersistence(modelContainer: container)
        
        try await orderPersistence.create(makeOrder(id: "O1", campaignNames: ["五月團"]))
        
        let removedIdentifier = try await campaignPersistence.delete(id: "C-absent", name: "不存在的團")
        
        #expect(removedIdentifier == nil)
        let remainingOrder = try await orderPersistence.fetch(id: "O1")
        #expect(remainingOrder?.campaignNames == ["五月團"], "不存在的開團刪除不應影響任何訂單")
    }
    
    @Test func roundTripPreservesCloseAndSettledDates() async throws(any Error) {
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
    
}

// MARK: - Helper Method

private extension CampaignPersistenceTests {
    
    /// 用 in-memory 的 ``ModelContainer`` 建立每個測試獨立的 ``CampaignPersistence``
    /// - Returns: CampaignPersistence
    /// - Throws: 測試容器建立失敗時拋出錯誤
    func makePersistence() throws(any Error) -> CampaignPersistence {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        return CampaignPersistence(modelContainer: container)
    }
    
    /// 建立測試用開團；日期以 2026 年 4 月的固定日帶入，方便驗證排序
    /// - Returns: 建立的開團
    func makeCampaign(
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
    
    /// 建立測試用訂單，僅暴露 ``LedgerOrder/campaignNames`` 供刪除連動測試使用
    /// - Returns: 建立的訂單
    func makeOrder(id: String, campaignNames: [String]) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 0),
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 100,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 建立寫入初始資料的 store，並回傳檔案位置
    /// - Parameters:
    ///   - campaign: 要寫入的開團
    ///   - order: 要寫入的訂單
    ///   - reminderTimestamp: 提醒時間
    /// - Returns: 初始資料 store 的檔案路徑
    /// - Throws: store 建立或資料寫入失敗時拋出錯誤
    static func seedUnsavableStore(
        campaign: Campaign,
        order: LedgerOrder,
        reminderTimestamp: Date
    ) async throws(any Error) -> URL {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerCampaignRollbackTest-\(UUID().uuidString).store")
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let writableConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let writableContainer = try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: writableConfiguration
        )
        
        try await CampaignPersistence(modelContainer: writableContainer).upsert(campaign)
        try await OrderPersistence(modelContainer: writableContainer).create(order)
        try await CampaignReminderPersistence(modelContainer: writableContainer).upsert(
            campaignID: campaign.id,
            link: CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: reminderTimestamp
            )
        )
        
        return storeURL
    }
    
    /// 以 `allowsSave: false` 重新開啟指定路徑的 store，其上呼叫 `save()` 必定拋錯
    /// - Parameter storeURL: 資料庫路徑
    /// - Returns: 唯讀 ModelContainer
    /// - Throws: 測試容器建立失敗時拋出錯誤
    static func makeReadOnlyContainer(at storeURL: URL) throws(any Error) -> ModelContainer {
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let readOnlyConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: readOnlyConfiguration
        )
    }
}
