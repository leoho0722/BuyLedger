//
//  AccessibilityIdentifierScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation
import Testing

@testable import BuyLedger

/// `AccessibilityIdentifierScanner` 的單元測試，以合成原始碼證明規則會失敗，並掃描正式原始碼
struct AccessibilityIdentifierScanTests {

    // MARK: - Properties

    /// 共用的正式原始碼掃描結果，失敗一律包成自有錯誤，由每個測試各自回報
    ///
    /// - Note: Swift Testing 每個測試各建一個實例，寫成 `static let` 才能讓正式掃描的測試共用同一次掃描
    private static let productionResult = Result {
        try AccessibilityIdentifierScanTests.scanProduction()
    }.mapError {
        ProductionScanError.scanFailed(underlying: $0)
    }

    /// 合成案例使用的分隔符號，以字面值寫死，`row` 改分隔符號時案例的預期不會跟著漂移
    private let separators = AccessibilityIdentifierScanner.Separators(
        option: ".",
        row: ":",
        indexed: ".index."
    )

    /// 驗證合成違規案例回報的規則集合等於案例宣告的預期集合，證明每條規則都會在對應寫法上失敗
    ///
    /// - Parameter scenario: 一筆含合成原始碼與預期規則集合的違規案例
    /// - Note: 同時違反兩條規則的案例在名稱說明原因，預期集合寫兩條
    @Test(arguments: AccessibilityIdentifierScanCases.violationCases)
    func scan_違規案例_回報的規則集合與案例宣告相同(scenario: AccessibilityIdentifierScanCases.ViolationCase) {
        // Given

        // When
        let result = AccessibilityIdentifierScanner.scan(
            namespaceFiles: scenario.namespaceFiles,
            outsideFiles: scenario.outsideFiles,
            outsideRoots: scenario.outsideRoots,
            systemIdentifierPath: scenario.systemIdentifierPath,
            separators: separators
        )

        // Then
        #expect(
            Set(result.violations.map(\.rule)) == scenario.expectedRules,
            "\(scenario.name) 回報的違規不符：\(AccessibilityIdentifierScanner.describe(result.violations))"
        )
    }

    /// 驗證每條規則都至少有一筆預期集合只含該規則的案例，證明它能單獨失敗
    ///
    /// - Parameter rule: 要確認有單獨案例的規則
    @Test(arguments: AccessibilityIdentifierScanner.Rule.allCases)
    func violationCases_每條規則_至少有一筆只破壞該規則的案例(rule: AccessibilityIdentifierScanner.Rule) {
        // Given
        let scenarios = AccessibilityIdentifierScanCases.violationCases

        // When
        let soleScenarios = scenarios.filter { $0.expectedRules == [rule] }

        // Then
        #expect(!soleScenarios.isEmpty, "規則 \(rule) 沒有只破壞該規則的案例")
    }

    /// 驗證合規案例沒有任何違規
    ///
    /// - Parameter scenario: 一筆合規案例，含 spec 示例表中判為 passes 的列與易誤判的寫法
    @Test(arguments: AccessibilityIdentifierScanCases.compliantCases)
    func scan_合規案例_沒有違規(scenario: AccessibilityIdentifierScanCases.CompliantCase) {
        // Given

        // When
        let result = AccessibilityIdentifierScanner.scan(
            namespaceFiles: scenario.namespaceFiles,
            outsideFiles: scenario.outsideFiles,
            outsideRoots: scenario.outsideRoots,
            systemIdentifierPath: scenario.systemIdentifierPath,
            separators: separators
        )

        // Then
        #expect(
            result.violations.isEmpty,
            "\(scenario.name) 不應有違規：\(AccessibilityIdentifierScanner.describe(result.violations))"
        )
    }

    /// 驗證合規案例掃到的固定值與組出前綴等於案例宣告的字面值，防止掃描器略過整段宣告卻判無違規
    ///
    /// - Parameter scenario: 一筆合規案例，含預期掃到的固定值與前綴清單
    /// - Note: 清單依輸入檔案順序再依宣告順序排列
    @Test(arguments: AccessibilityIdentifierScanCases.compliantCases)
    func scan_合規案例_掃到的固定值與前綴等於案例宣告(scenario: AccessibilityIdentifierScanCases.CompliantCase) {
        // Given

        // When
        let result = AccessibilityIdentifierScanner.scan(
            namespaceFiles: scenario.namespaceFiles,
            outsideFiles: scenario.outsideFiles,
            outsideRoots: scenario.outsideRoots,
            systemIdentifierPath: scenario.systemIdentifierPath,
            separators: separators
        )

        // Then
        #expect(
            result.definitions.fixed.map(\.value) == scenario.expectedFixedValues,
            "\(scenario.name) 掃到的固定值不符"
        )
        #expect(
            result.definitions.prefixes.map(\.value) == scenario.expectedPrefixValues,
            "\(scenario.name) 掃到的組出前綴不符"
        )
    }

    /// 驗證違規描述的格式、1 起算的行號與排序：跨檔輸入順序相反時，仍依相對路徑再依行號排序
    ///
    /// - Note: 三個檔案值相同的固定值，後出現者各自指向排序後的第一處
    @Test
    func describe_跨檔多筆違規_格式行號與排序固定() {
        // Given
        let namespaceFiles = AccessibilityIdentifierScanCases.descriptionNamespaceFiles

        // When
        let result = AccessibilityIdentifierScanner.scan(
            namespaceFiles: namespaceFiles,
            outsideFiles: [],
            outsideRoots: [],
            systemIdentifierPath: nil,
            separators: separators
        )

        // Then
        #expect(
            AccessibilityIdentifierScanner.describe(result.violations) == """
                BLAccessibilityID+Orders.swift:7 Orders.listRootCopy "orders.list.root" 與 BLAccessibilityID+Orders.swift:5 同值
                BLAccessibilityID+Orders.swift:13 Orders.statusChipAll "orders.list.statusChip.all" 落在查詢前綴 orders.list.statusChip. 之下
                BLAccessibilityID+OrdersDetail.swift:5 Orders.listRootAgain "orders.list.root" 與 BLAccessibilityID+Orders.swift:5 同值
                """
        )
    }

    /// 驗證根層組字串函式重載時，兩處宣告都被點名，並依檔案路徑排序
    @Test
    func describe_根層組字串函式跨檔重載_完整描述同時點名兩處宣告() {
        // Given
        let namespaceFiles = AccessibilityIdentifierScanCases.overloadedComposerNamespaceFiles

        // When
        let result = AccessibilityIdentifierScanner.scan(
            namespaceFiles: namespaceFiles,
            outsideFiles: [],
            outsideRoots: [],
            systemIdentifierPath: nil,
            separators: separators
        )

        // Then
        #expect(
            AccessibilityIdentifierScanner.describe(result.violations) == """
                BLAccessibilityID+Builders.swift:3 BLAccessibilityID.option "" 宣告不在接受的定義形式內
                BLAccessibilityID.swift:3 BLAccessibilityID.option "" 宣告不在接受的定義形式內
                """
        )
    }

    /// 驗證各規則的違規描述都以 `<相對路徑>:<行號> <型別>.<名稱> "<值>" ` 開頭
    ///
    /// - Parameter scenario: 一筆只有一筆違規的案例，含預期的描述開頭
    @Test(arguments: AccessibilityIdentifierScanCases.descriptionPrefixCases)
    func describe_各規則違規_描述以位置型別名稱與值開頭(
        scenario: AccessibilityIdentifierScanCases.DescriptionPrefixCase
    ) {
        // Given

        // When
        let result = AccessibilityIdentifierScanner.scan(
            namespaceFiles: scenario.namespaceFiles,
            outsideFiles: scenario.outsideFiles,
            outsideRoots: scenario.outsideRoots,
            systemIdentifierPath: scenario.systemIdentifierPath,
            separators: separators
        )
        let descriptions = result.violations.map(\.description)

        // Then
        #expect(
            descriptions.count == 1,
            "\(scenario.name) 應只有一筆違規：\(AccessibilityIdentifierScanner.describe(result.violations))"
        )
        #expect(
            descriptions.first?.hasPrefix(scenario.expectedPrefix) == true,
            "\(scenario.name) 的描述開頭不符：\(AccessibilityIdentifierScanner.describe(result.violations))"
        )
    }

    /// 驗證正式原始碼沒有任何違規，避免新規則漏接個別測試的斷言
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有任何違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations

        // Then
        #expect(
            violations.isEmpty,
            "正式原始碼違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證正式命名空間的每個宣告都是接受的定義形式
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有定義形式違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .definitionForm }

        // Then
        #expect(
            violations.isEmpty,
            """
            定義形式違規：\(AccessibilityIdentifierScanner.describe(violations))
            接受的寫法見 spec ui-test-element-identity 與 .claude/rules/ios-ui-tests.md「定位與 identifier」
            """
        )
    }

    /// 驗證 App 與 UI 測試 target 沒有在命名空間目錄之外擴充或宣告 `BLAccessibilityID`
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有宣告位置違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .declarationLocation }

        // Then
        #expect(
            violations.isEmpty,
            "宣告位置違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證系統 identifier 都引用 UI 測試端常數，沒有在其他原始碼重寫字面值
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有系統identifier字面值違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .systemIdentifierLiteral }

        // Then
        #expect(
            violations.isEmpty,
            "系統 identifier 字面值違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證每個固定值與組出前綴的形狀合規，第一段等於所屬巢狀型別的 lowerCamelCase
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有形狀與第一段違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .shape || $0.rule == .firstSegment }

        // Then
        #expect(
            violations.isEmpty,
            "形狀或第一段違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證每個固定值與組出前綴都只含 ASCII 字元
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有非ASCII違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .asciiOnly }

        // Then
        #expect(
            violations.isEmpty,
            "非 ASCII 違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證固定值之間、組出前綴之間 (不分函式) 沒有相同的值
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    @Test
    func scan_正式原始碼_沒有值重複違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .duplicateValue }

        // Then
        #expect(
            violations.isEmpty,
            "值重複違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證沒有固定值落在查詢前綴之下，也沒有查詢前綴落在另一個查詢前綴之下
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    /// - Note: UI 測試以前綴查詢時，重疊會誤中其他元素
    @Test
    func scan_正式原始碼_沒有前綴重疊違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .prefixOverlap }

        // Then
        #expect(
            violations.isEmpty,
            "前綴重疊違規：\(AccessibilityIdentifierScanner.describe(violations))"
        )
    }

    /// 驗證掃描有掃到檔案、固定值與組出前綴，不會因為掃不到東西而誤判通過
    ///
    /// - Throws: 讀取或列舉正式原始碼失敗時丟出
    /// - Note: 訊息附掃到的檔案數、固定值數與組出前綴數，供人工核對
    @Test
    func scan_正式原始碼_沒有空掃描違規() throws {
        // Given
        let result = try Self.productionResult.get()

        // When
        let violations = result.violations.filter { $0.rule == .emptyScan }

        // Then
        #expect(
            violations.isEmpty,
            """
            空掃描違規：\(AccessibilityIdentifierScanner.describe(violations))，\
            掃到 \(result.definitions.fileCount) 檔、\(result.definitions.fixed.count) 個固定值、\
            \(result.definitions.prefixes.count) 個組出前綴
            """
        )
    }

    /// 驗證以空字串呼叫三個組字串函式得到的分隔符號依序為 `.`、`:`、`.index.`
    ///
    /// - Note: 函式格式變更時此測試轉紅，讓變更成為有意識的決定
    @Test
    func separators_組字串函式以空字串呼叫_分隔符號依序為句點冒號與句點index句點() {
        // Given
        let composed = [
            BLAccessibilityID.option("", key: ""),
            BLAccessibilityID.row("", key: ""),
            BLAccessibilityID.indexed("", index: 0),
        ]

        // When
        let separators = Self.productionSeparators()

        // Then
        #expect(composed == [".", ":", ".index.0"])
        #expect([separators.option, separators.row, separators.indexed] == [".", ":", ".index."])
    }
}

