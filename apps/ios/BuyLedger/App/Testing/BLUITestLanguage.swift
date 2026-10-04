//
//  BLUITestLanguage.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

#if DEBUG

/// UI 測試要覆寫的 App 內語言
enum BLUITestLanguage: String, CaseIterable, Sendable {

    /// 覆寫 App 內語言為正體中文，供中文介面測試使用
    case traditionalChinese

    /// 覆寫 App 內語言為英文，供英文介面測試使用
    case english
}

#endif
