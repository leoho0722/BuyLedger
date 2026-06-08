//
//  LedgerOrder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//
//  資料形狀 (stored properties、memberwise init、conformances) 由 Generated/LedgerOrder.generated.swift 產生；
//  本檔僅保留手寫業務邏輯 (照片上限、財務摘要與合併判定)。
//  改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Static Properties

extension LedgerOrder {

    /// 單筆訂單可附加的照片張數上限。
    ///
    /// 作為唯一來源：編輯表單的 PhotosPicker `maxSelectionCount`、計數標籤與 reducer 的截斷守門皆引用此值。
    static let maxPhotoCount = 5
}

// MARK: - Computed Properties

extension LedgerOrder {

    /// 訂單的財務摘要。
    var summary: OrderSummary {
        OrderSummary(order: self)
    }

    /// 是否由「合併訂單」產生 (即非葉端訂單)。
    var isMergeResult: Bool {
        !mergedSourceIDs.isEmpty
    }

    /// 是否計入「類別收益」彙總。
    ///
    /// 統計歸屬採「合併前收益」：僅葉端訂單入組，狀態沿用既有 realized 規則並額外放行「已合併」，讓被合併的舊單以原始類別、金額與日期入帳；由合併產生的訂單一律不入組，避免重複計算。
    var contributesToCategoryBreakdown: Bool {
        !isMergeResult && (OrderStatus.realizedStatuses.contains(status) || status == .merged)
    }

    /// 列表中顯示的商品摘要，每項商品各自一行，名稱後接購買數量 (例如「藍牙耳機 x2」)。
    var itemSummary: String {
        guard !items.isEmpty else {
            return "未命名商品"
        }

        return items.map { "\($0.name) x\($0.quantity)" }.joined(separator: "\n")
    }
}
