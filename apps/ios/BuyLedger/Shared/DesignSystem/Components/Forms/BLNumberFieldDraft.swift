//
//  BLNumberFieldDraft.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/6.
//

import Foundation

/// 數字欄位的純編輯狀態，決定草稿文字與需要寫回的金額
struct BLNumberFieldDraft: Sendable {

    // MARK: - Properties

    /// 這一輪取得焦點時的金額，全部刪除時用來還原
    private var focusedValue: Decimal

    /// 這一輪聚焦是否曾完成金額寫回
    private var hasWrittenValue = false

    /// 草稿目前是否正在編輯，避免同一輪聚焦被重複清空
    private var isFocused = false

    /// 最後一次初始化、同步或寫回後讀到的金額
    private var lastReadValue: Decimal

    /// 使用者正在編輯的原文，失焦時才重新套用格式
    private(set) var text: String

    // MARK: - Init

    /// 依目前金額建立草稿，初次顯示不等待畫面事件
    ///
    /// - Parameters:
    ///   - value: 呼叫端目前持有的金額
    ///   - format: 顯示金額的格式
    init(value: Decimal, format: Decimal.FormatStyle) {
        focusedValue = value
        lastReadValue = value
        text = format.format(value)
    }
}

// MARK: - Internal Method

extension BLNumberFieldDraft {

    /// 依焦點變化清空或還原草稿，兩者都不要求寫回
    ///
    /// - Parameters:
    ///   - isFocused: 此欄位是否取得焦點
    ///   - value: 焦點變動當下的綁定金額
    ///   - format: 失焦時顯示金額的格式
    /// - Note: 欄位重建後可能沒收到聚焦通知，所以只排除重複的聚焦，失焦一律依格式顯示
    mutating func setFocused(_ isFocused: Bool, value: Decimal, format: Decimal.FormatStyle) {
        guard !(isFocused && self.isFocused) else {
            return
        }
        self.isFocused = isFocused
        hasWrittenValue = false
        lastReadValue = value
        if isFocused {
            focusedValue = value
            text = ""
        } else {
            text = format.format(value)
        }
    }

    /// 保留使用者輸入原文，解析成功或需要還原時才提出寫回金額
    ///
    /// - Parameters:
    ///   - newText: 使用者改動後的草稿
    ///   - format: 解析金額的原有格式
    /// - Returns: 解析後的金額或聚焦快照，沒有改動、解析失敗或不需還原時為缺值
    mutating func updateText(_ newText: String, format: Decimal.FormatStyle) -> Decimal? {
        guard text != newText else {
            return nil
        }
        text = newText
        if newText.isEmpty {
            return hasWrittenValue ? focusedValue : nil
        }
        do {
            return try format.parseStrategy.parse(newText)
        } catch {
            return nil
        }
    }

    /// 記住寫回後實際讀到的金額，避免把呼叫端捨入或上限誤認為外部修改
    ///
    /// - Parameter value: 呼叫端完成寫回後讀回的金額
    mutating func recordWrittenValue(_ value: Decimal) {
        hasWrittenValue = true
        lastReadValue = value
    }

    /// 比對外部金額與最後讀回值，不同時以外部金額重設顯示，保留本輪聚焦快照與寫回紀錄
    ///
    /// - Parameters:
    ///   - value: 呼叫端目前持有的金額
    ///   - format: 顯示外部金額的原有格式
    /// - Returns: 已以外部金額重設草稿時為真，相同金額不重設
    @discardableResult
    mutating func synchronizeValue(_ value: Decimal, format: Decimal.FormatStyle) -> Bool {
        guard value != lastReadValue else {
            return false
        }
        lastReadValue = value
        text = format.format(value)
        return true
    }
}
