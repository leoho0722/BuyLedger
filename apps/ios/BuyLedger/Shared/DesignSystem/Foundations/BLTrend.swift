//
//  BLTrend.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 數值與比較基準相比的走勢方向，由差值的正負決定
enum BLTrend: CaseIterable, Equatable, Sendable {

    /// 差值大於或等於零，持平也歸為上升
    case up

    /// 差值小於零
    case down

    /// 沒有差值，無法判定方向
    case unavailable

    // MARK: - Init

    /// 依差值的正負決定走勢方向；沒有差值時無法判定
    ///
    /// - Parameter delta: 與比較基準的差值，`nil` 表示無法計算
    init(delta: Decimal?) {
        if let delta {
            self = delta < 0 ? .down : .up
        } else {
            self = .unavailable
        }
    }
}
