//
//  XCUIElement+CombinedText.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 合併朗讀文字

extension XCUIElement {

    /// 合併朗讀後承載的完整文字 (`label` 串接 `value`)
    var combinedText: String {
        let valueText = (value as? String) ?? ""
        return [label, valueText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
