//
//  CloudSyncEngineReconcileTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/22.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// ``CloudSyncEngine`` 的 reconcile / mergeDocument 守護測試
///
/// 以 DEBUG test seam (`configureForTesting`) 注入 in-memory 持久層、繞過 Firestore listener，
/// 驗證後端 PATCH 回應的權威值套回本機、tombstone 不砍較新本機編輯、
/// 照片暫時下載失敗不覆蓋
@MainActor
struct CloudSyncEngineReconcileTests {

    // MARK: - Replay 不丟棄

    /// push X@C_push 標 DIRTY → in-flight 收到 remote X@C_remote (>C_push) 進 pendingRemote →
    /// ACK 後本機最終為 C_remote 的值 (非停在 C_push)
    @Test
    func replayHigherRemoteIsAppliedNotDiscarded() async throws {
        let env = try Self.makeEnv()
        let id = "BL-C1"

        // baseline
        try await env.persistence.upsert(Self.order(id: id, notes: "本機舊筆記", charged: 100))

        // push 標 DIRTY
        let cPush = "1700000000000:000000:device-a"
        try await env.meta.markPushed(entityID: id, collection: "orders", clocks: ["notes": cPush])

        // 較高遠端值被 DIRTY 略過、進 pendingRemote
        let cRemote = "1700000000999:000000:device-b"
        try await env.meta.recordPendingRemote(entityID: id, collection: "orders", field: "notes", clock: cRemote)

        // ACK 採遠端權威值 + C_remote
        let response = BackendAPIClient.PatchResponse(
            appliedFieldClocks: ["notes": cRemote],
            orderData: Self.orderData(id: id, notes: "遠端新筆記", charged: 100)
        )
        await env.engine.reconcileForTesting(id: id, pushedClocks: ["notes": cPush], response: response)

        let final = try #require(try await env.persistence.fetch(id: id))
        #expect(final.notes == "遠端新筆記")
        let snapshot = try #require(try await env.meta.snapshot(entityID: id))
        #expect(snapshot.fieldClocks["notes"] == cRemote)
        #expect(!snapshot.dirtyFields.contains("notes"))
        #expect(snapshot.pendingRemote["notes"] == nil)
    }

    // MARK: - Ack 敗方採 winner

    /// push 落後值 → 後端回應 applied>pushed + order 帶 winner →
    /// 本機採 winner 值、DIRTY 清除
    @Test
    func ackLoserAdoptsWinnerFromOrderDTO() async throws {
        let env = try Self.makeEnv()
        let id = "BL-W2"
        try await env.persistence.upsert(Self.order(id: id, notes: "n", charged: 100))

        let cPush = "1700000000000:000000:device-a"
        try await env.meta.markPushed(entityID: id, collection: "orders", clocks: ["chargedAmount": cPush])

        // applied 嚴格大於 pushed：DTO 帶 winner chargedAmount=999
        let cWinner = "1700000000500:000000:device-b"
        let response = BackendAPIClient.PatchResponse(
            appliedFieldClocks: ["chargedAmount": cWinner],
            orderData: Self.orderData(id: id, notes: "n", charged: 999)
        )
        await env.engine.reconcileForTesting(id: id, pushedClocks: ["chargedAmount": cPush], response: response)

        let final = try #require(try await env.persistence.fetch(id: id))
        #expect(final.chargedAmount == 999)
        let snapshot = try #require(try await env.meta.snapshot(entityID: id))
        #expect(snapshot.fieldClocks["chargedAmount"] == cWinner)
        #expect(!snapshot.dirtyFields.contains("chargedAmount"))
    }

