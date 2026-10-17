//
//  SharedKey+CurrencyCodes.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture

// MARK: - Computed Properties

/// App 啟動時載入的幣別共用鍵值
extension SharedKey where Self == InMemoryKey<[CurrencyCode]>.Default {

    /// 只存在記憶體的幣別清單，首次使用時為空陣列
    static var currencyCodes: Self {
        Self[.inMemory("currencyCodes"), default: []]
    }
}
