//
//  SyncMetaPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/22.
//

import Foundation
import SwiftData

/// 跨裝置同步本機 metadata (``SyncMeta``) 的背景 actor CRUD。與 ``OrderPersistence`` 共用
/// ``PersistenceContainer/shared``，承載每欄位時鐘、DIRTY 集、tombstone、lastIssued HLC、
/// pendingRemote 與 photoRefs。跨邊界一律以 Sendable 投影 (``Snapshot``) 進出，不把非 Sendable
/// 的 @Model 帶出 actor。sync flag 關閉時不會被實例化或讀寫
@ModelActor
actor SyncMetaPersistence {

    // MARK: - Static Properties

    /// lastIssued HLC 專屬單例 meta 的保留 entityID (不對應任何領域實體)
    static let lastIssuedKey = "__lastIssued__"

    // MARK: - Last Issued HLC

    /// 讀回本地最後發放的 HLC (跨重啟存活以維持時鐘單調)；
    /// 任一筆 meta 皆存同一值，取其一即可
    /// - Returns: 解析後的最後發放 HLC；尚未發放過時為 nil
    func loadLastIssued() throws -> Hlc? {
        var descriptor = FetchDescriptor<SyncMeta>(
            predicate: #Predicate { $0.lastIssuedHLC != "" }
        )
        descriptor.fetchLimit = 1
        guard let encoded = try modelContext.fetch(descriptor).first?.lastIssuedHLC else {
            return nil
        }
        return Hlc(encoded: encoded)
    }

    /// 持久化本地最後發放的 HLC；
    /// 寫在 lastIssued 專屬的單例 meta 上 (entityID 為保留鍵)
    /// - Parameter hlc: 要持久化的最後發放 HLC
    func saveLastIssued(_ hlc: Hlc) throws {
        let meta = try fetchOrCreate(entityID: Self.lastIssuedKey, collection: "_meta")
        meta.lastIssuedHLC = hlc.encoded
        try modelContext.save()
    }

    /// 原子地為一組欄位生成遞增 HLC：actor 內單次「載入 → 逐欄 generate → 存回」，避免讀-改-寫在
    /// `await` 點交錯導致時鐘重複或回退。lastIssued 權威來源為 store，呼叫端
    /// (``CloudSyncEngine``) 的 in-memory 快取僅作鏡像
    /// - Parameters:
    ///   - fields: 要生成時鐘的欄位名 (依字典序生成以求決定性)
    ///   - nowMs: 注入的當下物理毫秒
    ///   - writerId: 本機寫入者識別
    /// - Returns: 每欄位的編碼 HLC 與生成後的最後 HLC (供呼叫端更新快取)
    func generateFieldClocks(
        fields: [String],
        nowMs: Int,
        writerId: String
    ) throws -> (clocks: [String: String], lastIssued: Hlc) {
        var lastIssued = try loadLastIssued()
        var clocks: [String: String] = [:]
        for field in fields.sorted() {
            let next = HlcClock.generate(lastIssued: lastIssued, nowMs: nowMs, writerId: writerId)
            lastIssued = next
            clocks[field] = next.encoded
        }
        let resolved = lastIssued ?? HlcClock.generate(lastIssued: nil, nowMs: nowMs, writerId: writerId)
        let meta = try fetchOrCreate(entityID: Self.lastIssuedKey, collection: "_meta")
        meta.lastIssuedHLC = resolved.encoded
        try modelContext.save()
        return (clocks, resolved)
    }

    /// 原子地觀察一組遠端時鐘並推進 lastIssued (RECEIVE)；
    /// 與 ``generateFieldClocks(fields:nowMs:writerId:)`` 同一序列化機制避免交錯
    /// - Parameters:
    ///   - remoteEncoded: 觀察到的遠端編碼 HLC 集合 (含 deleteClock，呼叫端先併入)
    ///   - nowMs: 注入的當下物理毫秒
    ///   - writerId: 本機寫入者識別
    /// - Returns: 推進後的最後 HLC (供呼叫端更新快取)；無有效遠端時鐘時為 nil
    func advanceLastIssued(
        observing remoteEncoded: [String],
        nowMs: Int,
        writerId: String
    ) throws -> Hlc? {
        var lastIssued = try loadLastIssued()
        var advanced = false
        for encoded in remoteEncoded {
            guard let remote = Hlc(encoded: encoded) else { continue }
            lastIssued = HlcClock.receive(lastIssued: lastIssued, remote: remote, nowMs: nowMs, writerId: writerId)
            advanced = true
        }
        guard advanced, let lastIssued else { return nil }
        let meta = try fetchOrCreate(entityID: Self.lastIssuedKey, collection: "_meta")
        meta.lastIssuedHLC = lastIssued.encoded
        try modelContext.save()
        return lastIssued
    }

    // MARK: - Field Clocks & Dirty

    /// 讀回某實體的同步 metadata 投影；不存在時回 nil
    /// - Parameter entityID: 對應領域實體的 id
    /// - Returns: 該實體的 Sendable metadata 投影；不存在時為 nil
    func snapshot(entityID: String) throws -> Snapshot? {
        guard let meta = try fetch(entityID: entityID) else { return nil }
        return Snapshot(meta: meta)
    }

    /// 推送某實體一組欄位後，記錄每欄位的 HLC 並標記為 DIRTY (尚未經後端 ack 確認勝出)
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection ("orders" / "campaigns")
    ///   - clocks: 本次推送各欄位對應的編碼 HLC
    func markPushed(
        entityID: String,
        collection: String,
        clocks: [String: String]
    ) throws {
        let meta = try fetchOrCreate(entityID: entityID, collection: collection)
        var fieldClocks = Self.decodeMap(meta.fieldClocksJSON)
        var dirty = Set(meta.dirtyFields)
        for (field, clock) in clocks {
            fieldClocks[field] = clock
            dirty.insert(field)
        }
        meta.fieldClocksJSON = Self.encodeMap(fieldClocks)
        meta.dirtyFields = Array(dirty).sorted()
        meta.pendingStateRaw = "pending"
        try modelContext.save()
    }

    /// 依後端 PATCH 回應的 appliedFieldClocks 逐欄對帳：
    /// 清除或採用 DIRTY、必要時補放 pendingRemote
    ///
    /// 規則：
    /// - applied == 本機推送時鐘 → 本機勝，寫該 clock 並清 DIRTY
    /// - applied >  本機推送時鐘 → 本機敗，採伺服器權威值 + clock 並清 DIRTY (server 值由呼叫端套進領域層)
    /// - 清除後 pendingRemote[field].clock 較 applied 高 → 回報該欄位需補套
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection
    ///   - pushedClocks: 本機本次推送各欄位的編碼 HLC
    ///   - appliedFieldClocks: 後端回傳的每欄位權威 HLC
    /// - Returns: 對帳後仍需補套的 pendingRemote 欄位清單 (clock 較 applied 高者)
    func reconcileAck(
        entityID: String,
        collection: String,
        pushedClocks: [String: String],
        appliedFieldClocks: [String: String]
    ) throws -> [PendingRemoteField] {
        let meta = try fetchOrCreate(entityID: entityID, collection: collection)
        var fieldClocks = Self.decodeMap(meta.fieldClocksJSON)
        var dirty = Set(meta.dirtyFields)
        var pendingRemote = Self.decodeMap(meta.pendingRemoteJSON)
        var replay: [PendingRemoteField] = []

        for (field, pushed) in pushedClocks {
            let applied = appliedFieldClocks[field]
            // 後端未回該欄位的權威時鐘時保守起見不清 DIRTY (留待投影核對)
            guard let applied, let appliedHlc = Hlc(encoded: applied) else { continue }
            fieldClocks[field] = applied
            dirty.remove(field)

            if let pendingEncoded = pendingRemote[field],
               let pendingHlc = Hlc(encoded: pendingEncoded),
               pendingHlc > appliedHlc {
                // pendingRemote 較高 → 補放 in-flight 窗略過的遠端值
                replay.append(PendingRemoteField(field: field, clock: pendingEncoded))
            }
            // 此欄位 pendingRemote 已不需保留 (要麼補套、要麼被 applied 蓋過)
            pendingRemote[field] = nil
            _ = pushed
        }

        meta.fieldClocksJSON = Self.encodeMap(fieldClocks)
        meta.dirtyFields = Array(dirty).sorted()
        meta.pendingRemoteJSON = Self.encodeMap(pendingRemote)
        meta.pendingStateRaw = dirty.isEmpty ? "synced" : "pending"
        try modelContext.save()
        return replay
    }

    /// 把某欄位的 pendingRemote 標記值更新 (拉取時被 DIRTY 保護而略過、但 remoteClock 較高者)
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection
    ///   - field: 欄位名
    ///   - clock: 被略過的較高遠端編碼 HLC
    func recordPendingRemote(
        entityID: String,
        collection: String,
        field: String,
        clock: String
    ) throws {
        let meta = try fetchOrCreate(entityID: entityID, collection: collection)
        var pendingRemote = Self.decodeMap(meta.pendingRemoteJSON)
        // 只保留更高者 (同欄位多次略過取最高)
        if let existing = pendingRemote[field],
           let existingHlc = Hlc(encoded: existing),
           let incomingHlc = Hlc(encoded: clock),
           incomingHlc <= existingHlc {
            return
        }
        pendingRemote[field] = clock
        meta.pendingRemoteJSON = Self.encodeMap(pendingRemote)
        try modelContext.save()
    }

    /// 拉取時某欄位被套用 (remoteClock > localClock 且非 DIRTY)，寫入該欄位的權威 clock
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection
    ///   - clocks: 本次套用的各欄位編碼 HLC
    func recordApplied(
        entityID: String,
        collection: String,
        clocks: [String: String]
    ) throws {
        let meta = try fetchOrCreate(entityID: entityID, collection: collection)
        var fieldClocks = Self.decodeMap(meta.fieldClocksJSON)
        var pendingRemote = Self.decodeMap(meta.pendingRemoteJSON)
        for (field, clock) in clocks {
            fieldClocks[field] = clock
            // 已抵達或超過，pendingRemote 此欄位不再需要
            pendingRemote[field] = nil
        }
        meta.fieldClocksJSON = Self.encodeMap(fieldClocks)
        meta.pendingRemoteJSON = Self.encodeMap(pendingRemote)
        try modelContext.save()
    }

    /// 重新訂閱時以投影核對 DIRTY：
    /// 僅投影 clock 與本機 dirty clock **相等** (我方勝、後端同 clock 重蓋章) 才清 DIRTY，
    /// 即使原 ack 遺失也能清
    ///
    /// 投影 clock 嚴格較高 (遠端較新值勝) **不在此清**，交由 push ack 的 winner 套用路徑
    /// (``CloudSyncEngine/reconcile(id:pushedClocks:response:)``) 套回權威值後再清，
    /// 避免清了 DIRTY 卻沒套 winner 值而停在落敗舊值
    /// 依賴後端對我方勝出欄位冪等重蓋 (不 re-stamp)
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - projectionClocks: 投影文件帶回的每欄位 HLC
    /// - Returns: 本次被清除的 DIRTY 欄位清單
    @discardableResult
    func reconcileDirtyAgainstProjection(
        entityID: String,
        projectionClocks: [String: String]
    ) throws -> [String] {
        guard let meta = try fetch(entityID: entityID) else { return [] }
        let fieldClocks = Self.decodeMap(meta.fieldClocksJSON)
        var dirty = Set(meta.dirtyFields)
        var cleared: [String] = []

        for field in meta.dirtyFields {
            guard let localEncoded = fieldClocks[field],
                  let localHlc = Hlc(encoded: localEncoded),
                  let projEncoded = projectionClocks[field],
                  let projHlc = Hlc(encoded: projEncoded) else {
                continue
            }
            // 相等＝我方勝，清 DIRTY；嚴格較高者交給 winner 套用路徑 (見上方 doc)
            if projHlc == localHlc {
                dirty.remove(field)
                cleared.append(field)
            }
        }

        if !cleared.isEmpty {
            meta.dirtyFields = Array(dirty).sorted()
            meta.pendingStateRaw = dirty.isEmpty ? "synced" : "pending"
            try modelContext.save()
        }
        return cleared
    }

    // MARK: - Tombstone

    /// 寫入某實體的本機刪除 tombstone 與刪除時鐘，並清空殘留的欄位時鐘 / DIRTY / pendingRemote
    ///
    /// 殘留的 `fieldClocks` 會在後續決勝 (復活判定、欄位合併) 誤用過時時鐘，故一併清空
    /// `fieldClocks` / `dirtyFields` / `pendingRemote` (復活時由拉取端以遠端權威 clock 重建)；
    /// `deleteClock` 為刪除事件唯一保留的時鐘
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection
    ///   - deleteClock: 刪除事件的編碼 HLC
    func markDeleted(
        entityID: String,
        collection: String,
        deleteClock: String
    ) throws {
        let meta = try fetchOrCreate(entityID: entityID, collection: collection)
        meta.deleteTombstone = true
        meta.deleteClock = deleteClock
        meta.fieldClocksJSON = "{}"
        meta.dirtyFields = []
        meta.pendingRemoteJSON = "{}"
        meta.pendingStateRaw = "synced"
        try modelContext.save()
    }

    /// 清除某實體的刪除 tombstone (復活)
    /// - Parameter entityID: 對應領域實體的 id
    func clearTombstone(entityID: String) throws {
        guard let meta = try fetch(entityID: entityID) else { return }
        meta.deleteTombstone = false
        meta.deleteClock = ""
        try modelContext.save()
    }

    // MARK: - Photo Refs

    /// 持久化某實體拉回的照片參照集 (Firestore Storage 路徑)，供後續下載解析回 [Data]
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection
    ///   - refs: 照片參照路徑陣列
    func savePhotoRefs(
        entityID: String,
        collection: String,
        refs: [String]
    ) throws {
        let meta = try fetchOrCreate(entityID: entityID, collection: collection)
        meta.photoRefsJSON = (try? String(decoding: JSONEncoder().encode(refs), as: UTF8.self)) ?? "[]"
        try modelContext.save()
    }
}

