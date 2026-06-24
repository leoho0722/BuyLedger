//
//  SyncMetaPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/22.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// ``SyncMetaPersistence`` 的 push-ack 對帳、DIRTY 投影核對、
/// pendingRemote 與 lastIssued 持久化測試
@MainActor
struct SyncMetaPersistenceTests {

    // MARK: - Last Issued

    @Test
    func lastIssuedSurvivesRoundTrip() async throws {
        let meta = try makeMeta()
        #expect(try await meta.loadLastIssued() == nil)

        let hlc = Hlc(p: 1_700_000_000_000, c: 3, w: "device-a")
        try await meta.saveLastIssued(hlc)
        #expect(try await meta.loadLastIssued() == hlc)
    }

    // MARK: - Ack Reconciliation

    /// applied == 本機推送時鐘 → 本機勝出，寫 clock 並清 DIRTY
    @Test
    func ackWithEqualClockClearsDirty() async throws {
        let meta = try makeMeta()
        let pushed = "1700000000000:000000:device-a"
        try await meta.markPushed(entityID: "BL-1", collection: "orders", clocks: ["customerName": pushed])

        let snapshotBefore = try #require(try await meta.snapshot(entityID: "BL-1"))
        #expect(snapshotBefore.dirtyFields.contains("customerName"))

        let replays = try await meta.reconcileAck(
            entityID: "BL-1",
            collection: "orders",
            pushedClocks: ["customerName": pushed],
            appliedFieldClocks: ["customerName": pushed]
        )
        #expect(replays.isEmpty)

        let snapshotAfter = try #require(try await meta.snapshot(entityID: "BL-1"))
        #expect(!snapshotAfter.dirtyFields.contains("customerName"))
        #expect(snapshotAfter.fieldClocks["customerName"] == pushed)
    }

    /// applied > 本機推送時鐘 → 本裝置敗，採伺服器 clock 並清 DIRTY
    @Test
    func ackWithHigherServerClockAdoptsAndClearsDirty() async throws {
        let meta = try makeMeta()
        let pushed = "1700000000000:000000:device-a"
        let serverWon = "1700000000005:000000:device-b"
        try await meta.markPushed(entityID: "BL-2", collection: "orders", clocks: ["amount": pushed])

        _ = try await meta.reconcileAck(
            entityID: "BL-2",
            collection: "orders",
            pushedClocks: ["amount": pushed],
            appliedFieldClocks: ["amount": serverWon]
        )

        let snapshot = try #require(try await meta.snapshot(entityID: "BL-2"))
        #expect(!snapshot.dirtyFields.contains("amount"))
        #expect(snapshot.fieldClocks["amount"] == serverWon)
    }

    /// pendingRemote 較 applied 高 → 對帳後回報需補套
    @Test
    func ackReplaysPendingRemoteWhenHigher() async throws {
        let meta = try makeMeta()
        let pushed = "1700000000000:000000:device-a"
        let higherRemote = "1700000000999:000000:device-c"
        try await meta.markPushed(entityID: "BL-3", collection: "orders", clocks: ["notes": pushed])
        // in-flight 期間略過的更高遠端值，ack 後應補套
        try await meta.recordPendingRemote(entityID: "BL-3", collection: "orders", field: "notes", clock: higherRemote)

        let replays = try await meta.reconcileAck(
            entityID: "BL-3",
            collection: "orders",
            pushedClocks: ["notes": pushed],
            appliedFieldClocks: ["notes": pushed]
        )
        #expect(replays == [SyncMetaPersistence.PendingRemoteField(field: "notes", clock: higherRemote)])
    }

    // MARK: - Dirty Against Projection (lost-ack)

    /// 投影 clock ≥ 本機 dirty clock → 即使 ack 遺失也清 DIRTY
    @Test
    func dirtyClearsViaProjectionReconciliation() async throws {
        let meta = try makeMeta()
        let dirtyClock = "1700000000000:000000:device-a"
        try await meta.markPushed(entityID: "BL-4", collection: "orders", clocks: ["status": dirtyClock])

        // 投影已反映本裝置值 (clock ≥ dirty clock)，但 ack 遺失
        let cleared = try await meta.reconcileDirtyAgainstProjection(
            entityID: "BL-4",
            projectionClocks: ["status": dirtyClock]
        )
        #expect(cleared == ["status"])

        let snapshot = try #require(try await meta.snapshot(entityID: "BL-4"))
        #expect(!snapshot.dirtyFields.contains("status"))
    }

    /// 投影 clock < 本機 dirty clock → 維持 DIRTY (本裝置值尚未送達)
    @Test
    func dirtyStaysWhenProjectionLower() async throws {
        let meta = try makeMeta()
        try await meta.markPushed(
            entityID: "BL-5",
            collection: "orders",
            clocks: ["status": "1700000000010:000000:device-a"]
        )
        let cleared = try await meta.reconcileDirtyAgainstProjection(
            entityID: "BL-5",
            projectionClocks: ["status": "1700000000000:000000:device-a"]
        )
        #expect(cleared.isEmpty)
        let snapshot = try #require(try await meta.snapshot(entityID: "BL-5"))
        #expect(snapshot.dirtyFields.contains("status"))
    }

