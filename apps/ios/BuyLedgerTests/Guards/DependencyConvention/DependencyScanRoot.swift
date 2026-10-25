//
//  DependencyScanRoot.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

/// 依賴規範掃描器要列舉的根目錄與來源類型
struct DependencyScanRoot: Sendable {

    // MARK: - Properties

    /// 要遞迴列舉的檔案系統位置
    let url: URL

    /// 根目錄屬於 App 正式程式碼或單元測試的來源類型，決定各規則是否適用
    let sourceTree: DependencySourceTree
}
