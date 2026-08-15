//
//  LookupKind.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation

/// 表單下拉選單背後的「主檔型別」
enum LookupKind: String, Equatable, Hashable, Sendable {
    
    // MARK: - Cases
    
    /// 訂單來源主檔
    case orderSource
    
    /// 商品類別主檔
    case category
    
    /// 付款方式主檔
    case paymentMethod
    
    /// 對帳狀態主檔
    case reconciliationStatus
    
    // MARK: - Display Properties
    
    /// 管理頁顯示的標題
    var title: String {
        switch self {
        case .orderSource:
            "訂單來源管理"
        case .category:
            "商品類別管理"
        case .paymentMethod:
            "付款方式管理"
        case .reconciliationStatus:
            "對帳狀態管理"
        }
    }
    
    /// 進入點 (MoreView 列表) 顯示的標題
    var entryTitle: String {
        switch self {
        case .orderSource:
            "訂單來源"
        case .category:
            "商品類別"
        case .paymentMethod:
            "付款方式"
        case .reconciliationStatus:
            "對帳狀態"
        }
    }
    
    /// 進入點 (MoreView 列表) 顯示的描述
    var entrySubtitle: String {
        switch self {
        case .orderSource:
            "管理訂單可選的訂單來源清單。"
        case .category:
            "管理訂單可選的商品類別清單。"
        case .paymentMethod:
            "管理訂單可選的付款方式清單。"
        case .reconciliationStatus:
            "管理訂單可選的對帳狀態清單。"
        }
    }
    
    /// 對應的 SF Symbol
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
    
    /// 「新增」按鈕標題
    var addButtonTitle: String {
        switch self {
        case .orderSource:
            "新增來源"
        case .category:
            "新增類別"
        case .paymentMethod:
            "新增付款方式"
        case .reconciliationStatus:
            "新增對帳狀態"
        }
    }
    
    /// 空狀態標題
    var emptyTitle: String {
        switch self {
        case .orderSource:
            "尚無來源"
        case .category:
            "尚無類別"
        case .paymentMethod:
            "尚無付款方式"
        case .reconciliationStatus:
            "尚無對帳狀態"
        }
    }
    
    /// 空狀態描述
    var emptyDescription: String {
        switch self {
        case .orderSource:
            "透過上方「新增來源」加入第一個訂單來源；訂單編輯時也能新增。"
        case .category:
            "透過上方「新增類別」加入第一個類別；訂單編輯時也能新增。"
        case .paymentMethod:
            "透過上方「新增付款方式」加入第一個項目；訂單編輯時也能新增。"
        case .reconciliationStatus:
            "透過上方「新增對帳狀態」加入第一個對帳狀態；訂單編輯時也能新增。"
        }
    }
    
    /// 新增 alert 標題
    var addAlertTitle: String {
        switch self {
        case .orderSource:
            "新增訂單來源"
        case .category:
            "新增商品類別"
        case .paymentMethod:
            "新增付款方式"
        case .reconciliationStatus:
            "新增對帳狀態"
        }
    }
    
    /// 新增 alert 內 TextField 的 placeholder
    var addFieldPlaceholder: String {
        switch self {
        case .orderSource:
            "來源名稱"
        case .category:
            "類別名稱"
        case .paymentMethod:
            "付款方式名稱"
        case .reconciliationStatus:
            "對帳狀態名稱"
        }
    }
    
    /// 新增 alert 的提示文字
    var addAlertMessage: String {
        switch self {
        case .orderSource:
            "輸入新的訂單來源名稱；不會自動套用到任何既有訂單。"
        case .category:
            "輸入新的商品類別名稱；不會自動套用到任何既有訂單。"
        case .paymentMethod:
            "輸入新的付款方式名稱；不會自動套用到任何既有訂單。"
        case .reconciliationStatus:
            "輸入新的對帳狀態名稱；不會自動套用到任何既有訂單。"
        }
    }
}

// MARK: - Order Cascade

extension LookupKind {
    
    /// 訂單是否引用此主檔種類的指定值
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
    
    /// 依此主檔種類的更名規則重建訂單，承載四種主檔的重建差異
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
