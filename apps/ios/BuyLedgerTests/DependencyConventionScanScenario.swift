//
//  DependencyConventionScanScenario.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 原始碼掃描測試用的輸入片段與預期結果命名空間
enum DependencyConventionScanScenario {}

// MARK: - Nested Types

extension DependencyConventionScanScenario {

    /// 會命中一筆掃描違規的案例
    struct ViolationCase: Sendable {

        /// 顯示在失敗訊息中，辨識這一列案例
        let name: String

        /// 送進掃描器的完整 Swift 原始碼片段
        let source: String

        /// 假設片段所在的相對路徑，決定哪些規則適用
        let relativePath: String

        /// App 正式程式碼或單元測試；決定各規則是否適用
        let sourceTree: DependencyConventionScanTests.SourceTree

        /// 此案例要驗證的掃描規則
        let rules: [DependencyConventionScanTests.ScanRule]

        /// 預期違規所在的 1 起算行號
        let expectedLine: Int

        /// 預期掃描器擷取的原始碼文字
        let expectedReference: String

        /// 預期回報的一句「不得…」或「必須…」規則句，須與掃描器提供的文字逐字相同
        let expectedReason: String
    }

    /// 不應命中掃描違規的案例
    struct PassingCase: Sendable {

        /// 顯示在失敗訊息中，辨識這一列案例
        let name: String

        /// 送進掃描器的完整 Swift 原始碼片段
        let source: String

        /// 假設片段所在的相對路徑，決定哪些規則適用
        let relativePath: String

        /// App 正式程式碼或單元測試；決定各規則是否適用
        let sourceTree: DependencyConventionScanTests.SourceTree

        /// 此案例要驗證的掃描規則
        let rules: [DependencyConventionScanTests.ScanRule]
    }
}

// MARK: - Computed Properties

extension DependencyConventionScanScenario {

    /// 組合五條依賴規則的違規案例，作為 `fragmentViolations_違規案例_回報位置與原因(scenario:)` 的參數
    static var violationCases: [ViolationCase] {
        dependencyViolationCases
            + boundaryViolationCases
            + testValueViolationCases
            + sharedContainerViolationCases
            + appModelContainerViolationCases
    }

    /// 組合五條依賴規則與詞法處理的合規案例，作為 `fragmentViolations_合規案例_不回報違規(scenario:)` 的參數
    static var passingCases: [PassingCase] {
        dependencyPassingCases
            + boundaryPassingCases
            + testValuePassingCases
            + sharedContainerPassingCases
            + appModelContainerPassingCases
            + lexicalPassingCases
    }
}
