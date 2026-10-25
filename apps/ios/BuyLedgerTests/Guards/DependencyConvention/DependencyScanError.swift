//
//  DependencyScanError.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 依賴規範掃描根目錄或整理相對路徑時可能發生的錯誤
enum DependencyScanError: Error {

    /// 根目錄不存在或不是可列舉的目錄
    ///
    /// - Parameter path: 無法列舉的根目錄路徑
    case sourceRootNotFound(path: String)

    /// 規則未找到任何適用的 Swift 檔案
    ///
    /// - Parameter rule: 沒有找到適用檔案的掃描規則
    case noApplicableSourceFiles(rule: DependencyScanRule)

    /// 某條規則的子規則未找到適用的 Swift 檔案
    ///
    /// - Parameters:
    ///   - rule: 子規則所屬的掃描規則
    ///   - subrule: 沒有找到適用檔案的規則子範圍
    case noApplicableSubruleFiles(rule: DependencyScanRule, subrule: DependencyScanSubrule)

    /// 被掃描檔案不在指定根目錄之下
    ///
    /// - Parameter path: 超出根目錄範圍的檔案路徑
    case sourceFileOutsideRoot(path: String)
}