    /// 投影 clock 嚴格大於本機 dirty clock → **不**在此清 DIRTY (交給 winner 套用路徑)，
    /// 避免「清了 DIRTY 卻沒套 winner 值」停在落敗舊值
    @Test
    func dirtyStaysWhenProjectionStrictlyHigher() async throws {
        let meta = try makeMeta()
        try await meta.markPushed(
            entityID: "BL-5H",
            collection: "orders",
            clocks: ["status": "1700000000000:000000:device-a"]
        )
        // 投影帶嚴格較高的遠端 clock (遠端值勝出)
        let cleared = try await meta.reconcileDirtyAgainstProjection(
            entityID: "BL-5H",
            projectionClocks: ["status": "1700000000999:000000:device-b"]
        )
        #expect(cleared.isEmpty)
        let snapshot = try #require(try await meta.snapshot(entityID: "BL-5H"))
        #expect(snapshot.dirtyFields.contains("status"))
    }

    // MARK: - Tombstone

    @Test
    func tombstoneMarkAndClear() async throws {
        let meta = try makeMeta()
        let deleteClock = "1700000000000:000000:device-a"
        try await meta.markDeleted(entityID: "BL-6", collection: "orders", deleteClock: deleteClock)
        var snapshot = try #require(try await meta.snapshot(entityID: "BL-6"))
        #expect(snapshot.deleteTombstone)
        #expect(snapshot.deleteClock == deleteClock)

        try await meta.clearTombstone(entityID: "BL-6")
        snapshot = try #require(try await meta.snapshot(entityID: "BL-6"))
        #expect(!snapshot.deleteTombstone)
        #expect(snapshot.deleteClock == "")
    }

    /// 寫 tombstone 時一併清空殘留的 fieldClocks / dirtyFields / pendingRemote，
    /// 避免舊時鐘影響後續決勝
    @Test
    func tombstoneClearsResidualClocksAndDirty() async throws {
        let meta = try makeMeta()
        let id = "BL-S6"
        try await meta.markPushed(entityID: id, collection: "orders", clocks: ["notes": "1700000000000:000000:device-a"])
        try await meta.recordPendingRemote(entityID: id, collection: "orders", field: "amount", clock: "1700000000999:000000:device-b")

        var snapshot = try #require(try await meta.snapshot(entityID: id))
        #expect(!snapshot.fieldClocks.isEmpty)
        #expect(!snapshot.dirtyFields.isEmpty)
        #expect(!snapshot.pendingRemote.isEmpty)

        try await meta.markDeleted(entityID: id, collection: "orders", deleteClock: "1700000001000:000000:device-a")

        snapshot = try #require(try await meta.snapshot(entityID: id))
        #expect(snapshot.deleteTombstone)
        #expect(snapshot.fieldClocks.isEmpty)
        #expect(snapshot.dirtyFields.isEmpty)
        #expect(snapshot.pendingRemote.isEmpty)
    }

    // MARK: - Serialized Clock Generation

    /// generateFieldClocks 在 actor 內原子讀-改-寫 lastIssued，逐欄遞增且存回 store
    @Test
    func generateFieldClocksIsMonotonicAndPersisted() async throws {
        let meta = try makeMeta()
        let nowMs = 1_700_000_000_000

        let first = try await meta.generateFieldClocks(fields: ["a", "b"], nowMs: nowMs, writerId: "device-a")
        // 同毫秒下逐欄 counter+1，故嚴格遞增
        let aClock = try #require(first.clocks["a"].flatMap { Hlc(encoded: $0) })
        let bClock = try #require(first.clocks["b"].flatMap { Hlc(encoded: $0) })
        #expect(aClock < bClock)
        #expect(first.lastIssued == bClock)

        // lastIssued 存回 store，故跨輪仍嚴格遞增
        let second = try await meta.generateFieldClocks(fields: ["c"], nowMs: nowMs, writerId: "device-a")
        let cClock = try #require(second.clocks["c"].flatMap { Hlc(encoded: $0) })
        #expect(bClock < cClock)
        #expect(try await meta.loadLastIssued() == cClock)
    }

    /// 並行 push 與 receive 經 actor 序列化，lastIssued 不回退、最終單調
    @Test
    func concurrentGenerateAndReceiveDoNotRegress() async throws {
        let meta = try makeMeta()
        let nowMs = 1_700_000_000_000

        async let push: Void = {
            for _ in 0..<20 {
                _ = try? await meta.generateFieldClocks(fields: ["f"], nowMs: nowMs, writerId: "device-a")
            }
        }()
        async let receive: Void = {
            for index in 0..<20 {
                _ = try? await meta.advanceLastIssued(
                    observing: ["\(1_700_000_000_000 + index):000000:device-b"],
                    nowMs: nowMs,
                    writerId: "device-a"
                )
            }
        }()
        _ = await (push, receive)

        // 並行下 lastIssued 仍為合法 HLC 且不回退 (actor 序列化保證)
        let final = try #require(try await meta.loadLastIssued())
        #expect(final.p >= nowMs)
    }
}

// MARK: - Helpers

extension SyncMetaPersistenceTests {

    /// 以 in-memory container 建立每個測試獨立的 ``SyncMetaPersistence``
    /// - Returns: 不污染 production store 的測試 actor
    func makeMeta() throws -> SyncMetaPersistence {
        let container = try PersistenceContainer.make(inMemoryOnly: true)
        return SyncMetaPersistence(modelContainer: container)
    }
}
