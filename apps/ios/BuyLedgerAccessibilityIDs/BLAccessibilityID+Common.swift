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

        /// 跨功能共用的未選取或空詳情提示容器識別碼
        static let detailEmptyState = "common.detail.emptyState"

        /// 跨功能共用選取標記所屬之功能範疇
        enum Feature: String, Sendable {

            /// 訂單功能
            case orders

            /// 開團功能
            case campaigns

            /// 更多功能
            case more
        }

        /// 組出各功能共用格式、依功能範疇區分的目前選取項目識別碼
        ///
        /// - Parameter feature: 功能範疇 (如 `.orders`, `.campaigns`, `.more`)
        /// - Returns: 對應功能的選取項目識別碼 (格式：`"common.navigation.selectedItem.<feature>"`)
        /// - Note: 該元素的 `accessibilityValue` 直接反映導覽路徑目前選取的項目識別碼；未選取時為空字串，不另存第二份選取狀態
        static func selectedItem(_ feature: Feature) -> String {
            option("common.navigation.selectedItem", key: feature.rawValue)
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

        /// 組出以原始字串識別的選項列識別碼
        ///
        /// - Parameter option: 選項原始字串
        /// - Returns: 對應選項列的 accessibility identifier
        static func optionRow(_ option: String) -> String {
            row("optionPicker.optionRow", key: option)
        }
    }
}
