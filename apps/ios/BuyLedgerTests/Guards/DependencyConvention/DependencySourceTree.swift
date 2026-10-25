//
//  DependencySourceTree.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// App 正式程式碼或單元測試；決定各依賴規則是否適用
enum DependencySourceTree: Sendable {

    /// App 正式程式碼
    case production

    /// App 單元測試程式碼
    case unitTests
}
