//
//  PhotoService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import PhotosUI
// PhotosPickerItem 宣告在 PhotosUI 的 SwiftUI overlay，需同時 import SwiftUI
import SwiftUI

/// 從 `PhotosPicker` 選取項目匯入照片的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct PhotoService: Sendable {

    // MARK: - Properties

    /// 載入選取項目並正規化為可儲存的照片資料
    ///
    /// - Parameter items: 使用者由 `PhotosPicker` 選取的項目
    /// - Returns: 正規化成功的照片資料與失敗張數
    var importPhotos: ImportPhotos
}

// MARK: - Nested Types

extension PhotoService {

    /// `importPhotos` 的函式型別
    typealias ImportPhotos = @Sendable (_ items: [PhotosPickerItem]) async -> PhotoImportResult
}
