//
//  LayerBoundaryScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

/// 掃描功能、核心與共用模組之間的分層邊界
enum LayerBoundaryScanner {}

// MARK: - Nested Types

extension LayerBoundaryScanner {

    /// 記錄掃描命中的檔案、行號與違規名稱
    struct Violation {

        /// 相對於 App 正式原始碼根目錄的檔案路徑
        let file: String

        /// 命中所在的行號，從 1 開始
        let line: Int

        /// 命中的識別字或規則文字
        let typeName: String
    }
}

// MARK: - Computed Properties

extension LayerBoundaryScanner {

    /// 功能層頂層宣告的擷取目錄
    static var featuresRoot: URL {
        productionRoot.appending(path: "Features")
    }

    /// 核心層的分層守門目錄
    static var coreRoot: URL {
        productionRoot.appending(path: "Core")
    }

    /// 共用模組的分層守門目錄
    static var sharedRoot: URL {
        productionRoot.appending(path: "Shared")
    }

    /// 設計系統的分層守門目錄
    static var designSystemRoot: URL {
        productionRoot.appending(path: "Shared/DesignSystem")
    }
}

// MARK: - Internal Method

extension LayerBoundaryScanner {

    /// 掃描功能層原始檔，取得可對外使用的頂層宣告名稱
    ///
    /// - Returns: 功能層頂層宣告名稱
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    static func featureTopLevelDeclarationNames() throws -> Set<String> {
        var names = Set<String>()
        let patterns = try LayerBoundaryPatterns.declarationPatterns
        let exclusionPattern = try LayerBoundaryPatterns.accessModifierExclusionPattern

        for file in try SwiftSourceFiles.swiftFiles(under: featuresRoot) {
            let content = try String(contentsOf: file, encoding: .utf8)
            let rawLines = content.components(separatedBy: "\n")
            var stripMode = SwiftSourceStripping.StripMode.normal

            for rawLine in rawLines {
                let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                    from: rawLine,
                    mode: &stripMode
                )
                names.formUnion(
                    LayerBoundaryPatterns.topLevelDeclarationNames(
                        in: stripped,
                        patterns: patterns,
                        exclusionPattern: exclusionPattern
                    )
                )
            }
        }

