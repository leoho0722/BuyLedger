//
//  OrderEditOptions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation

/// 建立訂單編輯表單時帶入的選項與日期格式化行事曆
struct OrderEditOptions: Equatable, Sendable {

    // MARK: - Properties

    /// 可選訂單來源，包含主檔與訂單已使用的名稱
    var orderSources: [String]

    /// 可選商品類別，包含主檔與訂單已使用的名稱
    var categories: [String]

    /// 可選付款方式與分類旗標
    var paymentMethods: [PaymentMethodInfo]

    /// 可選對帳狀態，包含主檔與訂單已使用的名稱
    var reconciliationStatuses: [String]

    /// 建立表單時仍在收單的開團名稱
    var campaigns: [String]

    /// 啟動時載入的幣別代碼清單
    var currencyCodes: [CurrencyCode]

    /// 表單完整時間使用的注入行事曆
    var calendar: Calendar

    // MARK: - Init

    /// 建立表單選項並保存呼叫端注入的行事曆
    ///
    /// - Parameters:
    ///   - orderSources: 可選訂單來源
    ///   - categories: 可選商品類別
    ///   - paymentMethods: 可選付款方式與分類旗標
    ///   - reconciliationStatuses: 可選對帳狀態
    ///   - campaigns: 可選開團名稱
    ///   - currencyCodes: 可選幣別代碼；空清單保留表單的常用幣別退回行為
    ///   - calendar: 完整時間使用的行事曆
    init(
        orderSources: [String] = [],
        categories: [String] = [],
        paymentMethods: [PaymentMethodInfo] = [],
        reconciliationStatuses: [String] = [],
        campaigns: [String] = [],
        currencyCodes: [CurrencyCode] = [],
        calendar: Calendar
    ) {
        self.orderSources = orderSources
        self.categories = categories
        self.paymentMethods = paymentMethods
        self.reconciliationStatuses = reconciliationStatuses
        self.campaigns = campaigns
        self.currencyCodes = currencyCodes
        self.calendar = calendar
    }
}

// MARK: - Computed Properties

extension OrderEditOptions {

    /// 未帶入選項時的空值，以固定 UTC 西曆維持初始化的可重現性
    static var empty: Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return Self(calendar: calendar)
    }
}

// MARK: - Internal Method

extension OrderEditOptions {

    /// 將已落盤的主檔選項加入清單，同名付款方式覆寫旗標，其餘名稱去重並自然排序
    ///
    /// - Parameter request: 已成功落盤且名稱已整理的主檔新增請求
    mutating func applyAddition(_ request: LookupAdditionRequest) {
        let trimmed = request.addition.name
        let flags = request.addition.flags
        switch request.kind {
        case .orderSource:
            Self.append(trimmed, to: &orderSources)

        case .category:
            Self.append(trimmed, to: &categories)

        case .paymentMethod:
            if let index = paymentMethods.firstIndex(where: { $0.name == trimmed }) {
                paymentMethods[index] = PaymentMethodInfo(name: trimmed, flags: flags)
            } else {
                var updated = paymentMethods
                updated.append(PaymentMethodInfo(name: trimmed, flags: flags))
                paymentMethods = updated.sorted { lhs, rhs in
                    lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
            }

        case .reconciliationStatus:
            Self.append(trimmed, to: &reconciliationStatuses)
        }
    }
}

// MARK: - Private Method

private extension OrderEditOptions {

    /// 清單尚無同名項目時加入名稱，並沿用自然排序
    ///
    /// - Parameters:
    ///   - name: 已整理的非空名稱
    ///   - options: 要補入新名稱的可選清單
    static func append(_ name: String, to options: inout [String]) {
        if !options.contains(name) {
            var updated = options
            updated.append(name)
            options = updated.sorted { lhs, rhs in
                lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
        }
    }
}
