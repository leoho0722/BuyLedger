//
//  CustomerRankBadgeStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 客戶名次徽章的配色
enum CustomerRankBadgeStyle {

    /// 第一名
    case first

    /// 第二名
    case second

    /// 第三名以後
    case other
}

// MARK: - Computed Properties

extension CustomerRankBadgeStyle {

    /// 徽章底色
    var background: Color {
        switch self {
        case .first:
            Color("BLRankBadgeFirstBackground", bundle: .assets)

        case .second:
            BLTone.neutral.indicator

        case .other:
            .blFillTertiary
        }
    }

    /// 徽章數字色
    var numeral: Color {
        switch self {
        case .first:
            .white

        case .second:
            BLTone.neutral.onIndicator

        case .other:
            .blSecondaryLabel
        }
    }
}

// MARK: - Internal Method

extension CustomerRankBadgeStyle {

    /// 依名次回傳對應的徽章配色
    ///
    /// - Parameter rank: 名次，自 1 起算
    /// - Returns: 對應的配色分支
    static func style(forRank rank: Int) -> CustomerRankBadgeStyle {
        switch rank {
        case 1:
            .first

        case 2:
            .second

        default:
            .other
        }
    }
}
