//
//  OrderFilterPreviewFixtures.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

/// 篩選畫面 Preview 與 snapshot 使用的固定分組與選擇
enum OrderFilterPreviewFixtures {

}

// MARK: - Internal Method

extension OrderFilterPreviewFixtures {

    /// 以單一類別建立 Preview 篩選狀態
    ///
    /// - Parameters:
    ///   - date: 已套用的日期區間
    ///   - category: 已套用的類別，省略代表全部
    ///   - paymentMethod: 已套用的付款方式，省略代表全部
    /// - Returns: 帶有兩組類別的篩選狀態
    static func makeState(
        date: OrderDatePeriod,
        category: String?,
        paymentMethod: String? = nil
    ) -> OrderFilterFeature.State {
        makeState(
            selection: OrderFilterSelection(
                datePeriod: date,
                categories: category.map { [$0] } ?? [],
                paymentMethod: paymentMethod
            )
        )
    }

    /// 以完整集合建立開團中三類、已收單五類的固定篩選狀態
    ///
    /// - Parameters:
    ///   - selection: 已套用的日期、類別與付款方式
    ///   - searchText: 類別搜尋文字，預設為空
    /// - Returns: 暫存與已套用值一致，包含長類別名稱與指定搜尋文字的篩選狀態
    static func makeState(
        selection: OrderFilterSelection,
        searchText: String = ""
    ) -> OrderFilterFeature.State {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let now = Date(timeIntervalSince1970: 1_777_507_200)
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                makeOrder(categories: ["美妝", "3C", "零食"], campaign: "春季團", date: now),
                makeOrder(categories: ["精品", "食品"], campaign: "冬季團", date: now),
            ]),
            campaigns: SharedReader(value: [
                Campaign(
                    id: "preview-spring",
                    name: "春季團",
                    openDate: now,
                    status: .ongoing,
                    notes: ""
                ),
                Campaign(
                    id: "preview-winter",
                    name: "冬季團",
                    openDate: now,
                    status: .closed,
                    notes: ""
                ),
            ]),
            lookupCatalog: SharedReader(
                value: LookupCatalog(
                    categories: [
                        "3C",
                        "美妝",
                        "零食",
                        "精品",
                        "食品",
                        "保健",
                        "書籍",
                        "aespa Lemonade QQ 音樂限定禮包",
                    ],
                    paymentMethods: [
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
                            name: "貨到付款",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        ),
                    ]
                )
            ),
            committedFilterSelection: selection,
            dateContext: OrderDateContext(now: now, calendar: calendar)
        )
        state.filterSheetSearchText = searchText
        return state
    }
}

// MARK: - Private Method

private extension OrderFilterPreviewFixtures {

    /// 建立只供類別分組使用的固定訂單
    ///
    /// - Parameters:
    ///   - categories: 訂單使用的類別
    ///   - campaign: 訂單所屬的開團名稱
    ///   - date: 固定訂單日期
    /// - Returns: 不包含隨機值的示範訂單
    static func makeOrder(categories: [String], campaign: String, date: Date) -> LedgerOrder {
        LedgerOrder(
            id: campaign,
            customer: LedgerCustomer(name: "", initials: "", tier: .regular),
            status: .purchased,
            currency: .twd,
            date: date,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: categories,
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [campaign],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
