//
//  SidebarBadgeCounts.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation

/// iPad 側邊欄「訂單」分頁的徽章計數與朗讀文字
enum SidebarBadgeCounts {

    // MARK: - Properties

    /// 視為進行中的訂單狀態
    private static let activeStatuses: Set<OrderStatus> = [
        .confirmed,
        .purchased,
        .shipping,
        .partiallyArrived,
        .arrived,
    ]
}

// MARK: - Internal Method

extension SidebarBadgeCounts {

    /// 計算目前進行中的訂單數量，顯示在側邊欄「訂單」分頁的紅色徽章
    ///
    /// - Parameter orders: 目前的訂單清單
    /// - Returns: 進行中的訂單數量
    static func activeOrderCount(orders: [LedgerOrder]) -> Int {
        orders.count { activeStatuses.contains($0.status) }
    }

    /// 提供分頁列合併朗讀後的徽章筆數文字
    ///
    /// - Parameters:
    ///   - badgeCount: 徽章數量；缺值或非正數時不朗讀
    ///   - language: 畫面使用的語言
    /// - Returns: 本地化筆數描述，沒有徽章時為空字串
    static func accessibilityValue(_ badgeCount: Int?, language: AppLanguage) -> String {
        guard let badgeCount, badgeCount > 0 else {
            return ""
        }
        return language.localizedString(forKey: "common.general.label.ldProgress", badgeCount)
    }
}
