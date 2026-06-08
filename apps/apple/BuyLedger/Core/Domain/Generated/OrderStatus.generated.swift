//
//  OrderStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import Foundation

/// 訂單在代購流程中的目前狀態。
enum OrderStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 正在報價，尚未成立正式訂單。
    case quoting

    /// 客戶已確認訂單。
    case confirmed

    /// 已完成海外下單。
    case purchased

    /// 商品正在集運或國際運送。
    case shipping

    /// 商品已交付客戶。
    case delivered

    /// 訂單已取消。
    case cancelled

    /// 訂單已被合併到另一筆新訂單，僅保留作歷史紀錄。
    case merged

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)。
    var id: String { rawValue }
}
