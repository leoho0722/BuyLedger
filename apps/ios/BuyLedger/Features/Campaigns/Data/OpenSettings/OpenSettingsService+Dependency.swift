//
//  OpenSettingsService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import UIKit

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
