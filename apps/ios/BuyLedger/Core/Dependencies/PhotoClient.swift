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
struct PhotoClient: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 將選取項目逐一載入 `Data` 並交由 ``PhotoDataProcessor`` 正規化
    /// - Parameter items: 使用者由 `PhotosPicker` 選取的項目
    /// - Returns: 正規化成功的照片資料
    var importPhotos: @Sendable (_ items: [PhotosPickerItem]) async -> [Data]
}

// MARK: - Dependency Values

extension PhotoClient: DependencyKey {
    
    /// 載入原始影像後降採樣並轉成 JPEG
    nonisolated static let liveValue = PhotoClient(
        importPhotos: { items in
            var photos: [Data] = []
            for item in items {
                do {
                    guard let raw = try await item.loadTransferable(type: Data.self),
                          let normalized = PhotoDataProcessor.downscaledJPEGData(from: raw) else {
                        continue
                    }
                    photos.append(normalized)
                } catch {
                    continue
                }
            }
            return photos
        }
    )
    
    /// 測試預設不匯入任何照片；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = PhotoClient(
        importPhotos: { _ in [] }
    )
}
