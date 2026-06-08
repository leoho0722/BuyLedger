//
//  CurrencyCode.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import Foundation

/// 交易幣別。
///
/// rawValue 為 ISO 4217 三位代碼 (例如 "USD"、"TWD")。實際可用的幣別清單於執行期由匯率服務動態取得、不寫死；在地化顯示名稱依使用者地區動態解析，不硬編於資料模型。
struct CurrencyCode: Hashable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 包裝的原始值。
    let rawValue: String

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)。
    var id: String { rawValue }
}
