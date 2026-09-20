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

    // MARK: - Properties

    /// 將選取項目逐一載入 `Data` 並轉成可儲存的照片資料
    /// - Parameter items: 使用者由 `PhotosPicker` 選取的項目
    /// - Returns: 正規化成功的照片資料與失敗張數
    var importPhotos: @Sendable (_ items: [PhotosPickerItem]) async -> PhotoImportResult
}

// MARK: - DependencyKey

extension PhotoClient: DependencyKey {

    /// 載入原始影像後降採樣並轉成 JPEG
    nonisolated static let liveValue = PhotoClient(
        importPhotos: { items in
            var photos: [Data] = []
            var failedCount = 0
            for item in items {
                do {
                    guard let raw = try await item.loadTransferable(type: Data.self) else {
                        failedCount += 1
                        continue
                    }
                    guard let normalized = PhotoDataProcessor.downscaledJPEGData(from: raw) else {
                        failedCount += 1
                        continue
                    }
                    photos.append(normalized)
                } catch {
                    failedCount += 1
                }
            }
            return PhotoImportResult(photos: photos, failedCount: failedCount)
        }
    )

    /// 測試預設不匯入任何照片；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = PhotoClient(
        importPhotos: { _ in PhotoImportResult(photos: [], failedCount: 0) }
    )
}
