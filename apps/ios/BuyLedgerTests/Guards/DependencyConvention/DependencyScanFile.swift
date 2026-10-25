//
//  DependencyScanFile.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 傳給單一依賴規則的 Swift 檔案內容
struct DependencyScanFile: Sendable {

    // MARK: - Properties

    /// 相對於所屬根目錄的路徑
    let relativePath: String

    /// 檔案屬於 App 正式程式碼或單元測試的來源類型，決定各規則是否適用
    let sourceTree: DependencySourceTree

    /// 檔案完整文字，尚未移除註解與字串
    let contents: String
}
