//
//  CampaignDateSectionBuilder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 依狀態篩選與分組粒度，把開團分成日期區段與子群組的純計算
enum CampaignDateSectionBuilder {}

// MARK: - Internal Method

extension CampaignDateSectionBuilder {

    /// 依分組粒度建立開團區段與次級群組
    ///
    /// - Parameters:
    ///   - campaigns: 要分組的全部開團
    ///   - statusFilter: 只保留此狀態的開團；`nil` 表示不篩選
    ///   - grouping: 頂層區段的分組粒度
    ///   - calendar: 分桶使用的行事曆 (含時區)
    /// - Returns: 依日期由新到舊排序的區段與子群組
    static func sections(
        for campaigns: [Campaign],
        statusFilter: CampaignStatus?,
        grouping: CampaignGrouping,
        calendar: Calendar
    ) -> [CampaignDateSection] {
        let filtered = statusFilter.map { status in
            campaigns.filter {
                $0.status == status
            }
        } ?? campaigns
        let topGrouped = Dictionary(grouping: filtered) {
            topBucketStart(for: $0.openDate, grouping: grouping, calendar: calendar)
        }
        return topGrouped.keys
            .sorted(by: >)
            .map {
                CampaignDateSection(
                    id: $0,
                    title: topTitle(for: $0, grouping: grouping),
                    subgroups: subgroups(
                        of: topGrouped[$0] ?? [],
                        grouping: grouping,
                        calendar: calendar
                    )
                )
            }
    }
}

// MARK: - Private Method

private extension CampaignDateSectionBuilder {

    /// 取得頂層分組鍵：按日取當日起始、按月取當月起始、按年取當年起始
    ///
    /// - Parameters:
    ///   - date: 要轉換的開團日期
    ///   - grouping: 頂層區段的分組粒度
    ///   - calendar: 分桶使用的行事曆
    /// - Returns: 對應頂層區段的起始日期
    static func topBucketStart(
        for date: Date,
        grouping: CampaignGrouping,
        calendar: Calendar
    ) -> Date {
        switch grouping {
        case .day:
            calendar.startOfDay(for: date)

        case .month:
            calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)

        case .year:
            calendar.dateInterval(of: .year, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    /// 決定頂層標題內容：日 → 日；月 → 年月；年 → 年
    ///
    /// - Parameters:
    ///   - bucket: 頂層區段的起始日期
    ///   - grouping: 頂層區段的分組粒度
    /// - Returns: 頂層區段的標題內容
    static func topTitle(for bucket: Date, grouping: CampaignGrouping) -> CampaignSectionTitle {
        switch grouping {
        case .day:
            .day(bucket)

        case .month:
            .yearMonth(bucket)

        case .year:
            .year(bucket)
        }
    }

    /// 將頂層區段切成次級群組；按日分組時只回傳一組
    ///
    /// - Parameters:
    ///   - topCampaigns: 頂層區段內的開團
    ///   - grouping: 頂層區段的分組粒度
    ///   - calendar: 分桶使用的行事曆
    /// - Returns: 依日期由新到舊排序的次級群組
    static func subgroups(
        of topCampaigns: [Campaign],
        grouping: CampaignGrouping,
        calendar: Calendar
    ) -> [CampaignSubgroup] {
        guard grouping != .day else {
            return [
                CampaignSubgroup(
                    id: topCampaigns.first.map { calendar.startOfDay(for: $0.openDate) }
                        ?? .distantPast,
                    title: nil,
                    campaigns: sortedByDate(topCampaigns)
                ),
            ]
        }
        let subGrouped = Dictionary(grouping: topCampaigns) {
            subBucketStart(for: $0.openDate, grouping: grouping, calendar: calendar)
        }
        return subGrouped.keys
            .sorted(by: >)
            .map {
                CampaignSubgroup(
                    id: $0,
                    title: subTitle(for: $0, grouping: grouping),
                    campaigns: sortedByDate(subGrouped[$0] ?? [])
                )
            }
    }

    /// 將開團依開團日期由新到舊排序 (同一時刻再依名稱)
    ///
    /// - Parameter campaigns: 要排序的開團
    /// - Returns: 排序後的開團
    static func sortedByDate(_ campaigns: [Campaign]) -> [Campaign] {
        campaigns.sorted { lhs, rhs in
            if lhs.openDate != rhs.openDate {
                return lhs.openDate > rhs.openDate
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    /// 取得次級群組的日期鍵
    ///
    /// - Parameters:
    ///   - date: 要轉換的開團日期
    ///   - grouping: 頂層區段的分組粒度
    ///   - calendar: 分桶使用的行事曆
    /// - Returns: 對應次級群組的起始日期
    static func subBucketStart(
        for date: Date,
        grouping: CampaignGrouping,
        calendar: Calendar
    ) -> Date {
        switch grouping {
        case .day, .month:
            calendar.startOfDay(for: date)

        case .year:
            calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    /// 決定子標題內容：按月 → 日；按年 → 月
    ///
    /// - Parameters:
    ///   - bucket: 子區段的起始日期
    ///   - grouping: 頂層區段的分組粒度
    /// - Returns: 次級群組的標題內容
    static func subTitle(for bucket: Date, grouping: CampaignGrouping) -> CampaignSectionTitle {
        switch grouping {
        case .day, .month:
            .day(bucket)

        case .year:
            .month(bucket)
        }
    }
}
