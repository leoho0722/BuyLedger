//
//  OrderFilterSelection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 整合篩選 sheet 尚未套用的三欄選擇
struct OrderFilterSelection: Equatable {

    // MARK: - Properties

    /// 尚未套用的日期區間選擇
    var datePeriod: OrderDatePeriod = .all

    /// 尚未套用的商品類別選擇；`nil` 代表全部類別
    var category: String?

    /// 尚未套用的付款方式選擇；`nil` 代表全部付款方式
    var paymentMethod: String?
}

// MARK: - Computed Properties

extension OrderFilterSelection {

    /// 是否至少有一項非預設的整合篩選條件
    var isActive: Bool {
        datePeriod != .all || category != nil || paymentMethod != nil
    }
}
