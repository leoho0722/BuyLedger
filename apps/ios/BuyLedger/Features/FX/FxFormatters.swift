//
//  FxFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation

/// 匯率工具專用的格式化規則
enum FxFormatters {}

// MARK: - Internal Method

extension FxFormatters {

    /// 依指定 locale 格式化匯率；無資料時顯示破折號
    ///
    /// - Parameters:
    ///   - rate: 一單位來源幣別對應的新台幣匯率
    ///   - locale: 用於呈現的 locale
    /// - Returns: 四位小數的匯率字串，或無資料時的破折號
    static func rate(_ rate: Decimal?, locale: Locale) -> String {
        guard let rate else {
            return "—"
        }
        return rate.formatted(
            .number
                .precision(.fractionLength(4))
                .locale(locale)
        )
    }

    /// 依指定 locale 格式化匯率快照時間
    ///
    /// - Parameters:
    ///   - date: 匯率快照日期；無日期時為 `nil`
    ///   - locale: 用於呈現的 locale
    /// - Returns: 月日與時分字串，或無日期時的破折號
    static func snapshotTimestamp(_ date: Date?, locale: Locale) -> String {
        guard let date else {
            return "—"
        }
        return date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .hour(.defaultDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(locale)
        )
    }

    /// 依指定 locale 格式化快速金額
    ///
    /// - Parameters:
    ///   - amount: 快速金額
    ///   - locale: 用於呈現的 locale
    /// - Returns: 不含小數位的金額字串
    static func presetAmount(_ amount: Decimal, locale: Locale) -> String {
        amount.formatted(
            .number
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }
}
