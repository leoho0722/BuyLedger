//
//  DependencyScanViolationCase.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 會命中一筆依賴規範掃描違規的案例
struct DependencyScanViolationCase: Sendable {

    // MARK: - Properties

    /// 失敗訊息中用來辨識此案例的名稱
    let name: String

    /// 送進掃描器的完整 Swift 原始碼片段
    let source: String

    /// 假設片段所在的相對路徑，決定哪些規則適用
    let relativePath: String

    /// App 正式程式碼或單元測試；決定各規則是否適用
    let sourceTree: DependencySourceTree

    /// 此案例要驗證的掃描規則
    let rules: [DependencyScanRule]

    /// 預期違規所在的 1 起算行號
    let expectedLine: Int

    /// 預期掃描器擷取的原始碼文字
    let expectedReference: String

    /// 預期回報的一句「不得…」或「必須…」規則句，須與掃描器提供的文字逐字相同
    let expectedReason: String
}
