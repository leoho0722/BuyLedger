//
//  OpenSettingsService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

/// 開啟本 App 系統設定頁的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct OpenSettingsService: Sendable {

    // MARK: - Properties

    /// 開啟 BuyLedger 的系統設定頁
    var open: Open
}

// MARK: - Nested Types

extension OpenSettingsService {

    /// `open` 的函式型別
    typealias Open = @Sendable () async -> Void
}
