//
//  DependencyConventionScanScenario+TestValueCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

// MARK: - Computed Properties

extension DependencyConventionScanScenario {

    /// `testValue` 規則拒絕的 Service 與 Client 案例，供 `violationCases` 跨檔組合使用
    static var testValueViolationCases: [ViolationCase] {
        [
            ViolationCase(
                name: "Service 測試值提供可執行 closure",
                source: """
                static var testValue: Self {
                    Self(
                        fetchCategories: {
                            []
                        }
                    )
                }
                """,
                relativePath: "Core/Dependencies/CategoryService+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 3,
                expectedReference: "fetchCategories: { [] }",
                expectedReason: "CategoryService.fetchCategories 必須以 unimplemented( 開頭"
            ),
            ViolationCase(
                name: "Service 沒有 testValue",
                source: "enum CategoryServiceKey {}",
                relativePath: "Core/Dependencies/CategoryService+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 1,
                expectedReference: "testValue",
                expectedReason: "CategoryService 必須宣告測試值"
            ),
            ViolationCase(
                name: "HTTP client 宣告 testValue",
                source: "static var testValue: HTTPClientProtocol { PreviewHTTPClient() }",
                relativePath: "Core/Networking/HTTPClient+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 1,
                expectedReference: "var testValue",
                expectedReason: "Client、Store 與 Database 的 Dependency 不得宣告 testValue"
            ),
            ViolationCase(
                name: "新增 Client 宣告 testValue",
                source: "static let testValue = KeychainClient()",
                relativePath: "Core/Security/KeychainClient+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 1,
                expectedReference: "let testValue",
                expectedReason: "Client、Store 與 Database 的 Dependency 不得宣告 testValue"
            ),
            ViolationCase(
                name: "Service 第二個引數使用可執行 closure",
                source: """
                static var testValue: Self {
                    Self(
                        fetchCategories: unimplemented(
                            "CategoryService.fetchCategories",
                            placeholder: []
                        ),
                        saveCategory: { _ in }
                    )
                }
                """,
                relativePath: "Core/Dependencies/CategoryService+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 7,
                expectedReference: "saveCategory: { _ in }",
                expectedReason: "CategoryService.saveCategory 必須以 unimplemented( 開頭"
            ),
        ]
    }

    /// `testValue` 規則接受的 Service 與 Client 案例，供 `passingCases` 跨檔組合使用
    static var testValuePassingCases: [PassingCase] {
        [
            PassingCase(
                name: "Service 測試值 closure 全部未實作",
                source: """
                static var testValue: Self {
                    Self(
                        fetchCategories: unimplemented(
                            "CategoryService.fetchCategories",
                            placeholder: []
                        )
                    )
                }
                """,
                relativePath: "Core/Dependencies/CategoryService+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue]
            ),
            PassingCase(
                name: "Client dependency 只提供 live value",
                source: "static var liveValue: any HTTPClientProtocol { HTTPClient() }",
                relativePath: "Core/Networking/HTTPClient+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue]
            ),
        ]
    }
}
