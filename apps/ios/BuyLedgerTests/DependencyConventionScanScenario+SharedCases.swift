//
//  DependencyConventionScanScenario+SharedCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

// MARK: - Computed Properties

extension DependencyConventionScanScenario {

    /// 共用持久化容器規則拒絕的引用與宣告，供 `violationCases` 跨檔組合使用
    static var sharedContainerViolationCases: [ViolationCase] {
        [
            ViolationCase(
                name: "正式程式碼讀取共用容器",
                source: "PersistenceContainer.shared",
                relativePath: "Core/Persistence/PersistenceContainer.swift",
                sourceTree: .production,
                rules: [.sharedContainer],
                expectedLine: 1,
                expectedReference: "PersistenceContainer.shared",
                expectedReason: "不得讀取 PersistenceContainer.shared"
            ),
            ViolationCase(
                name: "單元測試也不得引用共用容器",
                source: "PersistenceContainer.shared",
                relativePath: "PersistenceRecoveryTests.swift",
                sourceTree: .unitTests,
                rules: [.sharedContainer],
                expectedLine: 1,
                expectedReference: "PersistenceContainer.shared",
                expectedReason: "不得讀取 PersistenceContainer.shared"
            ),
            ViolationCase(
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

    /// 共用持久化容器規則允許的系統 API 與範圍外宣告，供 `passingCases` 跨檔組合使用
    static var sharedContainerPassingCases: [PassingCase] {
        [
            PassingCase(
                name: "UIApplication shared 是系統 API",
                source: "UIApplication.shared.open(url)",
                relativePath: "App/OpenURL.swift",
                sourceTree: .production,
                rules: [.sharedContainer]
            ),
            PassingCase(
                name: "測試程式碼可宣告自己的 shared",
                source: "static let shared = TestStore()",
                relativePath: "Mocks/SharedMock.swift",
                sourceTree: .unitTests,
                rules: [.sharedContainer]
            ),
        ]
    }

    /// App target 的 SwiftData container 規則拒絕的掛載呼叫
    static var appModelContainerViolationCases: [ViolationCase] {
        [
            ViolationCase(
                name: "App View 附掛 SwiftData container",
                source: "RootView().modelContainer(container)",
                relativePath: "Features/App/RootView.swift",
                sourceTree: .production,
                rules: [.appModelContainer],
                expectedLine: 1,
                expectedReference: ".modelContainer(",
                expectedReason: "App target 不得出現 `.modelContainer(`"
            ),
        ]
    }

    /// App target 的 SwiftData container 規則允許字串或註解內的規則文字
    static var appModelContainerPassingCases: [PassingCase] {
        [
            PassingCase(
                name: "字串與註解內提及 SwiftData container",
                source: #"let example = ".modelContainer("; // .modelContainer("#,
                relativePath: "Features/App/RootView.swift",
                sourceTree: .production,
                rules: [.appModelContainer]
            ),
        ]
    }
}
