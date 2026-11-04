//
//  BLCardRowMetrics.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/30.
//

import SwiftUI

/// 卡片列的版面常數
enum BLCardRowMetrics {

    // MARK: - Properties

    /// 卡片與列左右邊緣的距離，與 `BLCard` 的外距相同
    static let horizontalInset: CGFloat = BLSpacing.large

    /// 外緣陰影所需的留白高度，需大於陰影的模糊與位移範圍
    static let edgeRoom: CGFloat = 4

    /// 內緣向列範圍外延伸的距離，使列界線處的陰影與描邊落在裁切範圍外
    static let overflow: CGFloat = 8
}