// MARK: - Nested Types

private extension AccessibilityIdentifierScanTests {

    /// 正式原始碼讀取失敗，讓每個讀取快取的測試各自回報錯誤
    enum ProductionScanError: Error, CustomStringConvertible {

        /// 正式掃描的原始錯誤，包含讀檔與斷言失敗
        ///
        /// - Parameter underlying: 原始掃描錯誤
        case scanFailed(underlying: any Error & Sendable)

        /// 正式原始碼讀取失敗的原始錯誤描述
        var description: String {
            switch self {
            case .scanFailed(let underlying):
                String(describing: underlying)
            }
        }
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierScanTests {

    /// 掃描正式原始碼：命名空間目錄 `BuyLedgerAccessibilityIDs/`，以及範圍外的 `BuyLedger/` 與 `BuyLedgerUITests/`
    ///
    /// - Returns: 掃描結果，命名空間檔案的路徑相對於 `BuyLedgerAccessibilityIDs/`，範圍外檔案的路徑相對於 `apps/ios`
    /// - Throws: 列舉目錄或讀取檔案失敗時丟出
    static func scanProduction() throws -> AccessibilityIdentifierScanner.ScanResult {
        let iosRoot = TestPaths.iosRoot
        let namespaceRoot = iosRoot.appending(path: "BuyLedgerAccessibilityIDs")
        let namespaceFiles = try sourceFiles(under: namespaceRoot, relativeTo: namespaceRoot)
        let outsideRoots = ["BuyLedger", "BuyLedgerUITests"]
        let outsideFiles = try outsideRoots.flatMap {
            try sourceFiles(under: iosRoot.appending(path: $0), relativeTo: iosRoot)
        }
        return AccessibilityIdentifierScanner.scan(
            namespaceFiles: namespaceFiles,
            outsideFiles: outsideFiles,
            outsideRoots: outsideRoots,
            systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
            separators: productionSeparators()
        )
    }

    /// 讀取目錄下全部 Swift 檔 (含生成檔)，依路徑排序
    ///
    /// - Parameters:
    ///   - directory: 要列舉的目錄
    ///   - base: 違規描述中相對路徑的根目錄
    /// - Returns: 相對路徑與原文
    /// - Throws: 列舉目錄或讀取檔案失敗時丟出
    static func sourceFiles(
        under directory: URL,
        relativeTo base: URL
    ) throws -> [AccessibilityIdentifierScanner.SourceFile] {
        let files = try SwiftSourceFiles.swiftFiles(under: directory, shouldIncludeGenerated: true)
        return try files
            .sorted { lhs, rhs in lhs.path < rhs.path }
            .map { file in
                let text = try String(contentsOf: file, encoding: .utf8)
                return AccessibilityIdentifierScanner.SourceFile(
                    relativePath: SwiftSourceFiles.relativePath(of: file, under: base),
                    text: text
                )
            }
    }

    /// 以正式的組字串函式取得分隔符號，與 UI 測試以空字串取前綴同源
    ///
    /// - Returns: `option`、`row`、`indexed` 在變動段之前插入的分隔符號
    static func productionSeparators() -> AccessibilityIdentifierScanner.Separators {
        let indexed = BLAccessibilityID.indexed("", index: 0)
        return AccessibilityIdentifierScanner.Separators(
            option: BLAccessibilityID.option("", key: ""),
            row: BLAccessibilityID.row("", key: ""),
            indexed: String(indexed.dropLast())
        )
    }
}
