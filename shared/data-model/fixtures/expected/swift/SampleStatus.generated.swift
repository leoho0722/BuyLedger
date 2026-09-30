//
//  SampleStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例狀態 (示範 enum + identity + case-iterable)
enum SampleStatus: String, CaseIterable, Codable, Sendable {

    // MARK: - Cases

    /// 進行中
    case active

    /// 已封存
    case archived

    /// 部分到貨 (示範多字駝峰式 case 的平台命名轉換)
    case partiallyArrived
}

// MARK: - Identifiable

extension SampleStatus: Identifiable {

    /// 以實際保存的值作為穩定識別
    var id: String { rawValue }
}
