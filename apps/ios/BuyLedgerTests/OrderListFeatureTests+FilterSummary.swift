//
//  OrderListFeatureTests+FilterSummary.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 摘要本地化固定詞並保留主檔原文、順序與分隔空格
    ///
    /// - Parameters:
    ///   - date: 已套用的日期區間
    ///   - category: 已套用的類別；`nil` 代表全部
    ///   - paymentMethod: 已套用的付款方式；`nil` 代表全部
    ///   - language: 顯示語言
    ///   - expectedSummary: 逐字相同的摘要預期值
    @Test(arguments: [
        (OrderDatePeriod.all, nil as String?, nil as String?, AppLanguage.traditionalChinese, "全部"),
        (.all, nil, nil, .english, "All"),
        (.thisWeek, nil, nil, .traditionalChinese, "本週"),
        (.thisWeek, nil, nil, .english, "This Week"),
        (.thisMonth, nil, nil, .english, "This Month"),
        (.lastMonth, nil, nil, .english, "Last Month"),
        (.all, "美妝", nil, .english, "美妝"),
        (.all, nil, "信用卡", .english, "信用卡"),
        (.all, "美妝", "信用卡", .english, "美妝 · 信用卡"),
        (.thisMonth, "美妝", "信用卡", .traditionalChinese, "本月 · 美妝 · 信用卡"),
        (.thisMonth, "美妝", "信用卡", .english, "This Month · 美妝 · 信用卡"),
        (.all, "全部", "本月", .english, "全部 · 本月"),
        (.all, "", nil, .english, ""),
        (.all, "", "現金", .traditionalChinese, " · 現金"),
        (.thisWeek, "", "", .traditionalChinese, "本週 ·  · "),
        (.all, "  美妝 \n", "Card · Visa", .english, "  美妝 \n · Card · Visa"),
    ])
    func filterSummary_已套用各種篩選_本地化固定詞並保留原文(
        date: OrderDatePeriod,
        category: String?,
        paymentMethod: String?,
        language: AppLanguage,
        expectedSummary: String
    ) {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = date
        state.selectedCategory = category
        state.selectedPaymentMethod = paymentMethod
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)
        state.filterSheet?.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .lastMonth,
            category: "未套用類別",
            paymentMethod: "未套用付款方式"
        )

        // When
        let summary = state.filterSummary(language: language)

        // Then
        #expect(summary == expectedSummary)
    }
}
