//
//  SidebarSmartGroup.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import SwiftUI

/// 側邊欄「智慧分組」中以訂單狀態與顏色呈現的項目，點選後切到訂單頁並套用該狀態篩選
enum SidebarSmartGroup: String, CaseIterable, Sendable {

    /// 報價中的訂單分組
    case quoting

    /// 已確認但尚未下單的訂單分組
    case confirmed

    /// 已下單但尚未集運的訂單分組
    case purchased

    /// 集運中的訂單分組
    case shipping

    /// 部分商品已到貨的訂單分組
    case partiallyArrived

    /// 已到貨但尚未交付的訂單分組
    case arrived

    /// 已交付完成的訂單分組
    case delivered

    /// 買家已取貨完成的訂單分組
    case pickedUp

    // MARK: - Properties

    /// 訂單瀏覽 sidebar 中提供的固定順序 (依訂單生命週期由前到後排)
    static let orderBrowsingCases: [SidebarSmartGroup] = [
        .quoting,
        .confirmed,
        .purchased,
        .shipping,
        .partiallyArrived,
        .arrived,
        .delivered,
        .pickedUp,
    ]
}

// MARK: - Computed Properties

extension SidebarSmartGroup {

    /// 對應的訂單狀態
    var status: OrderStatus {
        switch self {
        case .quoting:
            .quoting

        case .confirmed:
            .confirmed

        case .purchased:
            .purchased

        case .shipping:
            .shipping

        case .partiallyArrived:
            .partiallyArrived

        case .arrived:
            .arrived

        case .delivered:
            .delivered

        case .pickedUp:
            .pickedUp
        }
    }

    /// 對應到 UI 測試 identifier 的分組 key
    var accessibilityKey: BLAccessibilityID.Root.SmartGroup {
        switch self {
        case .quoting:
            .quoting

        case .confirmed:
            .confirmed

        case .purchased:
            .purchased

        case .shipping:
            .shipping

        case .partiallyArrived:
            .partiallyArrived

        case .arrived:
            .arrived

        case .delivered:
            .delivered

        case .pickedUp:
            .pickedUp
        }
    }
}

// MARK: - Internal Method

extension SidebarSmartGroup {

    /// 在側邊欄顯示的色點顏色
    ///
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 色點顏色
    func color(in palette: BLPalette) -> Color {
        status.sidebarHue(in: palette)
    }
}

// MARK: - Identifiable

extension SidebarSmartGroup: Identifiable {

    /// 分組的穩定識別值
    var id: String {
        rawValue
    }
}
