//
//  InsightsHeatmap.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 分析頁下單熱力圖的格子資料，以過去幾週的週次與星期為座標記錄每天的下單筆數
struct InsightsHeatmap: Equatable {

    // MARK: - Properties

    /// 熱力圖涵蓋的週數，由最早的一週排到本週
    static let weekCount = 8

    /// 每個週次與星期組合的下單筆數，沒有訂單的格子不在字典內
    let cells: [Key: Int]

    /// 整張熱力圖中最高的單日訂單筆數，沒有資料時為 1
    let maxCount: Int
}

// MARK: - Nested Types

extension InsightsHeatmap {

    /// 熱力圖上一個格子的座標
    struct Key: Hashable {

        /// 第幾週 (0 為最早、7 為本週)
        let week: Int

        /// 第幾天 (0 為週一、6 為週日)
        let weekday: Int
    }
}

// MARK: - Internal Method

extension InsightsHeatmap {

    /// 計算過去幾週每天的下單筆數與單日最高筆數
    ///
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - referenceDate: 基準「現在」時間，決定「本週」的位置
    ///   - calendar: 計算週界的行事曆；熱力圖固定週一為每週起點
    /// - Returns: 各格的訂單筆數與單日最高筆數；沒有資料時最高筆數為 1
    static func make(
        orders: [LedgerOrder],
        referenceDate: Date,
        calendar: Calendar
    ) -> InsightsHeatmap {
        var calendar = calendar
        // 熱力圖以週一為每週起點，分組也使用週一
        calendar.firstWeekday = 2
        let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        guard let currentWeekStart = currentWeekInterval?.start else {
            return InsightsHeatmap(cells: [:], maxCount: 1)
        }

        var cells: [Key: Int] = [:]
        for order in orders {
            if let key = cell(for: order, currentWeekStart: currentWeekStart, calendar: calendar) {
                cells[key, default: 0] += 1
            }
        }
        return InsightsHeatmap(cells: cells, maxCount: cells.values.max() ?? 1)
    }
}

// MARK: - Private Method

private extension InsightsHeatmap {

    /// 算出訂單落在熱力圖上的格子，超出顯示週數的訂單回傳 `nil`
    ///
    /// - Parameters:
    ///   - order: 要定位的訂單
    ///   - currentWeekStart: 本週的起點時間
    ///   - calendar: 以週一為起點的行事曆
    /// - Returns: 訂單所在的格子座標；超出顯示範圍時為 `nil`
    static func cell(for order: LedgerOrder, currentWeekStart: Date, calendar: Calendar) -> Key? {
        let orderWeekInterval = calendar.dateInterval(of: .weekOfYear, for: order.date)
        guard let orderWeekStart = orderWeekInterval?.start else {
            return nil
        }
        // 依週起點差距計算欄位，避免跨週誤差
        let daysBetween = calendar.dateComponents(
            [.day],
            from: orderWeekStart,
            to: currentWeekStart
        ).day ?? 0
        let weeksAgo = daysBetween / 7
        let weekIndex = (InsightsHeatmap.weekCount - 1) - weeksAgo
        guard weekIndex >= 0, weekIndex < InsightsHeatmap.weekCount else {
            return nil
        }

        // `weekday`: 1=週日 ... 7=週六；轉成 0=週一 ... 6=週日
        let raw = calendar.component(.weekday, from: order.date)
        let weekday = (raw + 5) % 7
        return Key(week: weekIndex, weekday: weekday)
    }
}
