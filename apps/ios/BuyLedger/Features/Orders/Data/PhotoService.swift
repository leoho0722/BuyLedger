//
//  PhotoService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

/// 從 `PhotosPicker` 選取項目匯入照片的操作入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct PhotoService: Sendable {

    // MARK: - Properties

    /// 載入選取的照片，縮小後轉成 JPEG
    ///
    /// - Parameter items: 使用者由 `PhotosPicker` 選取的項目
    /// - Returns: 成功轉成 JPEG 的照片資料與失敗張數
    var importPhotos: ImportPhotos
}

// MARK: - Nested Types

extension PhotoService {

    /// `importPhotos` 的函式型別
    typealias ImportPhotos = @Sendable (_ items: [PhotosPickerItem]) async -> PhotoImportResult
}

// MARK: - DependencyKey

extension PhotoService: DependencyKey {

    /// 正式 App 逐張載入照片，縮小後轉成 JPEG
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

    #if DEBUG

    /// Preview 不載入系統照片，只回傳空的匯入結果
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PhotoService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            importPhotos: { _ in
                PhotoImportResult(photos: [], failedCount: 0)
            }
        )
    }

    #endif

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
