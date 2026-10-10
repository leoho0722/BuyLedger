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
    let orderSources: [String]

    /// 可選商品類別，包含主檔與訂單已使用的名稱
    let categories: [String]

    /// 可選付款方式與分類旗標
    let paymentMethods: [PaymentMethodInfo]

    /// 可選對帳狀態，包含主檔與訂單已使用的名稱
    let reconciliationStatuses: [String]

    /// 建立表單時仍在收單的開團名稱
    let campaigns: [String]

    /// 啟動時載入的幣別代碼清單
    let currencyCodes: [CurrencyCode]

    /// 表單完整時間使用的注入行事曆
    let calendar: Calendar

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