    /// 對照：push 勝出 (applied == pushed) → 不從 DTO 覆蓋本機、清 DIRTY
    @Test
    func ackWinnerKeepsLocalValue() async throws {
        let env = try Self.makeEnv()
        let id = "BL-W2B"
        try await env.persistence.upsert(Self.order(id: id, notes: "n", charged: 777))

        let cPush = "1700000000000:000000:device-a"
        try await env.meta.markPushed(entityID: id, collection: "orders", clocks: ["chargedAmount": cPush])

        // applied == pushed：本機勝出，DTO 不覆蓋本機
        let response = BackendAPIClient.PatchResponse(
            appliedFieldClocks: ["chargedAmount": cPush],
            orderData: Self.orderData(id: id, notes: "n", charged: 111)
        )
        await env.engine.reconcileForTesting(id: id, pushedClocks: ["chargedAmount": cPush], response: response)

        let final = try #require(try await env.persistence.fetch(id: id))
        #expect(final.chargedAmount == 777)
        let snapshot = try #require(try await env.meta.snapshot(entityID: id))
        #expect(!snapshot.dirtyFields.contains("chargedAmount"))
    }

    // MARK: - 維持刪除不砍較新本機編輯

    /// 本機 chargedAmount@2500 DIRTY 未送 + 收到 _deleted/deleteClock@2000 → 本機列未被刪
    @Test
    func staleTombstoneDoesNotDeleteNewerLocalEdit() async throws {
        let env = try Self.makeEnv()
        let id = "BL-W3"
        try await env.persistence.upsert(Self.order(id: id, notes: "n", charged: 2500))

        // 本機 chargedAmount@2500 DIRTY 未送
        let localEdit = "0000000002500:000000:device-a"
        try await env.meta.markPushed(entityID: id, collection: "orders", clocks: ["chargedAmount": localEdit])

        // 較舊 tombstone (2000 < 2500) 不該砍較新本機編輯
        let doc = Self.tombstoneDocument(id: id, deleteClock: "0000000002000:000000:device-b")
        await env.engine.mergeDocumentForTesting(doc)

        let final = try await env.persistence.fetch(id: id)
        #expect(final != nil)
    }

    /// 對照：本機無較新編輯 + 收到 tombstone → 維持刪除
    @Test
    func tombstoneDeletesWhenNoNewerLocalEdit() async throws {
        let env = try Self.makeEnv()
        let id = "BL-W3B"
        try await env.persistence.upsert(Self.order(id: id, notes: "n", charged: 100))

        // 本機無 DIRTY / pendingRemote，tombstone 直接刪
        let doc = Self.tombstoneDocument(id: id, deleteClock: "0000000002000:000000:device-b")
        await env.engine.mergeDocumentForTesting(doc)

        let final = try await env.persistence.fetch(id: id)
        #expect(final == nil)
    }

    // MARK: - 照片暫時下載失敗不覆蓋

    /// photoRefs 非空但解析回空 (下載暫時失敗) → 保留 baseline.photos 不覆蓋為空
    @Test
    func photoDownloadFailurePreservesBaselinePhotos() async throws {
        // resolvePhotoRefs 回空模擬下載失敗
        let env = try Self.makeEnv(resolvePhotoRefs: { _ in [] })
        let id = "BL-S10"
        try await env.persistence.upsert(Self.order(id: id, notes: "n", charged: 100, photos: [Data([0xAB])]))

        // photoRefs 非空但解析回空，chargedAmount 勝出
        var doc = Self.orderDocument(id: id, charged: 200, fieldClock: "1700000000000:000000:device-b")
        doc["photoRefs"] = ["users/u/orders/\(id)/photo-x.jpg"]
        await env.engine.mergeDocumentForTesting(doc)

        let final = try #require(try await env.persistence.fetch(id: id))
        // 照片保留 baseline，其餘勝出欄位仍套用
        #expect(final.photos == [Data([0xAB])])
        #expect(final.chargedAmount == 200)
    }
}

// MARK: - Helpers

extension CloudSyncEngineReconcileTests {

    /// 注入 in-memory 持久層的測試環境 (engine + 三個持久層共用同一 container)
    struct Env {

        /// 受測引擎
        let engine: CloudSyncEngine

        /// 本機訂單持久層
        let persistence: OrderPersistence

        /// 同步 metadata 持久層
        let meta: SyncMetaPersistence

        /// 待送佇列持久層
        let queue: SyncQueuePersistence
    }

