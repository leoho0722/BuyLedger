//
//  DependencyConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation
import Testing

/// 守住 App 與單元測試中依賴注入邊界的掃描規則
struct DependencyConventionScanTests {

    // MARK: - Tests

    /// App 與單元測試現行程式碼不得違反任何依賴規範；違規時逐筆列出檔案、行號與原因
    ///
    /// - Parameter rule: 要掃描的依賴規則
    /// - Throws: 根目錄不存在或不是目錄時丟 `ScanError.sourceRootNotFound(path:)`；檔案不在
    ///   根目錄下時丟 `ScanError.sourceFileOutsideRoot(path:)`；沒有適用檔案時丟
    ///   `ScanError.noApplicableSourceFiles(rule:)`；子規則沒有適用檔案時丟
    ///   `ScanError.noApplicableSubruleFiles(rule:subrule:)`；讀檔失敗時丟系統錯誤
    @Test(arguments: ScanRule.allCases)
    func scanTree_每條規則掃描App與單元測試程式碼_沒有違規(rule: ScanRule) throws(any Error) {
        // Given
        let roots = Self.appAndTestRoots

        // When
        let violations = try Self.scanTree(rule: rule, roots: roots)

        // Then
        #expect(
            violations.isEmpty,
            Comment(rawValue: violations.map(\.diagnostic).joined(separator: "\n"))
        )
    }

    /// 根目錄設錯時，掃描應失敗並指出路徑，不把未掃到檔案當作沒有違規
    ///
    /// - Throws: 掃描器未拋出 `ScanError` 時由 `try #require` 丟出測試斷言錯誤
    @Test
    func scanTree_根目錄不存在_丟出缺少的路徑() throws(any Error) {
        // Given
        var actualError: (any Error)?
        let missingPath = "/DependencyConventionScanTests-missing-root"
        let missingRoot = URL(fileURLWithPath: missingPath)

        // When
        do {
            _ = try Self.scanTree(
                rule: .dependencyTypeSubscript,
                roots: [ScanRoot(url: missingRoot, sourceTree: .production)]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? ScanError)
        switch error {
        case .sourceRootNotFound(let path):
            #expect(path == "/DependencyConventionScanTests-missing-root")

        case .noApplicableSourceFiles, .sourceFileOutsideRoot, .noApplicableSubruleFiles:
            Issue.record("根目錄不存在時應回報 sourceRootNotFound")
        }
    }

    /// 根目錄內沒有可掃描的 Swift 檔時，掃描應失敗並指出規則，避免未執行的規則顯示通過
    ///
    /// - Throws: 找不到 App 正式程式碼根目錄，或掃描器未拋出 `ScanError` 時由
    ///   `try #require` 丟出測試斷言錯誤
    @Test
    func scanTree_根目錄沒有適用檔案_回報規則() throws(any Error) {
        // Given
        var actualError: (any Error)?
        let root = try #require(Self.appAndTestRoots.first { $0.sourceTree == .production })
        let resourcesRoot = root.url.appending(path: "Resources")

        // When
        do {
            _ = try Self.scanTree(
                rule: .dependencyTypeSubscript,
                roots: [ScanRoot(url: resourcesRoot, sourceTree: .production)]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? ScanError)
        switch error {
        case .noApplicableSourceFiles(let rule):
            #expect(rule == .dependencyTypeSubscript)

        case .sourceRootNotFound(let path):
            Issue.record("根目錄應存在：\(path)")

        case .sourceFileOutsideRoot(let path):
            Issue.record("檔案應位於根目錄下：\(path)")

        case .noApplicableSubruleFiles:
            Issue.record("dependencyTypeSubscript 不應缺少適用子規則")
        }
    }

    /// 違規案例應回報指定檔案、行號、引用文字與原因
    ///
    /// - Parameter scenario: 要送進掃描器的違規案例
    /// - Throws: 掃描器未回報違規時由 `try #require` 丟出錯誤
    @Test(arguments: DependencyConventionScanScenario.violationCases)
    func fragmentViolations_違規案例_回報位置與原因(
        scenario: DependencyConventionScanScenario.ViolationCase
    ) throws(any Error) {
        // Given
        let file = ScanFile(
            relativePath: scenario.relativePath,
            sourceTree: scenario.sourceTree,
            contents: scenario.source
        )

        // When
        let violations = Self.fragmentViolations(in: file, rules: scenario.rules)

        // Then
        let violation = try #require(violations.first)
        #expect(violations.count == 1, Comment(rawValue: scenario.name))
        #expect(violation.file == scenario.relativePath, Comment(rawValue: scenario.name))
        #expect(violation.line == scenario.expectedLine, Comment(rawValue: scenario.name))
        #expect(violation.reference == scenario.expectedReference, Comment(rawValue: scenario.name))
        #expect(violation.reason == scenario.expectedReason, Comment(rawValue: scenario.name))
    }

    /// 各規則的合規寫法，以及字串、註解內的規則文字，都不應產生違規
    ///
    /// - Parameter scenario: 要送進掃描器的合規案例
    @Test(arguments: DependencyConventionScanScenario.passingCases)
    func fragmentViolations_合規案例_不回報違規(scenario: DependencyConventionScanScenario.PassingCase) {
        // Given
        let file = ScanFile(
            relativePath: scenario.relativePath,
            sourceTree: scenario.sourceTree,
            contents: scenario.source
        )

        // When
        let violations = Self.fragmentViolations(in: file, rules: scenario.rules)

        // Then
        #expect(violations.isEmpty, Comment(rawValue: scenario.name))
    }
}

// MARK: - Nested Types

extension DependencyConventionScanTests {

    /// App 正式程式碼或單元測試；決定各規則是否適用
    enum SourceTree: Sendable {

        /// App 正式程式碼
        case production

        /// App 單元測試程式碼
        case unitTests
    }

    /// 掃描器提供的依賴規範
    enum ScanRule: CaseIterable, Sendable {

        /// 禁止以型別下標存取依賴
        case dependencyTypeSubscript

        /// 限制 Feature 與 Service 的依賴邊界
        case featureBoundary

        /// 限制 Service 與其他依賴的測試值
        case testValue

        /// 禁止讀取共用持久化容器；App 也不得宣告 `shared` 靜態屬性
        case sharedContainer

        /// 禁止 App target 附掛 SwiftData model container
        case appModelContainer
    }

    /// 分別確認掃描器涵蓋的依賴規範子範圍
    enum ScanSubrule: Hashable, Sendable {

        /// Feature 的 Data 目錄以外程式碼
        case featureOutsideData

        /// Service 原始碼中的跨 Service 依賴
        case serviceFile

        /// Service 的 `+Dependency.swift` 測試值
        case serviceDependency

        /// 非 Service 的 `+Dependency.swift` 測試值
        case nonServiceDependency
    }

    /// 掃描器要列舉的根目錄與來源類型
    struct ScanRoot: Sendable {

        /// 要遞迴列舉的檔案系統位置
        let url: URL

        /// 標示根目錄屬 App 正式程式碼或單元測試，決定各規則是否適用
        let sourceTree: SourceTree
    }

    /// 傳給單一規則的 Swift 檔案內容
    struct ScanFile: Sendable {

        /// 相對於所屬根目錄的路徑
        let relativePath: String

        /// 標示檔案屬 App 正式程式碼或單元測試，決定各規則是否適用
        let sourceTree: SourceTree

        /// 檔案完整文字，尚未移除註解與字串
        let contents: String
    }

    /// 一個檔案命中的適用子規則與違規
    struct FileScanResult: Sendable {

        /// 此檔案涵蓋的子規則
        let applicableSubrules: [ScanSubrule]

        /// 此檔案違反的規則
        let violations: [ScanViolation]
    }

    /// 掃描器回報的一筆規則違規
    struct ScanViolation: Sendable {

        /// 違規檔案相對於根目錄的位置
        let file: String

        /// 違規所在的 1 起算行號
        let line: Int

        /// 原樣放進失敗訊息的命中程式碼
        let reference: String

        /// 被違反的規則，寫成一句「不得…」或「必須…」的規則句，原樣放進失敗訊息
        let reason: String

        /// 組成檔案、行號、引用內容與原因的單行診斷文字
        var diagnostic: String {
            "\(file):\(line): \(reference): \(reason)"
        }
    }

    /// 一次正規表示式命中的字元範圍與擷取群組 (正規表示式中用括號框起、要單獨取出的片段)
    struct ScanMatch: Sendable {

        /// 命中在原始碼字串中的範圍
        let range: Range<String.Index>

        /// 各括號擷取片段的文字；未參與匹配的群組為 nil
        let captures: [String?]
    }

    /// 掃描根目錄或整理相對路徑時可能發生的錯誤
    enum ScanError: Error {

        /// 根目錄不存在或不是可列舉的目錄
        ///
        /// - Parameter path: 無法列舉的根目錄路徑
        case sourceRootNotFound(path: String)

        /// 規則未找到任何適用的 Swift 檔案
        ///
        /// - Parameter rule: 沒有找到適用檔案的掃描規則
        case noApplicableSourceFiles(rule: ScanRule)

        /// 某條規則的子規則未找到適用的 Swift 檔案
        ///
        /// - Parameters:
        ///   - rule: 子規則所屬的掃描規則
        ///   - subrule: 沒有找到適用檔案的規則子範圍
        case noApplicableSubruleFiles(rule: ScanRule, subrule: ScanSubrule)

        /// 被掃描檔案不在指定根目錄之下
        ///
        /// - Parameter path: 超出根目錄範圍的檔案路徑
        case sourceFileOutsideRoot(path: String)
    }

    /// Swift 字串起始或結尾分隔符的組成
    struct StringDelimiter: Sendable {

        /// 以井字號包住、不處理跳脫字元的字串分隔符中的井字號數量
        let hashCount: Int

        /// 單行或多行分隔符的引號數量
        let quoteCount: Int

        /// 起始分隔符包含的字元數
        var length: Int {
            hashCount + quoteCount
        }
    }

    /// 字串插值結束後要恢復的外層字串狀態
    struct StringParent: Sendable {

        /// 外層字串使用的分隔符
        let delimiter: StringDelimiter

        /// 外層插值原本的括號深度；外層不在插值內時為 nil
        let interpolationDepth: Int?
    }
}
