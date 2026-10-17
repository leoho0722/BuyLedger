//
//  OptionPickerSheet+Configuration.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

// MARK: - Nested Types

extension OptionPickerSheet {

    /// 選項的選取模式與操作回呼
    enum Selection {

        /// 單選，點選或清除後關閉選擇器
        ///
        /// - Parameters:
        ///   - selected: 目前選項；空字串表示尚未選取
        ///   - onSelect: 點選選項時接收該原始值的回呼
        ///   - clear: 清除選擇的列設定；`nil` 時隱藏
        case single(selected: String, onSelect: (String) -> Void, clear: ClearOption? = nil)

        /// 多選，點選立即切換，以完成鍵結束選取
        ///
        /// - Parameters:
        ///   - selections: 目前已選取的原始值集合
        ///   - onToggle: 點選選項時接收該原始值的回呼
        case multiple(selections: Set<String>, onToggle: (String) -> Void)
    }

    /// 新增項目的輸入方式與送出回呼
    enum Addition {

        /// 以 alert 輸入名稱後新增項目
        ///
        /// - Parameters:
        ///   - addPrompt: 新增按鈕與名稱輸入的文案
        ///   - onAdd: 確認時接收修剪後名稱的回呼
        case prompt(AddPrompt, onAdd: (String) -> Void)

        /// 推入付款方式編輯器，送出後返回選擇器
        ///
        /// - Parameters:
        ///   - addPrompt: 新增按鈕與付款方式編輯器的文案
        ///   - onSubmit: 編輯器送出名稱與付款方式旗標的回呼
        case paymentMethod(AddPrompt, onSubmit: PaymentMethodEditorSheet.SubmitAction)
    }

    /// 新增按鈕與輸入畫面使用的文案
    struct AddPrompt {

        /// 選擇器新增按鈕的標題
        let buttonTitle: String

        /// 輸入畫面的標題
        let title: String

        /// 說明新增項目方式的訊息
        let message: String

        /// 名稱輸入欄的提示文字
        let placeholder: String
    }

    /// 清除目前選擇的列，操作完成後關閉選擇器
    struct ClearOption {

        /// 清除選項列的顯示文字
        let title: String

        /// 點擊清除選項列時執行的回呼
        let onClear: () -> Void
    }

    /// 沒有符合選項時顯示的文案
    struct EmptyState {

        /// 空狀態的標題
        let title: String

        /// 說明沒有選項的原因或後續操作
        let description: String
    }

    /// 選項顯示名稱與搜尋補充文字的轉換方式
    struct Labeling {

        /// 將原始值轉成選項的顯示名稱
        ///
        /// - Parameter option: 選項的原始值
        /// - Returns: 選項的顯示文字
        let displayName: @Sendable (String) -> String

        /// 提供原始值以外的搜尋比對文字
        ///
        /// - Parameter option: 選項的原始值
        /// - Returns: 選項的搜尋補充文字
        let searchKeywords: @Sendable (String) -> String
    }
}
