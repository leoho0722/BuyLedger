//
//  BLAccessibilityID+Common.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension BLAccessibilityID {

    /// 跨畫面共用的元件
    enum Common {

        /// 鍵盤工具列的完成按鈕
        static let keyboardDoneButton = "common.keyboard.doneButton"

        /// 系統導覽返回按鈕
        static let backButton = "BackButton"

        /// 載入中容器
        ///
        /// - Parameter feature: 功能名稱
        /// - Returns: 載入中容器的 accessibility identifier
        static func loading(_ feature: String) -> String {
            option(feature, key: "loading")
        }

        /// 載入失敗容器
        ///
        /// - Parameter feature: 功能名稱
        /// - Returns: 載入失敗容器的 accessibility identifier
        static func loadFailure(_ feature: String) -> String {
            option(feature, key: "loadFailure")
        }

        /// 載入失敗容器的重試
        ///
        /// - Parameter feature: 功能名稱
        /// - Returns: 載入失敗重試按鈕的 accessibility identifier
        static func loadFailureRetryButton(_ feature: String) -> String {
            option(feature, key: "loadFailure") + ".retryButton"
        }
    }

    /// 單選／多選選項選擇器 (設定、訂單編輯、匯率、報價共用同一個元件)
    enum OptionPicker {

        /// 選項選擇器的根 accessibility identifier
        static let root = "optionPicker.root"

        /// 新增選項按鈕
        static let addButton = "optionPicker.addButton"

        /// 新增選項提示框的名稱輸入欄位
        static let addAlertNameField = "optionPicker.addAlert.nameField"

        /// 新增選項提示框的確認按鈕
        static let addAlertConfirmButton = "optionPicker.addAlert.confirmButton"

        /// 新增選項提示框的取消按鈕
        static let addAlertCancelButton = "optionPicker.addAlert.cancelButton"

        /// 完成選項選擇按鈕
        static let doneButton = "optionPicker.doneButton"

        /// 選項列，以原始字串識別
        ///
        /// - Parameter option: 選項原始字串
        /// - Returns: 對應選項列的 accessibility identifier
        static func optionRow(_ option: String) -> String {
            row("optionPicker.optionRow", key: option)
        }
    }
}
