//
//  LookupKind.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation

/// 表單下拉選單背後的「主檔型別」。
///
/// 把商品類別與付款方式抽成同一個 ``LookupManagementFeature`` 處理，差異透過此 enum 注入：標題、空狀態文案、寫入哪個 repository。
enum LookupKind: String, Equatable, Sendable {

    // MARK: - Cases

    /// 商品類別主檔。
    case category

    /// 付款方式主檔。
    case paymentMethod

    // MARK: - Display Properties

    /// 管理頁顯示的標題。
    var title: String {
        switch self {
        case .category:
            "商品類別管理"
        case .paymentMethod:
            "付款方式管理"
        }
    }

    /// 進入點 (MoreView 列表) 顯示的標題。
    var entryTitle: String {
        switch self {
        case .category:
            "商品類別"
        case .paymentMethod:
            "付款方式"
        }
    }

    /// 進入點 (MoreView 列表) 顯示的描述。
    var entrySubtitle: String {
        switch self {
        case .category:
            "管理訂單可選的商品類別清單。"
        case .paymentMethod:
            "管理訂單可選的付款方式清單。"
        }
    }

    /// 對應的 SF Symbol。
    var systemImage: String {
        switch self {
        case .category:
            "tag"
        case .paymentMethod:
            "creditcard"
        }
    }

    /// 「新增」按鈕標題。
    var addButtonTitle: String {
        switch self {
        case .category:
            "新增類別"
        case .paymentMethod:
            "新增付款方式"
        }
    }

    /// 空狀態標題。
    var emptyTitle: String {
        switch self {
        case .category:
            "尚無類別"
        case .paymentMethod:
            "尚無付款方式"
        }
    }

    /// 空狀態描述。
    var emptyDescription: String {
        switch self {
        case .category:
            "透過上方「新增類別」加入第一個類別；訂單編輯時也能新增。"
        case .paymentMethod:
            "透過上方「新增付款方式」加入第一個項目；訂單編輯時也能新增。"
        }
    }

    /// 新增 alert 標題。
    var addAlertTitle: String {
        switch self {
        case .category:
            "新增商品類別"
        case .paymentMethod:
            "新增付款方式"
        }
    }

    /// 新增 alert 內 TextField 的 placeholder。
    var addFieldPlaceholder: String {
        switch self {
        case .category:
            "類別名稱"
        case .paymentMethod:
            "付款方式名稱"
        }
    }

    /// 新增 alert 的提示文字。
    var addAlertMessage: String {
        switch self {
        case .category:
            "輸入新的商品類別名稱；不會自動套用到任何既有訂單。"
        case .paymentMethod:
            "輸入新的付款方式名稱；不會自動套用到任何既有訂單。"
        }
    }
}
