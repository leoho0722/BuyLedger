//
//  CustomerFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 客戶名單的名次、分級與強調區塊標題文字，畫面只負責呈現
enum CustomerFormatters {

}

// MARK: - Internal Method

extension CustomerFormatters {

    /// 組出強調區塊的標題，顯示固定的前幾名名額
    ///
    /// - Returns: 例如 `Top 3` 的標題
    static func topCountLabel() -> LocalizedStringResource {
        LocalizedStringResource(
            "customers.list.label.topCount",
            defaultValue: "\(CustomersFeature.topHighlightCount)"
        )
    }

    /// 組出 Top 客戶卡片名次膠囊的文字
    ///
    /// - Parameter rank: 名次，由 1 起算
    /// - Returns: 例如 `#1` 的文字
    static func rankLabel(_ rank: Int) -> String {
        "#\(rank)"
    }

    /// 組出客戶分級的顯示名稱；本地化名稱依 `locale` 解析，原文名稱原樣回傳
    ///
    /// - Parameters:
    ///   - tier: 客戶分級
    ///   - locale: 目前的 Locale，通常來自 `@Environment(\.locale)`
    /// - Returns: 例如 `Returning`、`常客` 或 `VIP` 的文字
    static func tierTitle(_ tier: CustomerTier, locale: Locale) -> String {
        switch tier.title {
        case .localized(let resource):
            AppLanguage.resolve(resource, locale: locale)

        case .verbatim(let text):
            text
        }
    }
}
