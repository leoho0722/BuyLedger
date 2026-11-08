//
//  CustomerTier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Nested Types

extension CustomerTier {

    /// 客戶分級名稱的本地化文字或原文文字
    enum DisplayTitle {

        /// 隨 App 語言顯示的分級名稱
        ///
        /// - Parameter localizedStringResource: 分級名稱的本地化文字
        case localized(LocalizedStringResource)

        /// 不需本地化的分級名稱
        ///
        /// - Parameter string: 要原樣顯示的分級名稱
        case verbatim(String)
    }
}

// MARK: - Computed Properties

extension CustomerTier {

    /// 顯示在介面中的分級名稱
    var title: DisplayTitle {
        switch self {
        case .new:
            .localized("customers.list.label.new")

        case .regular:
            .localized("customers.list.label.returning")

        case .vip:
            .verbatim("VIP")
        }
    }
}
