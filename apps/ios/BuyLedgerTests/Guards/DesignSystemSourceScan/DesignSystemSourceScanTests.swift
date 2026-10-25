//
//  DesignSystemSourceScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import Testing

/// `DesignSystemSourceScanner` 的單元測試，以掃描產品程式碼守住色彩、幣別、語言與版面分類的單一入口
struct DesignSystemSourceScanTests {

    // MARK: - Properties

    /// 規則三的八種色相引用情境，預期行號逐列指定
    private static let namedHueCases = [
        DesignSystemSourceScanner.SourceScanCase(
            source: ".foregroundStyle(.red)",
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(source: "Color.red", expectedLineNumbers: [1]),
        DesignSystemSourceScanner.SourceScanCase(
            source: "let colors = [.red]",
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(source: "let red = 1", expectedLineNumbers: []),
        DesignSystemSourceScanner.SourceScanCase(source: "case red", expectedLineNumbers: []),
        DesignSystemSourceScanner.SourceScanCase(
            source: "let preferred = 1",
            expectedLineNumbers: []
        ),
        DesignSystemSourceScanner.SourceScanCase(source: "case .red:", expectedLineNumbers: []),
        DesignSystemSourceScanner.SourceScanCase(
            source: "PaletteAction(.red)",
            expectedLineNumbers: []
        ),
    ]

    /// 尺寸分類的十六種詞法情境，保留規格來源文字與獨立指定的預期行號
    private static let sizeClassCases = [
        DesignSystemSourceScanner.SourceScanCase(
            source: #"@Environment(\.horizontalSizeClass) private var horizontalSizeClass"#,
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #".environment(\.verticalSizeClass, .regular)"#,
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: """
                extension EnvironmentValues {
                    var isRegular: Bool {
                        horizontalSizeClass == .regular
                    }
                }
                """,
            expectedLineNumbers: [3]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "horizontalSizeClass // design-system-scan-exempt: reason",
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #"@Environment(\.verticalSizeClass) private var verticalSizeClass // design-system-scan-exempt: reason"#,
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #"let pair = ("\\", horizontalSizeClass)"#,
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #"let pair = ("\"", horizontalSizeClass)"#,
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #"let separator = "\\""#,
            expectedLineNumbers: []
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "horizontalSizeClass/* note */as Any",
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "/* horizontalSizeClass */",
            expectedLineNumbers: []
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "let text = \"\"\"\n\\\"\"\"\n\"\"\"\nlet value = horizontalSizeClass",
            expectedLineNumbers: [4]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "let text = \"\"\"\nhorizontalSizeClass\n\"\"\"",
            expectedLineNumbers: []
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "let pair = (\"\u{0301}\", horizontalSizeClass)",
            expectedLineNumbers: [1]
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: "// horizontalSizeClass",
            expectedLineNumbers: []
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #""horizontalSizeClass""#,
            expectedLineNumbers: []
        ),
        DesignSystemSourceScanner.SourceScanCase(
            source: #"@Environment(\.blLayoutClass) private var layoutClass"#,
            expectedLineNumbers: []
        ),
    ]

    /// 驗證規則三的值位置色相引用會回報行號，非值位置與識別字則通過分類
    ///
    /// - Parameter scenario: 原始碼片段與獨立指定的預期違規行號
    @Test(arguments: Self.namedHueCases)
    func namedHueTokenPattern_值位置與非值位置的色相名稱_分類結果符合預期(
        scenario: DesignSystemSourceScanner.SourceScanCase
    ) {
        // Given
        let source = scenario.source

        // When
        let lineNumbers = DesignSystemSourceScanner.violatingLineNumbers(
            in: source,
            matching: DesignSystemSourcePatterns.namedHueTokenPattern,
            shouldHonorExemptions: true
        )

        // Then
        #expect(lineNumbers == scenario.expectedLineNumbers, "原始碼片段：\(scenario.source)")
    }

    /// 驗證規則十一的分類結果與規格範例表各列相符：註解或字串結束之後的引用，以及帶豁免標記的引用都回報，註解與字串內容不回報
    ///
    /// - Parameter scenario: 原始碼片段與獨立指定的預期違規行號
    @Test(arguments: Self.sizeClassCases)
    func sizeClassViolations_規格範例表各列_分類結果符合預期(scenario: DesignSystemSourceScanner.SourceScanCase) {
        // Given
        let source = scenario.source

        // When
        let lineNumbers = DesignSystemSourceScanner.sizeClassViolations(in: source)

        // Then
        #expect(lineNumbers == scenario.expectedLineNumbers, "原始碼片段：\(scenario.source)")
    }

    /// 驗證產品程式碼的尺寸分類引用只出現在版面判斷入口，豁免標記對規則十一無效
    ///
    /// - Throws: 原始檔讀取或目錄掃描失敗時丟出錯誤
    /// - Note: 掃描辨識 `//` 行註解、非巢狀 `/* … */` 區塊註解、單行 `"…"` 與多行 `"""…"""` 一般字串，包含反斜線跳脫並逐個 Unicode 碼位處理
    /// - Note: 其餘詞法形式超出掃描保證範圍，該處與之後的程式碼都可能漏判或誤判；
    ///   例如字串內插、原始字串與擴充分隔符號、正規表示式字面值、巢狀區塊註解
    @Test
    func sizeClassViolations_引用尺寸分類_僅出現在版面判斷入口() throws {
        // Given
        let scan: () throws -> [DesignSystemSourceScanner.Violation] = DesignSystemSourceScanner
            .sizeClassViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接引用尺寸分類，應改用 @Environment(\\.blLayoutClass)：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證產品程式碼目錄能掃到 Swift 檔案，避免目錄解析錯誤時因掃描結果為空而通過
    ///
    /// - Throws: 掃描檔案失敗時丟出錯誤
    @Test
    func productionRoot_掃描產品程式碼_取得非空檔案清單() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let files = try SwiftSourceFiles.swiftFiles(under: root)

        // Then
        #expect(
            !files.isEmpty,
            "掃描到 0 個 Swift 檔案，productionRoot 疑似解析錯誤：\(DesignSystemSourceScanner.productionRoot.path)"
        )
    }

    /// 驗證產品程式碼只透過 `CurrencyDisplayName` 查找幣別名稱，其他位置不得重新建立查表
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func currencyLookupViolations_查找幣別名稱_僅使用唯一入口() throws {
        // Given
        let scan = DesignSystemSourceScanner.currencyLookupViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "production code 不得建立第二份幣別名稱查表：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證產品程式碼只透過 `AppLanguage` 判斷語言，其他位置不得自行以 locale 推導
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func languageDerivationViolations_推導語言_僅使用唯一入口() throws {
        // Given
        let scan = DesignSystemSourceScanner.languageDerivationViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "production code 不得自行以 locale 推導語言：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則一的資訊性文字沒有直接使用系統次要色，應改用 `.blSecondaryLabel`
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_設定資訊性文字色彩_使用設計系統次要色() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.secondaryColorPattern
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統次要色於文字，應改用 `.blSecondaryLabel`：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則二沒有直接使用系統強調色，應改用色盤的 `.blAccent`
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_使用強調色_經由色盤取用() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.accentColorPattern
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統強調色，應改用 `.blAccent`：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則三沒有直接使用具名系統色相字面值，應改用對應的 `bl` 前綴色盤成員
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_使用具名系統色相_經由色盤取用() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.namedHueTokenPattern
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統色相字面值，應改用對應的 `bl` 前綴色盤成員，例如 `.blRed`：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則四的系統取色介面只出現在色盤檔 `Color+Semantic.swift`，其他檔案不呼叫
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_呼叫系統取色介面_僅出現在色盤() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.systemColorAPIPattern,
            excludingFilesNamed: ["Color+Semantic.swift"]
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置在色盤檔之外呼叫系統取色介面，應於 `Color+Semantic.swift` 新增 `bl` 成員後以 `.blX` 取用：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則五只有色盤檔與 `BLAvatar` 從原始分量建構色彩，其他檔案不得這麼做
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_從原始分量建構色彩_僅出現在色盤與頭像() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.rawConstructionPattern,
            excludingFilesNamed: ["Color+Semantic.swift", "BLAvatar.swift"]
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置在色盤檔與頭像元件之外從原始分量建構色彩，語意色一律改經色盤的系統取色介面：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則六的 `colorScheme` 環境宣告只出現在 `BLCardShadow.swift`
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_宣告外觀環境依賴_僅出現在卡片陰影() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.colorSchemeDeclarationPattern,
            excludingFilesNamed: ["BLCardShadow.swift"]
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置宣告了外觀環境依賴，僅卡片陰影修飾子真正讀取此值，其餘宣告應移除：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則七的十六進位顏色建構子已全庫移除，沒有任何引用
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findViolations_使用十六進位顏色建構子_不存在引用() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let violations = try DesignSystemSourceScanner.findViolations(
            under: root,
            matching: DesignSystemSourcePatterns.hexInitializerPattern
        )

        // Then
        #expect(
            violations.isEmpty,
            "以下位置仍存在十六進位顏色建構子，該建構子應已完全移除：\(DesignSystemSourceScanner.describe(violations))"
        )
    }

    /// 驗證規則八的豁免標記都附有非空理由，未附理由的標記會使測試失敗
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func findExemptionMarkers_使用豁免標記_附有非空理由() throws {
        // Given
        let root = DesignSystemSourceScanner.productionRoot

        // When
        let markers = try DesignSystemSourceScanner.findExemptionMarkers(under: root)
        let emptyReasonMarkers = markers.filter { $0.reason.isEmpty }

        // Then
        #expect(
            emptyReasonMarkers.isEmpty,
            "以下豁免標記未附理由，具名豁免標記必須帶非空理由：\(DesignSystemSourceScanner.describe(emptyReasonMarkers.map(\.violation)))"
        )
    }
}
