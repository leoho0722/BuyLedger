//
//  BLAccessibilityID+More.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension BLAccessibilityID {

    /// 更多分頁
    enum More {

        /// 更多分頁的根 accessibility identifier
        static let root = "more.root"

        /// 更多分頁各列的目的地 key
        enum Row: String {

            /// 匯率工具
            case fx

            /// 客戶名單
            case customers

            /// 報價試算
            case quote

            /// 訂單來源主檔
            case orderSources

            /// 商品類別主檔
            case categories

            /// 付款方式主檔
            case paymentMethods

            /// 對帳狀態主檔
            case reconciliationStatuses

            /// 設定頁
            case settings
        }

        /// 導向各工具與設定的列 (以目的地 key 指定)
        ///
        /// - Parameter row: 更多分頁目的地
        /// - Returns: 對應目的地列的 accessibility identifier
        static func row(_ row: Row) -> String {
            option("more.row", key: row.rawValue)
        }
    }

    /// 客戶名單
    enum Customers {

        /// 客戶清單的根 accessibility identifier
        static let listRoot = "customers.list.root"

        /// 客戶清單無資料狀態容器
        static let listEmptyState = "customers.list.emptyState"

        /// Top 3 卡片，key 取客戶名
        ///
        /// - Parameter customerName: 客戶名稱
        /// - Returns: 對應 Top 卡片的 accessibility identifier
        static func topCard(customerName: String) -> String {
            BLAccessibilityID.row("customers.topCard", key: customerName)
        }

        /// 全部客戶列，key 取客戶名
        ///
        /// - Parameter customerName: 客戶名稱
        /// - Returns: 對應客戶列的 accessibility identifier
        static func row(customerName: String) -> String {
            BLAccessibilityID.row("customers.list.row", key: customerName)
        }
    }

    /// 匯率工具
    enum Fx {

        /// 匯率工具的根 accessibility identifier
        static let root = "fx.root"

        /// 匯率查詢狀態橫幅
        static let statusBanner = "fx.statusBanner"

        /// 幣別選擇按鈕
        static let currencyPickerButton = "fx.currencyPickerButton"

        /// 金額輸入欄位
        static let amountField = "fx.amountField"

        /// 換算後金額
        static let convertedValue = "fx.convertedValue"
    }

    /// 報價試算
    enum Quote {

        /// 報價試算頁的根 accessibility identifier
        static let root = "quote.root"

        /// 幣別選擇按鈕
        static let currencyPickerButton = "quote.currencyPickerButton"

        /// 本金輸入欄位
        static let principalField = "quote.principalField"

        /// 建議售價
        static let suggestedPriceValue = "quote.suggestedPriceValue"

        /// 報價試算狀態橫幅
        static let statusBanner = "quote.statusBanner"

        /// 報價試算重新載入按鈕
        static let retryButton = "quote.retryButton"
    }

    /// 設定頁
    enum Settings {

        /// 設定頁的根 accessibility identifier
        static let root = "settings.root"

        /// 語言選擇器
        static let languagePicker = "settings.languagePicker"

        /// 預設幣別選擇列
        static let defaultCurrencyRow = "settings.defaultCurrencyRow"

        /// 每月目標金額欄位
        static let monthlyGoalField = "settings.monthlyGoalField"

        /// AI 摘要功能切換鈕
        static let aiSummaryToggle = "settings.aiSummaryToggle"

        /// AI 摘要模型選擇列
        static let aiSummaryModelRow = "settings.aiSummaryModelRow"

        /// 帳本鎖定功能切換鈕
        static let appLockToggle = "settings.appLockToggle"

        /// App 版本列
        static let versionRow = "settings.versionRow"

        /// 語言選項
        ///
        /// - Parameter key: 語言選項識別值
        /// - Returns: 對應語言選項的 accessibility identifier
        static func languageOption(_ key: String) -> String {
            option("settings.languageOption", key: key)
        }
    }

    /// 主檔管理頁面與付款方式編輯表單
    enum LookupManagement {

        /// 主檔管理頁面的根 accessibility identifier
        static let root = "lookupManagement.root"

        /// 新增主檔項目的按鈕
        static let addButton = "lookupManagement.addButton"

        /// 單欄名稱表單的輸入欄位
        static let nameField = "lookupManagement.nameField"

        /// 單欄名稱表單的送出按鈕
        static let nameSubmitButton = "lookupManagement.nameSubmitButton"

        /// 主檔管理頁的載入失敗文字
        static let loadFailureMessage = "lookupManagement.loadFailureMessage"

        /// 付款方式名稱輸入欄位
        static let paymentMethodNameField = "lookupManagement.paymentMethodEditor.nameField"

        /// 付款方式編輯表單的捲動容器
        static let paymentMethodEditorRoot = "lookupManagement.paymentMethodEditor.root"

        /// 付款方式貨到付款旗標
        static let paymentMethodCashOnDeliveryToggle = "lookupManagement.paymentMethodEditor.cashOnDeliveryToggle"

        /// 付款方式編輯表單儲存按鈕
        static let paymentMethodSaveButton = "lookupManagement.paymentMethodEditor.saveButton"

        /// 刪除主檔項目的按鈕，以項目名稱識別
        ///
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 對應刪除按鈕的 accessibility identifier
        static func deleteButton(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.deleteButton", key: name)
        }

        /// 主檔項目列，以項目名稱識別
        ///
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 主檔項目列的 accessibility identifier
        static func row(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.row", key: name)
        }

        /// 編輯或重新命名操作按鈕，以項目名稱識別
        ///
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 編輯操作按鈕的 accessibility identifier
        static func editButton(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.editButton", key: name)
        }

        /// 其他主檔的重新命名操作按鈕，以項目名稱識別
        ///
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 重新命名操作按鈕的 accessibility identifier
        static func renameButton(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.renameButton", key: name)
        }
    }
}