        return names
    }

    /// 掃描指定目錄，找出引用候選名稱的位置
    ///
    /// - Parameters:
    ///   - featureNames: 要比對的頂層宣告名稱集合
    ///   - roots: 掃描根目錄
    /// - Returns: 依檔名與行號排序的違規位置
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    static func findViolations(
        featureNames: Set<String>,
        under roots: [URL]
    ) throws -> [Violation] {
        guard !featureNames.isEmpty else {
            return []
        }

        let alternation = featureNames.sorted()
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let pattern = try NSRegularExpression(pattern: #"\b(?:"# + alternation + #")\b"#)

        var violations: [Violation] = []

        for root in roots {
            for file in try SwiftSourceFiles.swiftFiles(under: root) {
                let content = try String(contentsOf: file, encoding: .utf8)
                let rawLines = content.components(separatedBy: "\n")
                var stripMode = SwiftSourceStripping.StripMode.normal

                for (index, rawLine) in rawLines.enumerated() {
                    let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                        from: rawLine,
                        mode: &stripMode
                    )
                    guard let matchedName = firstMatch(pattern, in: stripped) else {
                        continue
                    }

                    violations.append(
                        Violation(
                            file: SwiftSourceFiles.relativePath(of: file, under: productionRoot),
                            line: index + 1,
                            typeName: matchedName
                        )
                    )
                }
            }
        }

        return violations.sorted { lhs, rhs in
            (lhs.file, lhs.line) < (rhs.file, rhs.line)
        }
    }

    /// 掃描領域目錄，包含生成檔中的頂層宣告名稱
    ///
    /// - Returns: 領域層頂層宣告名稱
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    static func coreDomainTopLevelDeclarationNames() throws -> Set<String> {
        var names = Set<String>()
        let patterns = try LayerBoundaryPatterns.declarationPatterns
        let exclusionPattern = try LayerBoundaryPatterns.accessModifierExclusionPattern

        for file in try SwiftSourceFiles.swiftFiles(
            under: coreDomainRoot,
            shouldIncludeGenerated: true
        ) {
            let content = try String(contentsOf: file, encoding: .utf8)
            let rawLines = content.components(separatedBy: "\n")
            var stripMode = SwiftSourceStripping.StripMode.normal

            for rawLine in rawLines {
                let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                    from: rawLine,
                    mode: &stripMode
                )
                names.formUnion(
                    LayerBoundaryPatterns.topLevelDeclarationNames(
                        in: stripped,
                        patterns: patterns,
                        exclusionPattern: exclusionPattern
                    )
                )
            }
        }

        return names
    }

    /// 掃描設計系統原始檔中的狀態管理套件匯入宣告
    ///
    /// - Returns: 依檔名與行號排序的違規位置
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    static func composableArchitectureImportViolations() throws -> [Violation] {
        var violations: [Violation] = []
        let pattern = try LayerBoundaryPatterns.composableArchitectureImportPattern

        for file in try SwiftSourceFiles.swiftFiles(under: designSystemRoot) {
            let content = try String(contentsOf: file, encoding: .utf8)
            let rawLines = content.components(separatedBy: "\n")
            var stripMode = SwiftSourceStripping.StripMode.normal

            for (index, rawLine) in rawLines.enumerated() {
                let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                    from: rawLine,
                    mode: &stripMode
                )
                let trimmed = stripped.trimmingCharacters(in: .whitespaces)
                let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                let matches = pattern.firstMatch(in: trimmed, range: range)
                guard matches != nil else {
                    continue
                }

                violations.append(
                    Violation(
                        file: SwiftSourceFiles.relativePath(of: file, under: productionRoot),
                        line: index + 1,
                        typeName: "ComposableArchitecture"
                    )
                )
            }
        }

        return violations.sorted { lhs, rhs in
            (lhs.file, lhs.line) < (rhs.file, rhs.line)
        }
    }

    /// 找出宣告 `StoreOf<RootFeature>` 的功能層原始檔
    ///
    /// - Returns: 宣告根功能 store 的檔案相對路徑
    /// - Throws: 目錄或原始檔讀取失敗時丟出錯誤
    static func filesDeclaringRootStore() throws -> Set<String> {
        var files = Set<String>()

        for file in try SwiftSourceFiles.swiftFiles(under: featuresRoot) {
            let content = try String(contentsOf: file, encoding: .utf8)
            let rawLines = content.components(separatedBy: "\n")
            var stripMode = SwiftSourceStripping.StripMode.normal

            for rawLine in rawLines {
                let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                    from: rawLine,
                    mode: &stripMode
                )
                if stripped.contains("StoreOf<RootFeature>") {
                    files.insert(SwiftSourceFiles.relativePath(of: file, under: productionRoot))
                    break
                }
            }
        }

        return files
    }
}

// MARK: - Private Method

private extension LayerBoundaryScanner {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// App 正式原始碼的掃描根目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }

    /// 包含手寫與生成領域型別的掃描根目錄
    static var coreDomainRoot: URL {
        productionRoot.appending(path: "Core/Domain")
    }

    /// 取得樣式在文字中的第一個命中內容
    ///
    /// - Parameters:
    ///   - pattern: 要比對的正規表示式
    ///   - text: 已移除註解與字串內容的程式碼
    /// - Returns: 第一個符合的字串；沒有命中時回傳 `nil`
    static func firstMatch(_ pattern: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let result = pattern.firstMatch(in: text, range: range),
              let matchRange = Range(result.range, in: text) else {
            return nil
        }
        return String(text[matchRange])
    }
}
