//
//  ServiceOwnershipScanLookupCatalogCasesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import Testing

/// 訂單主檔目錄唯讀規則的單元測試，涵蓋各種取得形式的片段案例
struct ServiceOwnershipScanLookupCatalogCasesTests {

    /// 驗證訂單功能以可寫入形式取得主檔目錄時，屬性包裝、建構與型別三種寫法都回報檔案與行號，唯讀、註解與主檔端不算違規
    ///
    /// - Parameter testCase: 原始碼片段與字面值違規
    /// - Throws: 掃描沒有適用的服務宣告時丟出 `noServiceDeclarations`
    @Test(arguments: ServiceOwnershipScanLookupCatalogCasesTests.lookupCatalogCases)
    func scan_訂單功能取得主檔目錄的各種形式_回傳可寫入的檔案與行號(testCase: ServiceOwnershipModels.ReferenceCase) throws {
        // Given
        let files = ServiceOwnershipFixtures.referenceServices + [testCase.file]

        // When
        let result = try ServiceOwnershipScanner.scan(files: files)

        // Then
        #expect(result.writableLookupCatalogs == testCase.expected)
    }
}

// MARK: - Private Method

private extension ServiceOwnershipScanLookupCatalogCasesTests {

    /// 可寫入、唯讀、註解與主檔端的主檔目錄片段案例
    static var lookupCatalogCases: [ServiceOwnershipModels.ReferenceCase] {
        [
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Orders/WritableAttribute.swift",
                    contents: "@Shared(.lookupCatalog) var lookupCatalog: LookupCatalog"
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Orders/WritableAttribute.swift",
                        line: 1,
                        key: "lookupCatalog"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Orders/WritableInit.swift",
                    contents: "let count = 1\nlet catalog = Shared(.lookupCatalog)"
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Orders/WritableInit.swift",
                        line: 2,
                        key: "lookupCatalog"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Orders/WritableType.swift",
                    contents: "var catalog: Shared<LookupCatalog>"
                ),
                expected: [
                    ServiceOwnershipModels.ReferenceViolation(
                        file: "Features/Orders/WritableType.swift",
                        line: 1,
                        key: "lookupCatalog"
                    ),
                ]
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Orders/Reader.swift",
                    contents: "@SharedReader(.lookupCatalog) var lookupCatalog: LookupCatalog"
                ),
                expected: []
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Orders/Comment.swift",
                    contents: "// @Shared(.lookupCatalog) var lookupCatalog: LookupCatalog"
                ),
                expected: []
            ),
            ServiceOwnershipModels.ReferenceCase(
                file: ServiceOwnershipModels.SourceFile(
                    path: "Features/Lookups/Owner.swift",
                    contents: "@Shared(.lookupCatalog) var catalog: LookupCatalog"
                ),
                expected: []
            ),
        ]
    }
}
