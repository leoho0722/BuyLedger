//
//  SyncMeta.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation
import SwiftData

/// 跨裝置同步的本機專屬 metadata (sidecar)，與每筆領域實體 (order / campaign) 一一對應。
///
/// 刻意與 ``OrderRecord`` 等領域記錄分離、不進生成型別、不進 shared/data-model schema (延續
/// `ownerUid` 不污染領域模型的先例)。sync flag 關閉時不會被讀寫。map 類欄位以 JSON 字串儲存，
/// 避免 SwiftData 對 Dictionary 屬性的限制；陣列欄位以 SwiftData 原生支援的 `[String]` 儲存。
@Model
final class SyncMeta {

    // MARK: - Data Properties

    /// 對應領域實體的 id。
    var entityID: String

    /// 所屬 collection ("orders" / "campaigns")。
    var collection: String

    /// 每欄位 HLC，JSON of `[欄位名: 編碼後 HLC]`。
    var fieldClocksJSON: String

    /// 本機已修改但尚未成功推送的欄位 (DIRTY)。
    var dirtyFields: [String]

    /// 軟刪除 tombstone。
    var deleteTombstone: Bool

    /// 刪除時鐘 (編碼 HLC)，未刪除為空字串。
    var deleteClock: String

    /// 同步狀態 raw ("synced" / "pending" / "failed")。
    var pendingStateRaw: String

    /// 推送重試次數。
    var retryCount: Int

    /// 本地最後發放的 HLC (編碼)，跨重啟存活以維持時鐘單調。
    var lastIssuedHLC: String

    /// in-flight 窗口被 DIRTY 保護而略過、待清除後補放的較高時鐘遠端值，JSON of `[欄位名: 編碼 HLC 標記值]`。
    var pendingRemoteJSON: String

    /// 訂單照片的 Firestore Storage 參照，JSON of `[String]`。
    var photoRefsJSON: String

    // MARK: - Init

    /// 建立同步 metadata；除 ``entityID`` 與 ``collection`` 外皆帶 default 表示初始未同步狀態。
    /// - Parameters:
    ///   - entityID: 對應領域實體的 id。
    ///   - collection: 所屬 collection ("orders" / "campaigns")。
    ///   - fieldClocksJSON: 每欄位 HLC 的 JSON (預設空物件)。
    ///   - dirtyFields: 本機已修改但尚未成功推送的欄位 (預設空)。
    ///   - deleteTombstone: 軟刪除 tombstone (預設 false)。
    ///   - deleteClock: 刪除時鐘的編碼 HLC，未刪除為空字串 (預設空)。
    ///   - pendingStateRaw: 同步狀態 raw (預設 "synced")。
    ///   - retryCount: 推送重試次數 (預設 0)。
    ///   - lastIssuedHLC: 本地最後發放的編碼 HLC (預設空)。
    ///   - pendingRemoteJSON: 待清除後補放的較高時鐘遠端值 JSON (預設空物件)。
    ///   - photoRefsJSON: 訂單照片的 Firestore Storage 參照 JSON (預設空陣列)。
    init(
        entityID: String,
        collection: String,
        fieldClocksJSON: String = "{}",
        dirtyFields: [String] = [],
        deleteTombstone: Bool = false,
        deleteClock: String = "",
        pendingStateRaw: String = "synced",
        retryCount: Int = 0,
        lastIssuedHLC: String = "",
        pendingRemoteJSON: String = "{}",
        photoRefsJSON: String = "[]"
    ) {
        self.entityID = entityID
        self.collection = collection
        self.fieldClocksJSON = fieldClocksJSON
        self.dirtyFields = dirtyFields
        self.deleteTombstone = deleteTombstone
        self.deleteClock = deleteClock
        self.pendingStateRaw = pendingStateRaw
        self.retryCount = retryCount
        self.lastIssuedHLC = lastIssuedHLC
        self.pendingRemoteJSON = pendingRemoteJSON
        self.photoRefsJSON = photoRefsJSON
    }
}
