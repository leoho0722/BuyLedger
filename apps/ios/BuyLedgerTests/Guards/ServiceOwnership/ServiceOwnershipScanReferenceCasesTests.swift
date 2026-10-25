//
//  ServiceOwnershipScanReferenceCasesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

/// 功能專屬服務邊界的單元測試，涵蓋各種 key path 取用形式的片段案例
struct ServiceOwnershipScanReferenceCasesTests {

    /// 驗證各種 key path 寫法的服務引用，跨功能引用回報檔案、行號與鍵值，自己功能、共用服務、App 組合根與註解或字串內的引用都不算違規
    ///
    /// - Parameter testCase: 原始碼片段與字面值違規
    /// - Throws: 掃描沒有適用的服務宣告時丟出 `noServiceDeclarations`
    @Test(arguments: ServiceOwnershipScanReferenceCasesTests.referenceCases)
    func scan_各種服務引用形式_回傳精確檔案行號與鍵值(testCase: ServiceOwnershipModels.ReferenceCase) throws {
        // Given
        let files = ServiceOwnershipFixtures.referenceServices + [testCase.file]

        // When
        let result = try ServiceOwnershipScanner.scan(files: files)

        // Then
        #expect(result.foreignReferences == testCase.expected)
        #expect(result.duplicateDatabaseServices == [])
    }
}

// MARK: - Private Method

private extension ServiceOwnershipScanReferenceCasesTests {

    /// 跨功能、自己功能、共用與非程式碼引用的片段案例
    static var referenceCases: [ServiceOwnershipModels.ReferenceCase] {
        [
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Campaigns/Short.swift",
                    contents: #"@Dependency(\.orderService) var service"#
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Campaigns/Short.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Campaigns/Full.swift",
                    contents: #"@Dependency(\DependencyValues.orderService) var service"#
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Campaigns/Full.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Campaigns/MultilineShort.swift",
                    contents: """
                    @Dependency(
                        \\.orderService
                    ) var service
                    """
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Campaigns/MultilineShort.swift",
                        line: 2,
                        key: "orderService"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
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
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Campaigns/MultilineFull.swift",
                        line: 3,
                        key: "orderService"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Lookups/Own.swift",
                    contents: #"@Dependency(\.lookupService) var service"#
                ),
                expected: []
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Campaigns/Core.swift",
                    contents: #"@Dependency(\DependencyValues.currencyMetadataService) var service"#
                ),
                expected: []
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Orders/SharedApp.swift",
                    contents: #"@Dependency(\.telemetryService) var service"#
                ),
                expected: []
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "App/Testing/Overrides.swift",
                    contents: #"@Dependency(\.orderService) var service"#
                ),
                expected: []
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
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
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/OrdersArchive/Prefix.swift",
                    contents: #"@Dependency(\.orderService) var service"#
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/OrdersArchive/Prefix.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Campaigns/Unicode.swift",
                    contents: """
                    let title = "測試🪙"
                    @Dependency(\\.orderService) var service
                    """
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Campaigns/Unicode.swift",
                        line: 2,
                        key: "orderService"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Campaigns/KeyPath.swift",
                    contents: #"let key = \DependencyValues.orderService"#
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Campaigns/KeyPath.swift",
                        line: 1,
                        key: "orderService"
                    ),
                ]
            ),
        ]
    }
}
