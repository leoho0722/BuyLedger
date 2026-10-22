//
//  PhotoService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

#if DEBUG

// MARK: - DependencyKey

extension PhotoService {

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
}

#endif
