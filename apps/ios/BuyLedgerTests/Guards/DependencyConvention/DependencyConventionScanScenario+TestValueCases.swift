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
                extension CategoryService: DependencyKey {
                    static var testValue: Self {
                        Self(
                            fetchCategories: {
                                []
                            }
                        )
                    }
                }
                """,
                relativePath: "Features/Lookups/Data/CategoryService.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 4,
                expectedReference: "fetchCategories: { [] }",
                expectedReason: "CategoryService.fetchCategories 必須以 unimplemented( 開頭"
            ),
            ViolationCase(
                name: "Service 沒有 testValue",
                source: "extension CategoryService: DependencyKey {}",
                relativePath: "Features/Lookups/Data/CategoryService.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 1,
                expectedReference: "testValue",
                expectedReason: "CategoryService 必須宣告測試值"
            ),
            ViolationCase(
                name: "Service 的 +Dependency 檔沒有 testValue",
                source: "extension CategoryService: DependencyKey {}",
                relativePath: "Features/Lookups/Data/CategoryService+Dependency.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 1,
                expectedReference: "testValue",
                expectedReason: "CategoryService 必須宣告測試值"
            ),
            ViolationCase(
                name: "HTTP client 宣告 testValue",
                source: """
                enum HTTPClientKey: DependencyKey {
                    static var testValue: HTTPClientProtocol { PreviewHTTPClient() }
                }
                """,
                relativePath: "Core/Networking/Client/HTTPClient.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 2,
                expectedReference: "var testValue",
                expectedReason: "Client、Store 與 Database 的 Dependency 不得宣告 testValue"
            ),
            ViolationCase(
                name: "新增 Client 宣告 testValue",
                source: """
                enum KeychainClientKey: DependencyKey {
                    static let testValue = KeychainClient()
                }
                """,
                relativePath: "Core/Security/KeychainClient.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 2,
                expectedReference: "let testValue",
                expectedReason: "Client、Store 與 Database 的 Dependency 不得宣告 testValue"
            ),
            ViolationCase(
                name: "Service 第二個引數使用可執行 closure",
                source: """
                extension CategoryService: DependencyKey {
                    static var testValue: Self {
                        Self(
                            fetchCategories: unimplemented(
                                "CategoryService.fetchCategories",
                                placeholder: []
                            ),
                            saveCategory: { _ in }
                        )
                    }
                }
                """,
                relativePath: "Features/Lookups/Data/CategoryService.swift",
                sourceTree: .production,
                rules: [.testValue],
                expectedLine: 8,
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
                extension CategoryService: DependencyKey {
                    static var testValue: Self {
                        Self(
                            fetchCategories: unimplemented(
                                "CategoryService.fetchCategories",
                                placeholder: []
                            )
                        )
                    }
                }
                """,
                relativePath: "Features/Lookups/Data/CategoryService.swift",
                sourceTree: .production,
                rules: [.testValue]
            ),
            PassingCase(
                name: "Client dependency 只提供 live value",
                source: """
                enum HTTPClientKey: DependencyKey {
                    static var liveValue: any HTTPClientProtocol { HTTPClient() }
                }
                """,
                relativePath: "Core/Networking/Client/HTTPClient.swift",
                sourceTree: .production,
                rules: [.testValue]
            ),
            PassingCase(
                name: "未宣告 DependencyKey 的 Service 檔不套用測試值規則",
                source: "extension CategoryService { static func fetchAll() -> [String] { [] } }",
                relativePath: "Features/Lookups/Data/CategoryService+Reads.swift",
                sourceTree: .production,
                rules: [.testValue]
            ),
        ]
    }
}
