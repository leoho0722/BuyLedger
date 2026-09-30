//
//  CampaignGrouping.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/29.
//

/// 開團列表的日期分組粒度
enum CampaignGrouping: String, CaseIterable, Sendable {

    /// 依「日」分組
    case day

    /// 依「月」分組
    case month

    /// 依「年」分組
    case year
}

// MARK: - Computed Properties

extension CampaignGrouping {

    /// 顯示在選單中的名稱
    var title: String {
        switch self {
        case .day:
            "按日分組"

        case .month:
            "按月分組"

        case .year:
            "按年分組"
        }
    }
}

// MARK: - Identifiable

extension CampaignGrouping: Identifiable {

    /// 分組粒度的穩定識別值
    var id: String {
        rawValue
    }
}
