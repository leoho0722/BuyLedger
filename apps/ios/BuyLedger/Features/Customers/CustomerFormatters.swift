//
//  CustomerFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 客戶名單的名次與強調區塊標題文字，畫面只負責呈現
enum CustomerFormatters {

}

// MARK: - Internal Method

extension CustomerFormatters {

    /// 組出強調區塊的標題，顯示固定的前幾名名額
    ///
    /// - Parameter locale: App 選定的 locale
    /// - Returns: 例如 `Top 3` 的標題
    static func topCountLabel(locale: Locale) -> String {
        AppLanguage.format(
            "customers.list.label.topCount",
            CustomersFeature.topHighlightCount,
            locale: locale
        )
    }

    /// 組出 Top 客戶卡片名次膠囊的文字
    ///
    /// - Parameter rank: 名次，由 1 起算
    /// - Returns: 例如 `#1` 的文字
    static func rankLabel(_ rank: Int) -> String {
        "#\(rank)"
    }
}