// MARK: - Nested Types

extension SyncMetaPersistence {

    /// ``SyncMeta`` 的 Sendable 投影 (@Model 非 Sendable，跨 actor 邊界以此傳遞)
    struct Snapshot: Sendable {

        /// 對應領域實體的 id
        let entityID: String

        /// 每欄位編碼 HLC
        let fieldClocks: [String: String]

        /// 本機已修改但尚未經 ack 確認的欄位 (DIRTY)
        let dirtyFields: Set<String>

        /// 軟刪除 tombstone
        let deleteTombstone: Bool

        /// 刪除時鐘 (編碼 HLC)，未刪除為空字串
        let deleteClock: String

        /// 被 DIRTY 保護而略過、待補放的較高遠端值 (欄位 → 編碼 HLC)
        let pendingRemote: [String: String]

        /// 照片參照路徑
        let photoRefs: [String]
    }

    /// 對帳後仍需補套的 pendingRemote 欄位
    struct PendingRemoteField: Sendable, Equatable {

        /// 欄位名
        let field: String

        /// 補放值的編碼 HLC
        let clock: String
    }
}

// MARK: - Init

private extension SyncMetaPersistence.Snapshot {

    /// 以 ``SyncMeta`` (@Model) 建立 Sendable 投影
    /// - Parameter meta: 來源 metadata 記錄
    init(meta: SyncMeta) {
        self.entityID = meta.entityID
        self.fieldClocks = SyncMetaPersistence.decodeMap(meta.fieldClocksJSON)
        self.dirtyFields = Set(meta.dirtyFields)
        self.deleteTombstone = meta.deleteTombstone
        self.deleteClock = meta.deleteClock
        self.pendingRemote = SyncMetaPersistence.decodeMap(meta.pendingRemoteJSON)
        self.photoRefs = SyncMetaPersistence.decodeArray(meta.photoRefsJSON)
    }
}

