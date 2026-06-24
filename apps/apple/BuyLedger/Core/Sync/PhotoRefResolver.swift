//
//  PhotoRefResolver.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/22.
//

@preconcurrency import FirebaseStorage
import Foundation

/// 把 Firestore 投影的 `photoRefs` (Firebase Storage 路徑參照) 下載解析回 `[Data]` 的工具
///
/// 投影文件只帶**參照字串**，client 須在欄位合併**之前**把參照下載成位元組
/// (絕不把參照字串寫進 `[Data]` 欄)，且只讀 Storage、從不上傳 (後端維持 Storage 唯一寫入方)
enum PhotoRefResolver {

    // MARK: - Static Properties

    /// 單張照片下載上限 (8 MB)，與後端正規化後的 JPEG 尺寸對齊，
    /// 防呆避免異常巨大物件
    static let maxBytesPerPhoto: Int64 = 8 * 1024 * 1024

    // MARK: - Operations

    /// 依序下載一組 `photoRefs` 為 `[Data]`；
    /// 個別參照下載失敗時略過該張 (不讓單張失敗阻斷整筆合併)
    /// 空參照集回空陣列 (不觸碰 Storage)
    /// - Parameter refs: Firebase Storage 物件路徑參照陣列
    /// - Returns: 成功下載的照片位元組陣列 (順序對齊 `refs`，失敗者被略過)
    static func resolve(refs: [String]) async -> [Data] {
        guard !refs.isEmpty else { return [] }
        let storage = Storage.storage()
        var result: [Data] = []
        for ref in refs {
            guard !ref.isEmpty else { continue }
            do {
                let data = try await storage.reference(withPath: ref)
                    .data(maxSize: maxBytesPerPhoto)
                result.append(data)
            } catch {
                // 單張失敗不阻斷整筆訂單合併
                continue
            }
        }
        return result
    }
}
