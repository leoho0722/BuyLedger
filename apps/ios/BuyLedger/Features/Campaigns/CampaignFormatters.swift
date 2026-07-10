//
//  CampaignFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import SwiftUI

/// 開團相關畫面共用的格式化工具
enum CampaignFormatters {

    // MARK: - Static Method

    /// 將金額格式化為新台幣 (無小數位)
    /// - Parameter amount: 金額
    /// - Returns: 含 NT$ 前綴的字串
    static func twd(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(Locale(identifier: "zh_TW"))
        )
    }

    /// 將開團日期格式化為精簡的年月日
    /// - Parameter date: 日期
    /// - Returns: 例如「4月10日」的字串
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "zh_TW")))
    }

    /// 將開團日期格式化為「月日 星期」，供分組粗於「日」時於列上顯示開團日期
    /// - Parameter date: 日期
    /// - Returns: 例如「5月27日 週三」的字串
    static func dayWithWeekday(_ date: Date) -> String {
        let day = date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "zh_TW")))
        let weekday = date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "zh_TW")))
        return "\(day) \(weekday)"
    }
}

/// 開團狀態對應的視覺語意
enum CampaignStatusStyle {

    // MARK: - Static Method

    /// 取得開團狀態對應的 ``BLTone``
    /// - Parameter status: 開團狀態
    /// - Returns: 狀態膠囊使用的語意色調
    static func tone(for status: CampaignStatus) -> BLTone {
        switch status {
        case .ongoing:
            .accent
        case .closed:
            .neutral
        }
    }
}
