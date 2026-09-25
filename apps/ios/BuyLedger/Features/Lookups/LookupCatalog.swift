//
//  LookupCatalog.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation

/// 四種主檔 (訂單來源、商品類別、付款方式、對帳狀態) 的單一來源
struct LookupCatalog: Equatable, Sendable {

    // MARK: - Properties

    /// 訂單來源清單 (已排序)
    var orderSources: [String] = []

    /// 商品類別清單 (已排序)
    var categories: [String] = []

    /// 付款方式清單 (已排序，含各自旗標)
    var paymentMethods: [PaymentMethodInfo] = []

    /// 對帳狀態清單 (已排序)
    var reconciliationStatuses: [String] = []
}

// MARK: - Internal Method

extension LookupCatalog {

    /// 讀取指定種類目前的名稱清單
    ///
    /// - Parameter kind: 主檔種類
    /// - Returns: 名稱陣列
    func names(for kind: LookupKind) -> [String] {
        switch kind {
        case .orderSource:
            orderSources

        case .category:
            categories

        case .paymentMethod:
            paymentMethods.map(\.name)

        case .reconciliationStatus:
            reconciliationStatuses
        }
    }

    /// 依名稱讀取第一筆付款方式的分類旗標；找不到時回傳沒有旗標
    ///
    /// - Parameter name: 要查詢的付款方式名稱
    /// - Returns: 第一筆同名付款方式的旗標，或沒有旗標
    func paymentMethodFlags(named name: String) -> PaymentMethodFlags {
        paymentMethods.first { $0.name == name }?.currentFlags ?? .none
    }

    /// 用另一份目錄替換指定種類的清單，其他種類保持不變
    ///
    /// - Parameters:
    ///   - kind: 要替換的主檔種類
    ///   - catalog: 提供新清單的目錄
    mutating func replaceItems(of kind: LookupKind, from catalog: LookupCatalog) {
        switch kind {
        case .orderSource:
            orderSources = catalog.orderSources

        case .category:
            categories = catalog.categories

        case .paymentMethod:
            paymentMethods = catalog.paymentMethods

        case .reconciliationStatus:
            reconciliationStatuses = catalog.reconciliationStatuses
        }
    }

    /// 加入指定種類的新項目；名稱前後的空白會移除，空白名稱不會加入
    ///
    /// - Parameters:
    ///   - name: 尚未清除頭尾空白的名稱
    ///   - kind: 主檔種類
    ///   - flags: 付款方式分類旗標 (僅 `.paymentMethod` 有意義)
    mutating func add(
        name: String,
        kind: LookupKind,
        flags: PaymentMethodFlags = .none
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        switch kind {
        case .orderSource:
            orderSources = Self.inserting(trimmed, into: orderSources)

        case .category:
            categories = Self.inserting(trimmed, into: categories)

        case .paymentMethod:
            paymentMethods = Self.upserting(
                PaymentMethodInfo(name: trimmed, flags: flags),
                into: paymentMethods
            )

        case .reconciliationStatus:
            reconciliationStatuses = Self.inserting(trimmed, into: reconciliationStatuses)
        }
    }

    /// 移除指定種類的同名項目；找不到時清單保持不變
    ///
    /// - Parameters:
    ///   - name: 要移除的名稱
    ///   - kind: 主檔種類
    mutating func remove(name: String, kind: LookupKind) {
        switch kind {
        case .orderSource:
            orderSources.removeAll { $0 == name }

        case .category:
            categories.removeAll { $0 == name }

        case .paymentMethod:
            paymentMethods.removeAll { $0.name == name }

        case .reconciliationStatus:
            reconciliationStatuses.removeAll { $0 == name }
        }
    }

