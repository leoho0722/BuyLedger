//
//  DesignSystemSourceScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import Testing

/// 掃描產品程式碼，守住色彩、幣別、語言與版面分類的單一入口
struct DesignSystemSourceScanTests {

    // MARK: - Properties

    /// 規則三的八種色相引用情境，預期行號逐列指定
    private static let namedHueCases = [
        SourceScanCase(source: ".foregroundStyle(.red)", expectedLineNumbers: [1]),
        SourceScanCase(source: "Color.red", expectedLineNumbers: [1]),
        SourceScanCase(source: "let colors = [.red]", expectedLineNumbers: [1]),
        SourceScanCase(source: "let red = 1", expectedLineNumbers: []),
        SourceScanCase(source: "case red", expectedLineNumbers: []),
        SourceScanCase(source: "let preferred = 1", expectedLineNumbers: []),
        SourceScanCase(source: "case .red:", expectedLineNumbers: []),
        SourceScanCase(source: "PaletteAction(.red)", expectedLineNumbers: []),
    ]

    /// 尺寸分類的十六種詞法情境，保留規格來源文字與獨立指定的預期行號
    private static let sizeClassCases = [
        SourceScanCase(
            source: #"@Environment(\.horizontalSizeClass) private var horizontalSizeClass"#,
            expectedLineNumbers: [1]
        ),
        SourceScanCase(
            source: #".environment(\.verticalSizeClass, .regular)"#,
            expectedLineNumbers: [1]
        ),
        SourceScanCase(
            source: """
            extension EnvironmentValues {
                var isRegular: Bool {
                    horizontalSizeClass == .regular
                }
            }
            """,
            expectedLineNumbers: [3]
        ),
        SourceScanCase(
            source: "horizontalSizeClass // design-system-scan-exempt: reason",
            expectedLineNumbers: [1]
        ),
        SourceScanCase(
            source: #"@Environment(\.verticalSizeClass) private var verticalSizeClass // design-system-scan-exempt: reason"#,
            expectedLineNumbers: [1]
        ),
        SourceScanCase(
            source: #"let pair = ("\\", horizontalSizeClass)"#,
            expectedLineNumbers: [1]
        ),
        SourceScanCase(
            source: #"let pair = ("\"", horizontalSizeClass)"#,
            expectedLineNumbers: [1]
        ),
        SourceScanCase(source: #"let separator = "\\""#, expectedLineNumbers: []),
        SourceScanCase(source: "horizontalSizeClass/* note */as Any", expectedLineNumbers: [1]),
        SourceScanCase(source: "/* horizontalSizeClass */", expectedLineNumbers: []),
        SourceScanCase(
            source: "let text = \"\"\"\n\\\"\"\"\n\"\"\"\nlet value = horizontalSizeClass",
            expectedLineNumbers: [4]
        ),
        SourceScanCase(
            source: "let text = \"\"\"\nhorizontalSizeClass\n\"\"\"",
            expectedLineNumbers: []
        ),
        SourceScanCase(
            source: "let pair = (\"\u{0301}\", horizontalSizeClass)",
            expectedLineNumbers: [1]
        ),
        SourceScanCase(source: "// horizontalSizeClass", expectedLineNumbers: []),
        SourceScanCase(source: #""horizontalSizeClass""#, expectedLineNumbers: []),
        SourceScanCase(
            source: #"@Environment(\.blLayoutClass) private var layoutClass"#,
            expectedLineNumbers: []
        ),
    ]

    /// 規則三的值位置色相引用應回報行號，非值位置與識別字應通過分類
    ///
    /// - Parameter scenario: 原始碼片段與獨立指定的預期違規行號
    @Test(arguments: Self.namedHueCases)
    func namedHueTokenPattern_值位置與非值位置的色相名稱_分類結果符合預期(scenario: SourceScanCase) {
        // Given
        let source = scenario.source

        // When
        let lineNumbers = Self.violatingLineNumbers(
            in: source,
            matching: Self.namedHueTokenPattern,
            shouldHonorExemptions: true
        )

        // Then
        #expect(lineNumbers == scenario.expectedLineNumbers, "原始碼片段：\(scenario.source)")
    }

    /// 經規則十一入口分類規格範例表各列：剝除邊界之後的引用與帶豁免標記的引用都要回報，註解與字串內容不回報
    ///
    /// - Parameter scenario: 原始碼片段與獨立指定的預期違規行號
    @Test(arguments: Self.sizeClassCases)
    func sizeClassViolations_規格範例表各列_分類結果符合預期(scenario: SourceScanCase) {
        // Given
        let source = scenario.source

        // When
        let lineNumbers = Self.sizeClassViolations(in: source)

        // Then
        #expect(lineNumbers == scenario.expectedLineNumbers, "原始碼片段：\(scenario.source)")
    }

    /// 規則十一：產品程式碼的尺寸分類引用只出現在版面判斷入口，豁免標記無效
    ///
    /// - Throws: 原始檔讀取或目錄掃描失敗時拋出錯誤
    /// - Note: 掃描辨識 `//` 行註解、非巢狀 `/* … */` 區塊註解、單行 `"…"` 與多行 `"""…"""` 一般字串，包含反斜線跳脫並逐個 Unicode 碼位處理
    /// - Note: 其餘詞法形式超出掃描保證範圍，該處與之後的程式碼都可能漏判或誤判；
    ///   例如字串內插、原始字串與擴充分隔符號、正規表示式字面值、巢狀區塊註解
    @Test
    func sizeClassViolations_引用尺寸分類_僅出現在版面判斷入口() throws(any Error) {
        // Given
        let scan: () throws(any Error) -> [Violation] = Self.sizeClassViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接引用尺寸分類，應改用 @Environment(\\.blLayoutClass)：\(Self.describe(violations))"
        )
    }

    /// 確認掃描根目錄可取得檔案
    ///
    /// - Throws: 掃描檔案失敗時拋出錯誤
    @Test
    func productionRoot_掃描產品程式碼_取得非空檔案清單() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let files = try Self.swiftFiles(under: root)

        // Then
        #expect(
            !files.isEmpty,
            "掃描到 0 個 Swift 檔案，productionRoot 疑似解析錯誤：\(Self.productionRoot.path)"
        )
    }

    /// 確認產品程式碼只透過 `CurrencyDisplayName` 查找幣別名稱
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func currencyLookupViolations_查找幣別名稱_僅使用唯一入口() throws(any Error) {
        // Given
        let scan = Self.currencyLookupViolations

        // When
        let violations = try scan()

        // Then
        #expect(violations.isEmpty, "production code 不得建立第二份幣別名稱查表：\(Self.describe(violations))")
    }

    /// 確認產品程式碼只透過 `AppLanguage` 判斷語言
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func languageDerivationViolations_推導語言_僅使用唯一入口() throws(any Error) {
        // Given
        let scan = Self.languageDerivationViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "production code 不得自行以 locale 推導語言：\(Self.describe(violations))"
        )
    }

    /// 規則一：資訊性文字使用 `.blSecondaryLabel`
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_設定資訊性文字色彩_使用設計系統次要色() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(under: root, matching: Self.secondaryColorPattern)

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統次要色於文字，應改用 `.blSecondaryLabel`：\(Self.describe(violations))"
        )
    }

    /// 規則二：不得直接使用系統強調色，一律經色盤的 `.blAccent` 取用
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_使用強調色_經由色盤取用() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(under: root, matching: Self.accentColorPattern)

        // Then
        #expect(violations.isEmpty, "以下位置直接使用系統強調色，應改用 `.blAccent`：\(Self.describe(violations))")
    }

    /// 規則三：元件不得直接使用系統色彩，必須經色盤取用
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_使用具名系統色相_經由色盤取用() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(under: root, matching: Self.namedHueTokenPattern)

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統色相字面值，應改用對應的 `bl` 前綴色盤成員，例如 `.blRed`：\(Self.describe(violations))"
        )
    }

    /// 規則四：系統取色 API 只准在色盤檔
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_呼叫系統取色介面_僅出現在色盤() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(
            under: root,
            matching: Self.systemColorAPIPattern,
            excludingFilesNamed: ["Color+Semantic.swift"]
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置在色盤檔之外呼叫系統取色介面，應於 `Color+Semantic.swift` 新增 `bl` 成員後以 `.blX` 取用：\(Self.describe(violations))"
        )
    }

    /// 規則五：原始色彩建構只出現在色盤與頭像元件
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_從原始分量建構色彩_僅出現在色盤與頭像() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(
            under: root,
            matching: Self.rawConstructionPattern,
            excludingFilesNamed: ["Color+Semantic.swift", "BLAvatar.swift"]
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置在色盤檔與頭像元件之外從原始分量建構色彩，語意色一律改經色盤的系統取色介面：\(Self.describe(violations))"
        )
    }

    /// 規則六：`colorScheme` 只准用於卡片陰影修飾子
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_宣告外觀環境依賴_僅出現在卡片陰影() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(
            under: root,
            matching: Self.colorSchemeDeclarationPattern,
            excludingFilesNamed: ["BLCardShadow.swift"]
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置宣告了外觀環境依賴，僅卡片陰影修飾子真正讀取此值，其餘宣告應移除：\(Self.describe(violations))"
        )
    }

    /// 規則七：禁止使用十六進位顏色建構子
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findViolations_使用十六進位顏色建構子_不存在引用() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findViolations(under: root, matching: Self.hexInitializerPattern)

        // Then
        #expect(violations.isEmpty, "以下位置仍存在十六進位顏色建構子，該建構子應已完全移除：\(Self.describe(violations))")
    }

    /// 規則八：豁免標記必須有理由
    ///
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test
    func findExemptionMarkers_使用豁免標記_附有非空理由() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let markers = try Self.findExemptionMarkers(under: root)
        let emptyReasonMarkers = markers.filter { $0.reason.isEmpty }

        // Then
        #expect(
            emptyReasonMarkers.isEmpty,
            "以下豁免標記未附理由，具名豁免標記必須帶非空理由：\(Self.describe(emptyReasonMarkers.map(\.violation)))"
        )
    }
}
