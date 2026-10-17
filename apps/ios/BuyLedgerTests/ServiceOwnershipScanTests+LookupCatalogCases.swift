//
//  ServiceOwnershipScanTests+LookupCatalogCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import Testing

extension ServiceOwnershipScanTests {

    /// 訂單功能的可寫入主檔目錄以屬性包裝、建構與型別三種形式回報，唯讀、註解與主檔端不算違規
    ///
    /// - Parameter testCase: 原始碼片段與字面值違規
    /// - Throws: 服務宣告收集失敗時拋出錯誤
    @Test(arguments: ServiceOwnershipScanTests.lookupCatalogCases)
    func scan_訂單功能取得主檔目錄的各種形式_回傳可寫入的檔案與行號(testCase: ReferenceCase) throws {
        // Given
        let files = Self.referenceServices + [testCase.file]

        // When
        let result = try Self.scan(files: files)

        // Then
        #expect(result.writableLookupCatalogs == testCase.expected)
    }
}

// MARK: - Private Method

private extension ServiceOwnershipScanTests {

    /// 可寫入、唯讀、註解與主檔端的主檔目錄片段案例
    static var lookupCatalogCases: [ReferenceCase] {
        [
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Orders/WritableAttribute.swift",
                    contents: "@Shared(.lookupCatalog) var lookupCatalog: LookupCatalog"
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Orders/WritableAttribute.swift",
                        line: 1,
                        key: "lookupCatalog"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Orders/WritableInit.swift",
                    contents: "let count = 1\nlet catalog = Shared(.lookupCatalog)"
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Orders/WritableInit.swift",
                        line: 2,
                        key: "lookupCatalog"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Orders/WritableType.swift",
                    contents: "var catalog: Shared<LookupCatalog>"
                ),
                expected: [
                    ReferenceViolation(
                        file: "Features/Orders/WritableType.swift",
                        line: 1,
                        key: "lookupCatalog"
                    ),
                ]
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Orders/Reader.swift",
                    contents: "@SharedReader(.lookupCatalog) var lookupCatalog: LookupCatalog"
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Orders/Comment.swift",
                    contents: "// @Shared(.lookupCatalog) var lookupCatalog: LookupCatalog"
                ),
                expected: []
            ),
            ReferenceCase(
                file: SourceFile(
                    path: "Features/Lookups/Owner.swift",
                    contents: "@Shared(.lookupCatalog) var catalog: LookupCatalog"
                ),
                expected: []
            ),
        ]
    }
}
