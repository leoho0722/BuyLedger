//
//  DependencyFileScanResult.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 一個檔案命中的適用子規則與依賴規則違規
struct DependencyFileScanResult: Sendable {

    // MARK: - Properties

    /// 此檔案涵蓋的子規則
    let applicableSubrules: [DependencyScanSubrule]

    /// 此檔案命中的違規清單
    let violations: [DependencyScanViolation]
}
