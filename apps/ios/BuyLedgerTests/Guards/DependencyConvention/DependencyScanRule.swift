//
//  DependencyScanRule.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 依賴規範掃描器提供的規則
enum DependencyScanRule: CaseIterable, Sendable {

    /// 禁止以型別下標存取依賴
    case dependencyTypeSubscript

    /// 限制 Feature 與 Service 的依賴邊界
    case featureBoundary

    /// 限制 Service 與其他依賴的測試值
    case testValue

    /// 禁止讀取 `PersistenceContainer.shared`；App 也不得宣告 `shared` 靜態屬性
    case sharedContainer

    /// 禁止 App target 附掛 SwiftData model container
    case appModelContainer

    /// 遵循 `View` 的型別不得宣告 `@Dependency`，production 程式碼不得讀取裝置曆法
    case viewDependency
}
