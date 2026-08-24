//
//  OrderStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 訂單目前狀態
enum OrderStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 正在報價
    case quoting

    /// 客戶已確認
    case confirmed

    /// 已完成下單
    case purchased

    /// 運送中
    case shipping

    /// 部分到貨
    case partiallyArrived

    /// 已到貨但未交付客戶
    case arrived

    /// 已交付客戶
    case delivered

    /// 客戶已取貨
    case pickedUp

    /// 已取消
    case cancelled

    /// 已合併到其他訂單
    case merged

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)
    var id: String { rawValue }
}
