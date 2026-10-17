//
//  OrderEditOptionNormalizer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import Foundation

/// 開啟表單時補齊草稿已使用的選項，並去除重複名稱與排序
enum OrderEditOptionNormalizer {

}

// MARK: - Internal Method

extension OrderEditOptionNormalizer {

    /// 整理父層注入的清單，並補入草稿已使用的值
    ///
    /// - Parameters:
    ///   - options: 父層提供的選項與行事曆
    ///   - draft: 開啟表單時的草稿快照，不由此型別持有
    /// - Returns: 去重、補齊並排序後的選項
    static func normalized(options: OrderEditOptions, draft: OrderDraft) -> OrderEditOptions {
        var orderSources = Set(options.orderSources)
        let orderSource = draft.orderSource.trimmingCharacters(in: .whitespacesAndNewlines)
        if !orderSource.isEmpty {
            orderSources.insert(orderSource)
        }
        let normalizedOrderSources = orderSources.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }

        var categories = Set(options.categories)
        let draftCategories = draft.categories.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        categories.formUnion(draftCategories.filter { !$0.isEmpty })
        let normalizedCategories = categories.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }

        var paymentMethods: [String: PaymentMethodInfo] = [:]
        for info in options.paymentMethods {
            paymentMethods[info.name] = info
        }
        let paymentMethod = draft.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        if !paymentMethod.isEmpty, paymentMethods[paymentMethod] == nil {
            paymentMethods[paymentMethod] = PaymentMethodInfo(
                name: paymentMethod,
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        }
        let normalizedPaymentMethods = paymentMethods.values.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }

        var reconciliationStatuses = Set(options.reconciliationStatuses)
        let reconciliationStatus = draft.reconciliationStatus
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !reconciliationStatus.isEmpty {
            reconciliationStatuses.insert(reconciliationStatus)
        }
        let normalizedReconciliationStatuses = reconciliationStatuses.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }

        var campaigns = Set(options.campaigns)
        let draftCampaigns = draft.campaignNames.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        campaigns.formUnion(draftCampaigns.filter { !$0.isEmpty })
        let normalizedCampaigns = campaigns.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }

        let currencyCodes = options.currencyCodes.isEmpty
            ? CurrencyCode.defaults : options.currencyCodes
        var currencies = Set(currencyCodes)
        currencies.insert(draft.currency)
        let normalizedCurrencies = currencies.sorted { lhs, rhs in
            lhs.rawValue.localizedStandardCompare(rhs.rawValue) == .orderedAscending
        }
        return OrderEditOptions(
            orderSources: normalizedOrderSources,
            categories: normalizedCategories,
            paymentMethods: normalizedPaymentMethods,
            reconciliationStatuses: normalizedReconciliationStatuses,
            campaigns: normalizedCampaigns,
            currencyCodes: normalizedCurrencies,
            calendar: options.calendar
        )
    }
}
