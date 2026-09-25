//
//  PhotoImportResult.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation

/// 照片匯入成功資料與失敗張數
struct PhotoImportResult: Equatable, Sendable {

    // MARK: - Properties

    /// 正規化成功的照片資料
    let photos: [Data]

    /// 載入或正規化失敗的照片張數
    let failedCount: Int
}