// MARK: - Private Method

private extension SyncMetaPersistence {

    /// 取某實體的 ``SyncMeta``；不存在回 nil
    /// - Parameter entityID: 對應領域實體的 id
    /// - Returns: 對應記錄；不存在時為 nil
    func fetch(entityID: String) throws -> SyncMeta? {
        let descriptor = FetchDescriptor<SyncMeta>(
            predicate: #Predicate { $0.entityID == entityID }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// 取某實體的 ``SyncMeta``；不存在時建立並插入
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id
    ///   - collection: 所屬 collection
    /// - Returns: 既有或新建的記錄
    func fetchOrCreate(entityID: String, collection: String) throws -> SyncMeta {
        if let existing = try fetch(entityID: entityID) {
            return existing
        }
        let meta = SyncMeta(entityID: entityID, collection: collection)
        modelContext.insert(meta)
        return meta
    }

    // MARK: JSON

    /// 解碼 `[String: String]` 的 JSON 字串；失敗回空字典
    /// - Parameter json: 編碼後的 JSON 字串
    /// - Returns: 解碼後的字典；失敗為空
    static func decodeMap(_ json: String) -> [String: String] {
        guard let data = json.data(using: .utf8),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return map
    }

    /// 編碼 `[String: String]` 為 JSON 字串；失敗回 `{}`
    /// - Parameter map: 來源字典
    /// - Returns: 編碼後的 JSON 字串
    static func encodeMap(_ map: [String: String]) -> String {
        guard let data = try? JSONEncoder().encode(map) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    /// 解碼 `[String]` 的 JSON 字串；失敗回空陣列
    /// - Parameter json: 編碼後的 JSON 字串
    /// - Returns: 解碼後的陣列；失敗為空
    static func decodeArray(_ json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }
}
