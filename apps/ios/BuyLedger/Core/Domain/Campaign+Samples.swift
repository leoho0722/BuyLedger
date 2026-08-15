//
//  Campaign+Samples.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

// MARK: - Sample Data

extension Campaign {
    
#if DEBUG
    
    /// Preview 與測試使用的開團範例
    nonisolated static let sampleCampaigns: [Campaign] = [
        Campaign(
            id: "CMP-SAMPLE-KR-APR",
            name: "四月韓國團",
            openDate: sampleDate(year: 2026, month: 4, day: 10),
            closeDate: sampleDate(year: 2026, month: 4, day: 30),
            status: .ongoing,
            settledDate: nil,
            notes: "美妝與服飾為主，集運倉收滿即出。"
        ),
        Campaign(
            id: "CMP-SAMPLE-JP-MAR",
            name: "三月日本團",
            openDate: sampleDate(year: 2026, month: 3, day: 1),
            closeDate: sampleDate(year: 2026, month: 3, day: 15),
            status: .closed,
            settledDate: sampleDate(year: 2026, month: 4, day: 5),
            notes: ""
        ),
    ]
#else
    nonisolated static let sampleCampaigns: [Campaign] = []
#endif
}

// MARK: - Private Method

private extension Campaign {
    
    /// 建立固定時區的範例日期
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 可重現的範例日期
    nonisolated static func sampleDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
