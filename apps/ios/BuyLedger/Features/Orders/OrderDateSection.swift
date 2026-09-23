//
//  OrderDateSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單列表以「日」為單位分組後的單一日期區段
struct OrderDateSection: Equatable, Identifiable, Sendable {

    // MARK: - Properties

    /// 區段識別值，使用該日的起始時刻 (start of day)
    let id: Date

    /// 區段標題 (例如「今天」「昨天」「5月26日 週一」)
    let title: String

    /// 該日的訂單，依時間由新到舊排序
    let orders: [LedgerOrder]
}

// MARK: - Internal Method

extension OrderDateSection {

    /// 把訂單依「日」分組為日期區段，供訂單列表與合併候選清單共用
    ///
    /// - Parameters:
    ///   - orders: 要分組的訂單
    ///   - referenceDate: 判斷「今天／昨天」的基準時間
    ///   - calendar: 分組與標題使用的曆法
    ///   - locale: App 選定、用於日期區段標題的 locale
    /// - Returns: 依日期由新到舊排序的區段
    static func group(
        _ orders: [LedgerOrder],
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> [OrderDateSection] {
        let grouped = Dictionary(grouping: orders) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped.keys
            .sorted(by: >)
            .map { day in
                OrderDateSection(
                    id: day,
                    title: OrderFormatters.daySectionTitle(
                        for: day,
                        referenceDate: referenceDate,
                        calendar: calendar,
                        locale: locale
                    ),
                    orders: (grouped[day] ?? []).sorted { $0.date > $1.date }
                )
            }
    }
}
