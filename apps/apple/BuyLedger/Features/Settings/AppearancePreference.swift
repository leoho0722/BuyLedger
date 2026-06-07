//
//  AppearancePreference.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/31.
//

import Foundation

/// 介面外觀模式偏好。
enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {

    // MARK: - Cases

    /// 跟隨系統外觀。
    case system

    /// 強制淺色。
    case light

    /// 強制深色。
    case dark

    // MARK: - Identifiable Properties

    /// 偏好的穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在介面中的名稱。
    var title: String {
        switch self {
        case .system:
            "自動"
        case .light:
            "淺色"
        case .dark:
            "深色"
        }
    }
}