    /// 把指定種類的項目更名；新名稱空白或與舊名相同時清單保持不變
    ///
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 尚未清除頭尾空白的新名稱
    ///   - kind: 主檔種類
    mutating func rename(
        from oldName: String,
        to newName: String,
        kind: LookupKind
    ) {
        let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNew.isEmpty, trimmedNew != oldName else {
            return
        }

        switch kind {
        case .orderSource:
            orderSources = Self.renamed(
                oldName,
                to: trimmedNew,
                in: orderSources
            )

        case .category:
            categories = Self.renamed(
                oldName,
                to: trimmedNew,
                in: categories
            )

        case .paymentMethod:
            paymentMethods = Self.renamedPaymentMethods(
                oldName,
                to: trimmedNew,
                in: paymentMethods
            )

        case .reconciliationStatus:
            reconciliationStatuses = Self.renamed(
                oldName,
                to: trimmedNew,
                in: reconciliationStatuses
            )
        }
    }
}

// MARK: - Private Method

private extension LookupCatalog {

    /// 加入名稱到清單並排序，已存在則不重複
    ///
    /// - Parameters:
    ///   - name: 要加入的名稱
    ///   - list: 原始名稱清單
    /// - Returns: 加入名稱後依 locale 排序的清單
    static func inserting(
        _ name: String,
        into list: [String]
    ) -> [String] {
        guard !list.contains(name) else {
            return list
        }
        return (list + [name]).sorted { firstName, secondName in
            firstName.localizedStandardCompare(secondName) == .orderedAscending
        }
    }

    /// 加入或覆寫付款方式 (同名以新旗標覆寫)，依 locale 排序
    ///
    /// - Parameters:
    ///   - info: 要加入或覆寫的付款方式
    ///   - list: 原始付款方式清單
    /// - Returns: 加入或覆寫後依 locale 排序的清單
    static func upserting(
        _ info: PaymentMethodInfo,
        into list: [PaymentMethodInfo]
    ) -> [PaymentMethodInfo] {
        var updated = list
        if let index = updated.firstIndex(where: { $0.name == info.name }) {
            updated[index] = info
        } else {
            updated.append(info)
        }
        return updated.sorted { firstInfo, secondInfo in
            firstInfo.name.localizedStandardCompare(secondInfo.name) == .orderedAscending
        }
    }

    /// 把清單中等於 `oldName` 的項目替換成 `newName`，去重後依 locale 排序
    ///
    /// - Parameters:
    ///   - oldName: 要替換的舊名稱
    ///   - newName: 要套用的新名稱
    ///   - list: 原始名稱清單
    /// - Returns: 替換、去重並排序後的清單
    static func renamed(
        _ oldName: String,
        to newName: String,
        in list: [String]
    ) -> [String] {
        let replaced = list.map { $0 == oldName ? newName : $0 }
        return Array(Set(replaced)).sorted { firstName, secondName in
            firstName.localizedStandardCompare(secondName) == .orderedAscending
        }
    }

    /// 改名付款方式；任一邊為真的旗標都保留
    ///
    /// - Parameters:
    ///   - oldName: 要替換的舊付款方式名稱
    ///   - newName: 要套用的新付款方式名稱
    ///   - list: 原始付款方式清單
    /// - Returns: 合併旗標、去重並排序後的付款方式清單
    static func renamedPaymentMethods(
        _ oldName: String,
        to newName: String,
        in list: [PaymentMethodInfo]
    ) -> [PaymentMethodInfo] {
        var byName: [String: PaymentMethodInfo] = [:]
        for info in list {
            let key = info.name == oldName ? newName : info.name
            let existing = byName[key]
            byName[key] = PaymentMethodInfo(
                name: key,
                isCardless: info.isCardless || (existing?.isCardless ?? false),
                isBankTransfer: info.isBankTransfer || (existing?.isBankTransfer ?? false),
                isCashOnDelivery: info.isCashOnDelivery || (existing?.isCashOnDelivery ?? false)
            )
        }
        return byName.values.sorted { firstInfo, secondInfo in
            firstInfo.name.localizedStandardCompare(secondInfo.name) == .orderedAscending
        }
    }
}
