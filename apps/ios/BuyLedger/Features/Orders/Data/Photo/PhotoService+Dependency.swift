//
//  PhotoService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import PhotosUI
// PhotosPickerItem 宣告在 PhotosUI 的 SwiftUI overlay，需同時 import SwiftUI
import SwiftUI

// MARK: - DependencyKey

extension PhotoService: DependencyKey {

    /// 正式 App 逐張載入照片並降採樣為 JPEG
    static var liveValue: Self {
        Self(
            importPhotos: { items in
                var photos: [Data] = []
                var failedCount = 0
                for item in items {
                    do {
                        if let raw = try await item.loadTransferable(type: Data.self),
                           let normalized = PhotoDataProcessor.downscaledJPEGData(from: raw) {
                            photos.append(normalized)
                        } else {
                            failedCount += 1
                        }
                    } catch {
                        failedCount += 1
                    }
                }
                return PhotoImportResult(photos: photos, failedCount: failedCount)
            }
        )
    }

    /// 測試預設不匯入照片，未覆寫的操作會回報未實作 issue
    static var testValue: Self {
        Self(
            importPhotos: unimplemented(
                "PhotoService.importPhotos",
                placeholder: PhotoImportResult(photos: [], failedCount: 0)
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供訂單編輯功能取得照片匯入操作
    var photoService: PhotoService {
        get { self[PhotoService.self] }
        set { self[PhotoService.self] = newValue }
    }
}
