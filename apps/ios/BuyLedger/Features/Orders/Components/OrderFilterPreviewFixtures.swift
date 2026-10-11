//
//  OrderFilterPreviewFixtures.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 篩選畫面 Preview 使用的固定主檔與選擇
enum OrderFilterPreviewFixtures {

}

// MARK: - Internal Method

extension OrderFilterPreviewFixtures {

    /// 建立 Preview 用的初始篩選 state
    ///
    /// - Parameters:
    ///   - date: 預設選中的日期區間
    ///   - category: 預設選中的類別；`nil` 代表「全部」
    ///   - paymentMethod: 預設選中的付款方式；`nil` 代表「全部」
    /// - Returns: 已套用上述條件的 `OrderFilterFeature.State`，其已提交的篩選選擇與套用內容相同
    static func makeState(
        date: OrderDatePeriod,
        category: String?,
        paymentMethod: String? = nil
    ) -> OrderFilterFeature.State {
        var state = OrderListFeature.State(orders: SharedReader(value: []))
        state.selectedDatePeriod = date
        state.selectedCategory = category
        state.selectedPaymentMethod = paymentMethod
        state.$lookupCatalog.withLock {
            $0.categories = [
                "3C",
                "美妝",
                "精品",
                "食品",
                "保健",
                "零食",
                "書籍",
                "aespa Lemonade QQ 音樂限定禮包",
            ]
            $0.paymentMethods = [
                PaymentMethodInfo(
                    name: "信用卡",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "現金",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "銀行轉帳",
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "orders.list.label.cashDelivery",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: true
                ),
            ]
        }
        return OrderFilterFeature.State(
            orders: state.$orders,
            lookupCatalog: SharedReader(state.$lookupCatalog),
            committedFilterSelection: state.committedFilterSelection
        )
    }
}
