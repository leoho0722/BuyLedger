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
            return "settings.preference.label.unlockFaceId"

        case .touchID:
            return "settings.preference.label.unlockTouchId"

        case .unavailable:
            return "settings.preference.label.unlock"
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
            return "settings.preference.message.whenEnabled"

        case .touchID:
            return "settings.preference.message.whenEnabledLeaving"

        case .unavailable:
            return "settings.preference.message.whenEnabledLeavingThe"
        }
    }
}
