//
//  CampaignFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 開團相關畫面共用的格式化工具
enum CampaignFormatters {}

// MARK: - Internal Method

extension CampaignFormatters {

    /// 依指定 locale 將金額格式化為新台幣 (無小數位)
    ///
    /// - Parameters:
    ///   - amount: 金額
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 依選定 locale 呈現的新台幣金額字串
    static func twd(_ amount: Decimal, locale: Locale) -> String {
        BLFormatters.twd(amount, locale: locale)
    }

    /// 依指定 locale 將開團日期格式化為精簡日期
    ///
    /// - Parameters:
    ///   - date: 日期
    ///   - locale: App 選定、用於日期呈現的 locale
    /// - Returns: 依選定 locale 呈現的日期字串
    static func shortDate(_ date: Date, locale: Locale) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().locale(locale))
    }

    /// 依 locale 格式化開團日期與星期
    ///
    /// - Parameters:
    ///   - date: 日期
    ///   - locale: App 選定、用於日期呈現的 locale
    /// - Returns: 依選定 locale 呈現的日期與星期字串
    static func dayWithWeekday(_ date: Date, locale: Locale) -> String {
        let day = date.formatted(.dateTime.month(.abbreviated).day().locale(locale))
        let weekday = date.formatted(.dateTime.weekday(.abbreviated).locale(locale))
        return "\(day) \(weekday)"
    }

    /// 依指定 locale 將訂購提醒時間戳格式化為日期與提示時間
    ///
    /// - Parameters:
    ///   - date: 提醒時間戳
    ///   - locale: App 選定、用於日期與時間呈現的 locale
    /// - Returns: 依選定 locale 呈現的日期與時間字串
    static func reminderTimestamp(_ date: Date, locale: Locale) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute().locale(locale))
    }

    /// 依標題內容與列表記錄的現在時間，格式化開團列表的區段標題
    ///
    /// - Parameters:
    ///   - title: 區段或子群組的標題內容
    ///   - context: 列表出現時記錄的現在時間與行事曆，用來判斷「今天」「昨天」
    ///   - locale: App 選定、用於日期標題的 locale
    /// - Returns: 區段標題；日標題在現在當天與前一天為「今天」「昨天」，其餘依 locale 格式化
    static func sectionTitle(
        _ title: CampaignSectionTitle,
        context: CampaignDateContext,
        locale: Locale
    ) -> String {
        switch title {
        case .day(let date):
            BLFormatters.daySectionTitle(
                for: date,
                now: context.now,
                calendar: context.calendar,
                locale: locale
            )

        case .yearMonth(let date):
            BLFormatters.yearMonthSectionTitle(date, calendar: context.calendar, locale: locale)

        case .year(let date):
            BLFormatters.yearSectionTitle(date, calendar: context.calendar, locale: locale)

        case .month(let date):
            BLFormatters.monthSectionTitle(date, calendar: context.calendar, locale: locale)
        }
    }
}
