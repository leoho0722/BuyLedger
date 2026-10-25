//
//  DependencyConventionScanScenario.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 依賴規範掃描測試的違規與合規案例彙總，各規則的案例由各自的案例集合型別提供
enum DependencyConventionScanScenario {}

// MARK: - Computed Properties

extension DependencyConventionScanScenario {

    /// 組合六條依賴規則的違規案例，作為 `fragmentViolations_違規案例_回報位置與原因(scenario:)` 的參數
    static var violationCases: [DependencyScanViolationCase] {
        DependencyConventionDependencyCases.dependencyViolationCases
            + DependencyConventionBoundaryCases.boundaryViolationCases
            + DependencyConventionTestValueCases.testValueViolationCases
            + DependencyConventionSharedCases.sharedContainerViolationCases
            + DependencyConventionSharedCases.appModelContainerViolationCases
            + DependencyConventionViewCases.viewViolationCases
    }

    /// 組合六條依賴規則與詞法處理的合規案例，作為 `fragmentViolations_合規案例_不回報違規(scenario:)` 的參數
    static var passingCases: [DependencyScanPassingCase] {
        DependencyConventionDependencyCases.dependencyPassingCases
            + DependencyConventionBoundaryCases.boundaryPassingCases
            + DependencyConventionTestValueCases.testValuePassingCases
            + DependencyConventionSharedCases.sharedContainerPassingCases
            + DependencyConventionSharedCases.appModelContainerPassingCases
            + DependencyConventionViewCases.viewPassingCases
            + DependencyConventionLexicalCases.lexicalPassingCases
    }
}
