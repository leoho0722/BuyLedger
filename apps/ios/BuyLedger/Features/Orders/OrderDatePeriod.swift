//
//  OrderDatePeriod.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單列表使用的日期區間篩選
enum OrderDatePeriod: Hashable, Identifiable, CaseIterable {
    
    // MARK: - Cases
    
    /// 顯示全部日期
    case all
    
    /// 僅顯示本週的訂單
    case thisWeek
    
    /// 僅顯示本月的訂單
    case thisMonth
    
    /// 僅顯示上個月的訂單
    case lastMonth
    
    // MARK: - Identifiable Properties
    
    /// 篩選選項的穩定識別值
    var id: String { rawIdentifier }
    
    /// 篩選選項在 UI 與測試中使用的字串識別值
    private var rawIdentifier: String {
        switch self {
        case .all:
            "all"
        case .thisWeek:
            "thisWeek"
        case .thisMonth:
            "thisMonth"
        case .lastMonth:
            "lastMonth"
        }
    }
    
    // MARK: - Static Properties
    
    /// 訂單瀏覽列表中提供的固定順序
    static let orderBrowsingCases: [OrderDatePeriod] = [
        .all,
        .thisWeek,
        .thisMonth,
        .lastMonth,
    ]
    
    // MARK: - Display Properties
    
    /// 顯示在篩選列中的標題
    var title: String {
        switch self {
        case .all:
            "全部時間"
        case .thisWeek:
            "本週"
        case .thisMonth:
            "本月"
        case .lastMonth:
            "上月"
        }
    }
}

// MARK: - Internal Method

extension OrderDatePeriod {
    
    /// 判斷指定日期是否在此區間內
    /// - Parameters:
    ///   - date: 要判斷的訂單日期
    ///   - referenceDate: 計算「本週/本月」等相對區間的基準日，通常為現在時間
    ///   - calendar: 用來計算區間的曆法
    /// - Returns: 若 `.all` 永遠回傳 `true`，否則只在 `date` 落於區間內時回傳 `true`
    func includes(
        _ date: Date,
        referenceDate: Date,
        calendar: Calendar
    ) -> Bool {
        guard let range = dateRange(referenceDate: referenceDate, calendar: calendar) else {
            return true
        }
        
        return range.contains(date)
    }
    
    /// 回傳此區間在指定基準日下的時間範圍
    /// - Parameters:
    ///   - referenceDate: 計算區間的基準日
    ///   - calendar: 用來計算區間的曆法
    /// - Returns: `.all` 回傳 `nil`，其他值回傳日期區間
    func dateRange(referenceDate: Date, calendar: Calendar) -> Range<Date>? {
        switch self {
        case .all:
            return nil
            
        case .thisWeek:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
            else {
                return nil
            }
            
            return weekInterval.start..<weekInterval.end
            
        case .thisMonth:
            guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate) else {
                return nil
            }
            
            return monthInterval.start..<monthInterval.end
            
        case .lastMonth:
            guard let thisMonthInterval = calendar.dateInterval(of: .month, for: referenceDate),
                  let lastMonthStart = calendar.date(
                    byAdding: .month,
                    value: -1,
                    to: thisMonthInterval.start
                  ) else {
                return nil
            }
            
            return lastMonthStart..<thisMonthInterval.start
        }
    }
}
