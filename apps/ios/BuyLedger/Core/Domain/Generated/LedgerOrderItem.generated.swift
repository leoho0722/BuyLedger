//
//  LedgerOrderItem.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 訂單中的商品項目
struct LedgerOrderItem: Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 商品項目的穩定識別值
    let id: UUID

    /// 商品名稱
    var name: String

    /// 商品數量
    var quantity: Int

    /// 商品單價
    var unitPrice: Decimal

    // MARK: - Init

    /// 建立 LedgerOrderItem
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        unitPrice: Decimal
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
}
