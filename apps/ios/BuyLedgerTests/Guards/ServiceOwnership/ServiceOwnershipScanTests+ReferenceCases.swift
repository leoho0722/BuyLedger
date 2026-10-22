//
//  ServiceOwnershipScanTests+ReferenceCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

extension ServiceOwnershipScanTests {

    /// 以縮寫、完整與跨行 key path 驗證引用邊界，非程式碼文字不算引用
    ///
    /// - Parameter testCase: 原始碼片段與字面值違規
    /// - Throws: 服務宣告收集失敗時拋出錯誤
    @Test(arguments: ServiceOwnershipScanTests.referenceCases)
    func scan_各種服務引用形式_回傳精確檔案行號與鍵值(testCase: ReferenceCase) throws {
        // Given
        let files = Self.referenceServices + [testCase.file]

        // When
        let result = try Self.scan(files: files)

        // Then
        #expect(result.foreignReferences == testCase.expected)
        #expect(result.duplicateDatabaseServices == [])
    }
}

// MARK: - Private Method

private extension ServiceOwnershipScanTests {

    /// 跨功能、自己功能、共用與非程式碼引用的片段案例
    static var referenceCases: [ReferenceCase] {
        [
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/Short.swift",
                    contents: #"@Dependency(\.orderService) var service"#
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Campaigns/Short.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/Full.swift",
                    contents: #"@Dependency(\DependencyValues.orderService) var service"#
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Campaigns/Full.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/MultilineShort.swift",
                    contents: """
                    @Dependency(
                        \\.orderService
                    ) var service
                    """
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Campaigns/MultilineShort.swift",
                        line: 2,
                        key: "orderService"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/MultilineFull.swift",
                    contents: """
                    struct Example {
                        @Dependency(
                            \\DependencyValues.orderService
                        ) var service
                    }
                    """
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Campaigns/MultilineFull.swift",
                        line: 3,
                        key: "orderService"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Lookups/Own.swift",
                    contents: #"@Dependency(\.lookupService) var service"#
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/Core.swift",
                    contents: #"@Dependency(\DependencyValues.currencyMetadataService) var service"#
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Orders/SharedApp.swift",
                    contents: #"@Dependency(\.telemetryService) var service"#
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "App/Testing/Overrides.swift",
                    contents: #"@Dependency(\.orderService) var service"#
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/NonCode.swift",
                    contents: #"""
                    // @Dependency(\.orderService) var service
                    /* @Dependency(\DependencyValues.orderService) var service */
                    let normal = "@Dependency(\\.orderService)"
                    let raw = #"@Dependency(\DependencyValues.orderService)"#
                    let multiline = """
                    @Dependency(\\.orderService)
                    """
                    """#
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/OrdersArchive/Prefix.swift",
                    contents: #"@Dependency(\.orderService) var service"#
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/OrdersArchive/Prefix.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/Unicode.swift",
                    contents: """
                    let title = "測試🪙"
                    @Dependency(\\.orderService) var service
                    """
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Campaigns/Unicode.swift",
                        line: 2,
                        key: "orderService"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Campaigns/KeyPath.swift",
                    contents: #"let key = \DependencyValues.orderService"#
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Campaigns/KeyPath.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
        ]
    }
}
