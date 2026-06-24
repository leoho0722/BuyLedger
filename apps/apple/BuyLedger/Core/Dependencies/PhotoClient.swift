//
//  PhotoClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import Foundation
import PhotosUI
import SwiftUI

/// 將 PhotosPicker 選取項目載入並正規化為可持久化照片 data 的依賴介面
///
/// 以依賴反轉隔離 `PhotosPickerItem.loadTransferable` 的系統呼叫，讓 ``OrderEditFeature`` 的匯入流程可在 TestStore 中以 fake 實作完整驗證
struct PhotoClient: Sendable {

    // MARK: - Dependency Properties

    /// 將選取項目逐一載入 `Data` 並交由 ``PhotoDataProcessor`` 正規化
    ///
    /// 單一項目載入失敗 (如 iCloud 照片離線) 或無法解碼時靜默略過，不阻斷其餘照片、不回傳錯誤——與「寧可空狀態也不顯示假資料」的原則一致，使用者可由縮圖數量察覺缺漏
    var importPhotos: @Sendable ([PhotosPickerItem]) async -> [Data]
}

extension PhotoClient: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時逐一呼叫 `loadTransferable(type: Data.self)` 取得原始影像，再經 ``PhotoDataProcessor`` 降採樣與 JPEG 重編碼
    nonisolated static let liveValue = PhotoClient(
        importPhotos: { items in
            var photos: [Data] = []
            for item in items {
                guard let raw = try? await item.loadTransferable(type: Data.self),
                      let normalized = PhotoDataProcessor.downscaledJPEGData(from: raw) else {
                    continue
                }
                photos.append(normalized)
            }
            return photos
        }
    )

    /// 測試預設不匯入任何照片；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = PhotoClient(
        importPhotos: { _ in [] }
    )
}
