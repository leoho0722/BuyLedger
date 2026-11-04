//
//  BLReadableContentType.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/30.
//

import SwiftUI

/// 內容類型偏好，定義不同內容的閱讀寬度上限
enum BLReadableContentType: Equatable, Sendable {

    /// 一般長文字或純文字段落
    case text

    /// 輸入表單或設定欄位
    case form

    /// 圖表或資料視覺化
    case chart
}

// MARK: - Computed Properties

extension BLReadableContentType {

    /// 依 iPad 實測確認的最大寬度基準值 (單位：pt)
    ///
    /// - Note: 文字 640 pt、表單 680 pt 與圖表 840 pt 已於 iPad 測量確認
    var candidateMaximumWidth: CGFloat {
        switch self {
        case .text:
            return 640

        case .form:
            return 680

        case .chart:
            return 840
        }
    }
}
