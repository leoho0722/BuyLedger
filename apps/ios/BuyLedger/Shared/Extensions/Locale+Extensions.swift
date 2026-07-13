//
//  Locale+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

// MARK: - Internal Method

extension Locale {

    /// 使用者在系統「語言與地區」實際偏好的 locale
    ///
    /// 以 `Locale.preferredLanguages` 首選語言建立——這才是使用者在系統設定面板親手挑的語言序列
    ///
    /// 刻意不直接用 `@Dependency(\.locale)` 預設值 (`Locale.autoupdatingCurrent`)，因為它會被 App
    /// 自身的 `CFBundleDevelopmentRegion`／已掛載 localizations 限制：App 未掛 zh-Hant 時，即使使用者
    /// 手機是繁中也會回退到開發語言，導致幣別名稱與日期顯示異常
    ///
    /// 這是全 App 唯一直接讀取系統偏好語言／`Locale.current` 的集中點；view 應一律透過本方法取得偏好 locale，而非各自內嵌相同邏輯
    /// - Parameter fallback: 系統未提供任何偏好語言時的退路；預設為 ``Locale/current``。
    ///   採 `@autoclosure` 惰性求值，只有走到 fallback 分支時才計算——view 可放心傳入
    ///   `@Dependency(\.locale)`，正常路徑 (有偏好語言) 下不會讀取它，避免在未覆寫
    ///   `\.locale` 的測試情境觸發依賴 trap
    /// - Returns: 對應使用者偏好語言的 ``Locale``
    static func preferred(fallback: @autoclosure () -> Locale = .current) -> Locale {
        guard let identifier = Locale.preferredLanguages.first else {
            return fallback()
        }
        return Locale(identifier: identifier)
    }
}
