//
//  OpenSettingsService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import UIKit

/// 開啟本 App 系統設定頁的操作入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
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

// MARK: - DependencyKey

extension OpenSettingsService: DependencyKey {

    /// 正式 App 開啟本 App 的系統設定頁
    static var liveValue: Self {
        Self(
            open: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                await MainActor.run {
                    guard UIApplication.shared.canOpenURL(url) else {
                        return
                    }
                    UIApplication.shared.open(url)
                }
            }
        )
    }

    #if DEBUG

    /// Preview 不開啟系統設定頁，只做空操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "OpenSettingsService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            open: { }
        )
    }

    #endif

    /// 測試時未覆寫的開啟操作會回報未實作 issue
    static var testValue: Self {
        Self(
            open: unimplemented("OpenSettingsService.open")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供開團功能取得開啟系統設定頁的操作
    var openSettingsService: OpenSettingsService {
        get { self[OpenSettingsService.self] }
        set { self[OpenSettingsService.self] = newValue }
    }
}