    /// 建立注入 in-memory 持久層的引擎環境
    /// - Parameter resolvePhotoRefs: 照片解析閉包 (預設回空避免觸 Storage)
    /// - Returns: 組好的測試環境
    static func makeEnv(
        resolvePhotoRefs: @escaping ([String]) async -> [Data] = { _ in [] }
    ) throws -> Env {
        let container = try PersistenceContainer.make(inMemoryOnly: true)
        let persistence = OrderPersistence(modelContainer: container)
        let meta = SyncMetaPersistence(modelContainer: container)
        let queue = SyncQueuePersistence(modelContainer: container)
        let engine = CloudSyncEngine(
            uid: "test-uid",
            api: .testValue,
            idTokenProvider: { "token" },
            now: { Date(timeIntervalSince1970: 1_700_000_000) },
            resolvePhotoRefs: resolvePhotoRefs
        )
        engine.configureForTesting(
            persistence: persistence,
            metaPersistence: meta,
            queuePersistence: queue,
            writerId: "device-a"
        )
        return Env(engine: engine, persistence: persistence, meta: meta, queue: queue)
    }

    /// 建立測試訂單
    /// - Parameters:
    ///   - id: 訂單 id
    ///   - notes: 備註
    ///   - charged: 收款金額
    ///   - photos: 照片位元組
    /// - Returns: 組好的訂單
    static func order(
        id: String,
        notes: String,
        charged: Decimal,
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "", tier: .new),
            status: .confirmed,
            currency: CurrencyCode(rawValue: "TWD"),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: notes,
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: photos,
            mergedSourceIDs: []
        )
    }

    /// 組後端 PATCH 回應的 order DTO 原始欄位
    /// (對齊 ``CloudSyncEngine/decodeOrder(_:)`` 解碼路徑)
    /// - Parameters:
    ///   - id: 訂單 id
    ///   - notes: 備註
    ///   - charged: 收款金額
    /// - Returns: order DTO 的 JSONValue 欄位字典
    static func orderData(id: String, notes: String, charged: Decimal) -> [String: JSONValue] {
        [
            "id": .string(id),
            "date": .string(isoString),
            "customer": .object([
                "name": .string("客戶"),
                "initials": .string(""),
                "tier": .string("new"),
            ]),
            "status": .string("confirmed"),
            "currency": .string("TWD"),
            "chargedAmount": .string("\(charged)"),
            "notes": .string(notes),
        ]
    }

    /// 組投影文件 (帶單一欄位 clock 的 `_fieldClocks`，供 mergeDocument 測試)
    /// - Parameters:
    ///   - id: 訂單 id
    ///   - charged: 收款金額
    ///   - fieldClock: chargedAmount 的編碼 HLC
    /// - Returns: 投影文件原始欄位字典
    static func orderDocument(id: String, charged: Decimal, fieldClock: String) -> [String: Any] {
        [
            "id": id,
            "date": isoString,
            "customer": ["name": "客戶", "initials": "", "tier": "new"],
            "status": "confirmed",
            "currency": "TWD",
            "chargedAmount": "\(charged)",
            "_fieldClocks": ["chargedAmount": fieldClock],
        ]
    }

    /// 組 tombstone 投影文件 `{ _deleted:true, _deleteClock }`
    /// - Parameters:
    ///   - id: 訂單 id
    ///   - deleteClock: 刪除事件的編碼 HLC
    /// - Returns: tombstone 文件原始欄位字典
    static func tombstoneDocument(id: String, deleteClock: String) -> [String: Any] {
        [
            "id": id,
            "date": isoString,
            "customer": ["name": "客戶", "initials": "", "tier": "new"],
            "status": "confirmed",
            "currency": "TWD",
            "_deleted": true,
            "_deleteClock": deleteClock,
            "_fieldClocks": [String: String](),
        ]
    }

    /// 固定 ISO8601 日期字串 (對齊 decodeOrder 的解析格式)
    static let isoString = "2026-04-30T00:00:00.000Z"
}
