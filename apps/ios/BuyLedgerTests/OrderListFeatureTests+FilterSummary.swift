//
//  OrderListFeatureTests+FilterSummary.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 摘要本地化固定詞並保留主檔原文、順序與分隔空格
    ///
    /// - Parameter testCase: 已套用的日期、類別、付款方式、顯示語言與逐字預期摘要
    @Test(arguments: [
        SummaryCase(
            date: OrderDatePeriod.all,
            category: nil,
            paymentMethod: nil,
            language: AppLanguage.traditionalChinese,
            expectedSummary: "全部",
        ),
        SummaryCase(
            date: .all,
            category: nil,
            paymentMethod: nil,
            language: .english,
            expectedSummary: "All",
        ),
        SummaryCase(
            date: .thisWeek,
            category: nil,
            paymentMethod: nil,
            language: .traditionalChinese,
            expectedSummary: "本週",
        ),
        SummaryCase(
            date: .thisWeek,
            category: nil,
            paymentMethod: nil,
            language: .english,
            expectedSummary: "This Week",
        ),
        SummaryCase(
            date: .thisMonth,
            category: nil,
            paymentMethod: nil,
            language: .english,
            expectedSummary: "This Month",
        ),
        SummaryCase(
            date: .lastMonth,
            category: nil,
            paymentMethod: nil,
            language: .english,
            expectedSummary: "Last Month",
        ),
        SummaryCase(
            date: .all,
            category: "美妝",
            paymentMethod: nil,
            language: .english,
            expectedSummary: "美妝",
        ),
        SummaryCase(
            date: .all,
            category: nil,
            paymentMethod: "信用卡",
            language: .english,
            expectedSummary: "信用卡",
        ),
        SummaryCase(
            date: .all,
            category: "美妝",
            paymentMethod: "信用卡",
            language: .english,
            expectedSummary: "美妝 · 信用卡",
        ),
        SummaryCase(
            date: .thisMonth,
            category: "美妝",
            paymentMethod: "信用卡",
            language: .traditionalChinese,
            expectedSummary: "本月 · 美妝 · 信用卡",
        ),
        SummaryCase(
            date: .thisMonth,
            category: "美妝",
            paymentMethod: "信用卡",
            language: .english,
            expectedSummary: "This Month · 美妝 · 信用卡",
        ),
        SummaryCase(
            date: .all,
            category: "全部",
            paymentMethod: "本月",
            language: .english,
            expectedSummary: "全部 · 本月",
        ),
        SummaryCase(
            date: .all,
            category: "",
            paymentMethod: nil,
            language: .english,
            expectedSummary: "",
        ),
        SummaryCase(
            date: .all,
            category: "",
            paymentMethod: "現金",
            language: .traditionalChinese,
            expectedSummary: " · 現金",
        ),
        SummaryCase(
            date: .thisWeek,
            category: "",
            paymentMethod: "",
            language: .traditionalChinese,
            expectedSummary: "本週 ·  · ",
        ),
        SummaryCase(
            date: .all,
            category: "  美妝 \n",
            paymentMethod: "Card · Visa",
            language: .english,
            expectedSummary: "  美妝 \n · Card · Visa",
        ),
    ])
    func filterSummary_已套用各種篩選_本地化固定詞並保留原文(testCase: SummaryCase) {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = testCase.date
        state.selectedCategories = testCase.category.map { [$0] } ?? []
        state.selectedPaymentMethod = testCase.paymentMethod
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .lastMonth,
                categories: ["未套用類別"],
                paymentMethod: "未套用付款方式"
            )
        }

        // When
        let summary = state.filterSummary(language: testCase.language)

        // Then
        #expect(summary == testCase.expectedSummary)
    }

    /// 規格表的每種篩選組合都顯示對應摘要與膠囊啟用狀態
    ///
    /// - Parameter testCase: 已套用的日期、類別、付款方式與規格表的摘要與膠囊啟用狀態
    @Test(arguments: [
        SummaryActiveCase(
            date: OrderDatePeriod.all,
            categories: Set<String>(),
            paymentMethod: nil,
            expectedSummary: "全部",
            isActive: false,
        ),
        SummaryActiveCase(
            date: .all,
            categories: Set<String>(["美妝"]),
            paymentMethod: nil,
            expectedSummary: "美妝",
            isActive: true,
        ),
        SummaryActiveCase(
            date: .thisMonth,
            categories: Set<String>(),
            paymentMethod: nil,
            expectedSummary: "本月",
            isActive: true,
        ),
        SummaryActiveCase(
            date: .thisMonth,
            categories: Set<String>(["美妝"]),
            paymentMethod: nil,
            expectedSummary: "本月 · 美妝",
            isActive: true,
        ),
        SummaryActiveCase(
            date: .thisMonth,
            categories: Set<String>(["美妝", "書籍"]),
            paymentMethod: nil,
            expectedSummary: "本月 · 2 項類別",
            isActive: true,
        ),
        SummaryActiveCase(
            date: .lastMonth,
            categories: Set<String>(["3C"]),
            paymentMethod: "信用卡",
            expectedSummary: "上月 · 3C · 信用卡",
            isActive: true,
        ),
        SummaryActiveCase(
            date: .all,
            categories: Set<String>(),
            paymentMethod: "現金",
            expectedSummary: "現金",
            isActive: true,
        ),
    ])
    func filterSummary_範例表各種組合_顯示摘要與啟用狀態(testCase: SummaryActiveCase) {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = testCase.date
        state.selectedCategories = testCase.categories
        state.selectedPaymentMethod = testCase.paymentMethod

        // When
        let summary = state.filterSummary(language: .traditionalChinese)
        let hasActiveFilter = state.committedFilterSelection.isActive

        // Then
        #expect(summary == testCase.expectedSummary)
        #expect(hasActiveFilter == testCase.isActive)
    }

    /// 多選摘要顯示類別數量，保留日期與付款方式的順序
    ///
    /// - Parameter testCase: 已套用的類別集合、顯示語言與摘要的字面值預期
    @Test(arguments: [
        MultiCategorySummaryCase(
            categories: Set<String>(["美妝", "書籍"]),
            language: AppLanguage.traditionalChinese,
            expectedSummary: "本月 · 2 項類別",
        ),
        MultiCategorySummaryCase(
            categories: Set<String>(["美妝", "書籍"]),
            language: .english,
            expectedSummary: "This Month · 2 Categories",
        ),
        MultiCategorySummaryCase(
            categories: Set<String>(["美妝", "書籍", "3C"]),
            language: .traditionalChinese,
            expectedSummary: "本月 · 3 項類別",
        ),
        MultiCategorySummaryCase(
            categories: Set<String>(["美妝", "書籍", "3C"]),
            language: .english,
            expectedSummary: "This Month · 3 Categories",
        ),
    ])
    func filterSummary_已套用多個類別_顯示本地化數量(testCase: MultiCategorySummaryCase) {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = testCase.categories

        // When
        let summary = state.filterSummary(language: testCase.language)

        // Then
        #expect(summary == testCase.expectedSummary)
        #expect(state.committedFilterSelection.isActive == true)
    }
}

// MARK: - Nested Types

extension OrderListFeatureTests {

    /// 已套用的篩選條件與顯示語言的摘要案例
    struct SummaryCase: Sendable {

        /// 已套用的日期區間
        let date: OrderDatePeriod

        /// 已套用的類別，`nil` 代表全部
        let category: String?

        /// 已套用的付款方式，`nil` 代表全部
        let paymentMethod: String?

        /// 顯示語言
        let language: AppLanguage

        /// 逐字相同的摘要預期值
        let expectedSummary: String
    }

    /// 已套用的篩選條件與規格表預期結果的案例
    struct SummaryActiveCase: Sendable {

        /// 已套用的日期區間
        let date: OrderDatePeriod

        /// 已套用的類別集合
        let categories: Set<String>

        /// 已套用的付款方式
        let paymentMethod: String?

        /// 規格表的摘要
        let expectedSummary: String

        /// 規格表的膠囊啟用狀態
        let isActive: Bool
    }

    /// 多類別摘要的案例
    struct MultiCategorySummaryCase: Sendable {

        /// 已套用的類別集合
        let categories: Set<String>

        /// 顯示語言
        let language: AppLanguage

        /// 摘要的字面值預期
        let expectedSummary: String
    }
}
