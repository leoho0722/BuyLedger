//
//  RootTab.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// App 主要導覽分頁。
enum RootTab: String, CaseIterable, Identifiable {

    // MARK: - Cases

    /// 總覽頁。
    case dashboard

    /// 訂單頁。
    case orders

    /// 開團頁。
    case campaigns

    /// 分析頁。
    case insights

    /// 更多與設定頁。
    case more

    // MARK: - Identifiable Properties

    /// 分頁的穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 分頁標題。
    var title: String {
        switch self {
        case .dashboard:
            "總覽"
        case .orders:
            "訂單"
        case .campaigns:
            "開團"
        case .insights:
            "分析"
        case .more:
            "更多"
        }
    }

    /// 分頁使用的 SF Symbols 名稱。
    var systemImage: String {
        switch self {
        case .dashboard:
            "house"
        case .orders:
            "list.bullet.rectangle"
        case .campaigns:
            "shippingbox"
        case .insights:
            "chart.bar.xaxis"
        case .more:
            "ellipsis.circle"
        }
    }
}
