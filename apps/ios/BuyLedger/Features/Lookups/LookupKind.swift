//
//  LookupKind.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation

/// 訂單與管理畫面共用的四種主檔種類
enum LookupKind: String, CaseIterable, Sendable {

    /// 訂單使用的來源主檔
    case orderSource

    /// 訂單使用的商品分類主檔
    case category

    /// 訂單使用的付款方式主檔
    case paymentMethod

    /// 訂單使用的對帳狀態主檔
    case reconciliationStatus
}

// MARK: - Computed Properties

extension LookupKind {

    /// 主檔管理頁的導覽標題
    var title: String {
        switch self {
        case .orderSource:
            "orders.lookup.label.orderSources"

        case .category:
            "orders.lookup.label.itemCategories"

        case .paymentMethod:
            "orders.detail.label.paymentMethods"

        case .reconciliationStatus:
            "orders.lookup.label.reconciliationStatuses"
        }
    }

    /// 更多頁主檔入口的標題
    var entryTitle: String {
        switch self {
        case .orderSource:
            "orders.detail.label.orderSource"

        case .category:
            "orders.list.label.itemCategory"

        case .paymentMethod:
            "orders.list.label.paymentMethod"

        case .reconciliationStatus:
            "orders.edit.label.reconciliationStatus"
        }
    }

    /// 更多頁主檔入口的說明文字
    var entrySubtitle: String {
        switch self {
        case .orderSource:
            "orders.lookup.message.manageOrderSources"

        case .category:
            "orders.lookup.message.manageItemCategories"

        case .paymentMethod:
            "orders.lookup.message.managePaymentMethods"

        case .reconciliationStatus:
            "orders.lookup.message.manageReconciliationStatuses"
        }
    }

    /// 更多頁主檔入口使用的 SF Symbol 名稱
    var systemImage: String {
        switch self {
        case .orderSource:
            "bag"

        case .category:
            "tag"

        case .paymentMethod:
            "creditcard"

        case .reconciliationStatus:
            "checkmark.seal"
        }
    }

    /// 管理頁新增按鈕的標題
    var addButtonTitle: String {
        switch self {
        case .orderSource:
            "orders.edit.label.addSource"

        case .category:
            "orders.edit.label.addCategory"

        case .paymentMethod:
            "orders.edit.label.addPaymentMethod"

        case .reconciliationStatus:
            "orders.edit.label.addStatus"
        }
    }

    /// 主檔清單空白時顯示的標題
    var emptyTitle: String {
        switch self {
        case .orderSource:
            "orders.edit.label.sources"

        case .category:
            "orders.edit.label.categories"

        case .paymentMethod:
            "orders.edit.label.paymentMethods"

        case .reconciliationStatus:
            "orders.edit.label.reconciliationStatuses"
        }
    }

    /// 主檔清單空白時顯示的操作說明
    var emptyDescription: String {
        switch self {
        case .orderSource:
            "orders.lookup.message.useAddSource"

        case .category:
            "orders.lookup.message.useAddCategory"

        case .paymentMethod:
            "orders.lookup.message.useAddPayment"

        case .reconciliationStatus:
            "orders.lookup.message.useAddReconciliation"
        }
    }

    /// 新增主檔表單的標題
    var addFormTitle: String {
        switch self {
        case .orderSource:
            "orders.edit.label.addOrderSource"

        case .category:
            "orders.edit.label.addItemCategory"

        case .paymentMethod:
            "orders.edit.label.addPaymentMethod"

        case .reconciliationStatus:
            "orders.edit.label.addStatus"
        }
    }

    /// 新增主檔表單的補充說明
    var addFormMessage: String {
        switch self {
        case .orderSource:
            "orders.lookup.message.enterNewOrder"

        case .category:
            "orders.lookup.message.enterNewItem"

        case .paymentMethod:
            "orders.lookup.message.enterNewPayment"

        case .reconciliationStatus:
            "orders.lookup.message.enterNewReconciliation"
        }
    }

    /// 新增、改名與編輯表單中名稱欄位的提示文字
    var nameFieldPlaceholder: String {
        switch self {
        case .orderSource:
            "orders.edit.label.sourceName"

        case .category:
            "orders.edit.label.categoryName"

        case .paymentMethod:
            "orders.detail.label.paymentMethodName"

        case .reconciliationStatus:
            "orders.edit.label.reconciliationStatusName"
        }
    }
}

// MARK: - Internal Method

extension LookupKind {

    /// 訂單是否引用此主檔種類的指定值
    ///
    /// - Parameters:
    ///   - order: 要檢查的訂單
    ///   - name: 要比對的主檔值
    /// - Returns: 該訂單是否引用此值
    func isReferenced(by order: LedgerOrder, name: String) -> Bool {
        switch self {
        case .orderSource:
            order.orderSource == name

        case .category:
            order.categories.contains(name)

        case .paymentMethod:
            order.paymentMethod == name

        case .reconciliationStatus:
            order.reconciliationStatus == name
        }
    }

    /// 依此主檔種類的規則重建訂單
    ///
    /// - Parameters:
    ///   - order: 要重建的訂單
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Returns: 套用更名後的訂單
    func renamingReference(
        in order: LedgerOrder,
        from oldName: String,
        to newName: String
    ) -> LedgerOrder {
        switch self {
        case .orderSource:
            order.renamingOrderSource(to: newName)

        case .category:
            order.renamingCategory(from: oldName, to: newName)

        case .paymentMethod:
            order.renamingPaymentMethod(to: newName)

        case .reconciliationStatus:
            order.renamingReconciliationStatus(to: newName)
        }
    }
}
