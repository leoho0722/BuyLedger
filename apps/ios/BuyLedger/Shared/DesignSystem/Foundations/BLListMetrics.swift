//
//  BLListMetrics.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import SwiftUI

/// 列內元素的尺寸 token
enum BLListMetrics {

    // MARK: - Properties

    /// 列內頭像的尺寸
    static let avatarSize: CGFloat = 40

    /// 分隔線的左側內縮量
    static let dividerInset: CGFloat = BLSpacing.large + avatarSize + BLSpacing.medium
}
