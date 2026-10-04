//
//  AppLockFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import SwiftUI

/// 依裝置辨識類型提供鎖定畫面與設定頁的文案
enum AppLockFormatters {}

// MARK: - Internal Method

extension AppLockFormatters {

    /// 依辨識類型取得解鎖按鈕的本地化標題
    ///
    /// - Parameter biometryType: 裝置支援的辨識類型
    /// - Returns: 解鎖按鈕的本地化字串鍵
    static func unlockTitle(
        for biometryType: BiometricAuthService.BiometryKind
    ) -> LocalizedStringKey {
        switch biometryType {
        case .faceID:
            return "使用 Face ID 解鎖"

        case .touchID:
            return "使用 Touch ID 解鎖"

        case .unavailable:
            return "解鎖"
        }
    }

    /// 依辨識類型取得設定頁的 App 鎖定說明
    ///
    /// - Parameter biometryType: 裝置支援的辨識類型
    /// - Returns: 設定區段的本地化說明字串鍵
    static func protectionDescription(
        for biometryType: BiometricAuthService.BiometryKind
    ) -> LocalizedStringKey {
        switch biometryType {
        case .faceID:
            return "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Face ID 或密碼驗證才能繼續使用。"

        case .touchID:
            return "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Touch ID 或密碼驗證才能繼續使用。"

        case .unavailable:
            return "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過裝置密碼驗證才能繼續使用。"
        }
    }
}
