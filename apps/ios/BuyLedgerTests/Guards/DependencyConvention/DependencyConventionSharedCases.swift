//
//  DependencyConventionSharedCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

/// `PersistenceContainer.shared` 與 App target SwiftData container 規則的違規與合規案例
enum DependencyConventionSharedCases {}

// MARK: - Computed Properties

extension DependencyConventionSharedCases {

    /// `PersistenceContainer.shared` 規則拒絕的引用與宣告，由 `DependencyConventionScanScenario` 彙總
    static var sharedContainerViolationCases: [DependencyScanViolationCase] {
        [
            DependencyScanViolationCase(
                name: "正式程式碼讀取共用容器",
                source: "PersistenceContainer.shared",
                relativePath: "Core/Persistence/Database/PersistenceContainer.swift",
                sourceTree: .production,
                rules: [.sharedContainer],
                expectedLine: 1,
                expectedReference: "PersistenceContainer.shared",
                expectedReason: "不得讀取 PersistenceContainer.shared"
            ),
            DependencyScanViolationCase(
                name: "單元測試也不得引用共用容器",
                source: "PersistenceContainer.shared",
                relativePath: "PersistenceRecoveryTests.swift",
                sourceTree: .unitTests,
                rules: [.sharedContainer],
                expectedLine: 1,
                expectedReference: "PersistenceContainer.shared",
                expectedReason: "不得讀取 PersistenceContainer.shared"
            ),
            DependencyScanViolationCase(
                name: "正式程式碼宣告共用靜態屬性",
                source: "static let shared = UIApplication.shared",
                relativePath: "App/SharedValue.swift",
                sourceTree: .production,
                rules: [.sharedContainer],
                expectedLine: 1,
                expectedReference: "static let shared",
                expectedReason: "App 程式碼不得宣告 shared 靜態屬性"
            ),
        ]
    }

    /// `PersistenceContainer.shared` 規則允許的系統 API 與範圍外宣告，由 `DependencyConventionScanScenario` 彙總
    static var sharedContainerPassingCases: [DependencyScanPassingCase] {
        [
            DependencyScanPassingCase(
                name: "UIApplication shared 是系統 API",
                source: "UIApplication.shared.open(url)",
                relativePath: "App/OpenURL.swift",
                sourceTree: .production,
                rules: [.sharedContainer]
            ),
            DependencyScanPassingCase(
                name: "測試程式碼可宣告自己的 shared",
                source: "static let shared = TestStore()",
                relativePath: "Mocks/SharedMock.swift",
                sourceTree: .unitTests,
                rules: [.sharedContainer]
            ),
        ]
    }

    /// App target 的 SwiftData container 規則拒絕的掛載呼叫
    static var appModelContainerViolationCases: [DependencyScanViolationCase] {
        [
            DependencyScanViolationCase(
                name: "App View 附掛 SwiftData container",
                source: "RootView().modelContainer(container)",
                relativePath: "Features/App/Presentation/Root/RootView.swift",
                sourceTree: .production,
                rules: [.appModelContainer],
                expectedLine: 1,
                expectedReference: ".modelContainer(",
                expectedReason: "App target 不得出現 `.modelContainer(`"
            ),
        ]
    }

    /// App target 的 SwiftData container 規則應接受的案例，包含字串與註解內的規則文字
    static var appModelContainerPassingCases: [DependencyScanPassingCase] {
        [
            DependencyScanPassingCase(
                name: "字串與註解內提及 SwiftData container",
                source: #"let example = ".modelContainer("; // .modelContainer("#,
                relativePath: "Features/App/Presentation/Root/RootView.swift",
                sourceTree: .production,
                rules: [.appModelContainer]
            ),
        ]
    }
}
