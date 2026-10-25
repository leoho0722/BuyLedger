//
//  DependencyConventionRules.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

/// 依賴規範的逐檔規則判斷入口，以及各規則共用的違規組裝與 Service 檔名判斷
enum DependencyConventionRules {}

// MARK: - Internal Method

extension DependencyConventionRules {

    /// 執行單一檔案的依賴規則檢查，供掃描入口使用
    ///
    /// - Parameters:
    ///   - rule: 要套用的依賴規則
    ///   - file: 要檢查的 Swift 原始碼
    ///   - viewTypeNames: 整棵 production 目錄中遵循 `View` 的型別名稱，只有畫面依賴規則使用
    /// - Returns: 此檔案適用的子規則與違規；規則不適用此檔案時回傳 `nil`
    static func violations(
        of rule: DependencyScanRule,
        in file: DependencyScanFile,
        viewTypeNames: Set<String>
    ) -> DependencyFileScanResult? {
        switch rule {
        case .dependencyTypeSubscript:
            return DependencyFileScanResult(
                applicableSubrules: [],
                violations: dependencyTypeSubscriptViolations(in: file)
            )

        case .featureBoundary:
            let subrules = featureBoundarySubrules(in: file)
            guard !subrules.isEmpty else {
                return nil
            }
            return DependencyFileScanResult(
                applicableSubrules: subrules,
                violations: featureBoundaryViolations(in: file, for: subrules)
            )

        case .testValue:
            guard file.sourceTree == .production,
                  DependencyConventionSyntax.declaresDependencyKey(
                      in: DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
                  ) else {
                return nil
            }
            let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
            let subrule: DependencyScanSubrule = isServiceFilename(filename)
                ? .serviceDependency
                : .nonServiceDependency
            return DependencyFileScanResult(
                applicableSubrules: [subrule],
                violations: DependencyConventionTestValueRules.testValueViolations(in: file)
            )

        case .sharedContainer:
            return DependencyFileScanResult(
                applicableSubrules: [],
                violations: sharedContainerViolations(in: file)
            )

        case .appModelContainer:
            guard file.sourceTree == .production else {
                return nil
            }
            return DependencyFileScanResult(
                applicableSubrules: [],
                violations: appModelContainerViolations(in: file)
            )

        case .viewDependency:
            guard file.sourceTree == .production else {
                return nil
            }
            return DependencyFileScanResult(
                applicableSubrules: [],
                violations: DependencyConventionViewRules.viewDependencyViolations(
                    in: file,
                    viewTypeNames: viewTypeNames
                )
            )
        }
    }

    /// 比對大寫開頭、以 Service 結尾且可帶分類的 Swift 檔名，供邊界與測試值規則共用
    ///
    /// - Parameter filename: Swift 檔案名稱
    /// - Returns: 是否符合上述 Service 檔名格式
    static func isServiceFilename(_ filename: String) -> Bool {
        let matches = DependencyConventionMatching.matches(
            #"^[A-Z]\w*Service(\+\w+)?\.swift$"#,
            in: filename
        )
        return !matches.isEmpty
    }

    /// 建立含檔案、行號及引用內容的違規，供各規則共用
    ///
    /// - Parameters:
    ///   - file: 違規所屬的原始碼檔
    ///   - source: 已移除註解與字串的原始碼
    ///   - range: 命中在 `source` 中的位置
    ///   - reason: 規則判定違規的原因
    /// - Returns: 可呈現在掃描失敗診斷中的單筆違規
    static func violation(
        in file: DependencyScanFile,
        source: String,
        range: Range<String.Index>,
        reason: String
    ) -> DependencyScanViolation {
        let line = source[..<range.lowerBound].filter { $0.isNewline }.count + 1
        let reference = String(source[range])
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let referenceLimit = 120 // 避免過長的命中內容淹沒診斷重點
        return DependencyScanViolation(
            file: file.relativePath,
            line: line,
            reference: String(reference.prefix(referenceLimit)),
            reason: reason
        )
    }
}

// MARK: - Private Method

private extension DependencyConventionRules {

    /// 找出檔案中以型別注入或型別下標存取依賴的違規
    ///
    /// - Parameter file: 要檢查的 Swift 原始碼
    /// - Returns: 型別注入或型別下標存取的違規
    static func dependencyTypeSubscriptViolations(
        in file: DependencyScanFile
    ) -> [DependencyScanViolation] {
        let source = DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
        let extensionRanges = DependencyConventionMatching
            .matches(#"\bextension\s+DependencyValues\b[^{}]*\{"#, in: source)
            .compactMap { match in
                let openingBrace = source.index(before: match.range.upperBound)
                return DependencyConventionSyntax.matchingDelimiter(
                    in: source,
                    openingAt: openingBrace
                )
            }
        let isDependencyRegistration = DependencyConventionSyntax.declaresDependencyKey(in: source)
        var violations: [DependencyScanViolation] = []

        let dependencyPattern = #"@Dependency\s*\(\s*[A-Za-z_][A-Za-z0-9_]*(?:<[^<>]+>)?(?:\.[A-Za-z_][A-Za-z0-9_]*(?:<[^<>]+>)?)*\.self\s*\)"#
        for match in DependencyConventionMatching.matches(dependencyPattern, in: source) {
            violations.append(
                violation(
                    in: file,
                    source: source,
                    range: match.range,
                    reason: "不得以型別下標注入依賴"
                )
            )
        }

        let typeSubscriptPattern = #"([A-Za-z_$][A-Za-z0-9_$]*(?:\s*\.\s*[A-Za-z_$][A-Za-z0-9_$]*)*|[A-Za-z_$][A-Za-z0-9_$]*\s*\([^()]*\))\??\s*\[\s*([A-Za-z_][A-Za-z0-9_]*(?:<[^<>]+>)?(?:\.[A-Za-z_][A-Za-z0-9_]*(?:<[^<>]+>)?)*\.self)\s*\]"#
        let nonDependencyBases: Set<String> = [
            "as",
            "await",
            "case",
            "else",
            "for",
            "if",
            "in",
            "is",
            "return",
            "switch",
            "throw",
            "try",
            "while",
            "yield",
        ]
        for match in DependencyConventionMatching.matches(typeSubscriptPattern, in: source) {
            let base = match.captures.first.flatMap { $0 }
            let start = match.range.lowerBound
            let isWithinDependencyValuesExtension = extensionRanges.contains { $0.contains(start) }
            let isDependencyValuesAccessor = base == "self"
                && isDependencyRegistration
                && isWithinDependencyValuesExtension
            guard !isDependencyValuesAccessor, let base, !nonDependencyBases.contains(base) else {
                continue
            }
            violations.append(
                violation(
                    in: file,
                    source: source,
                    range: match.range,
                    reason: "不得以型別下標讀取依賴"
                )
            )
        }
        return violations
    }

    /// 列出 Feature 與 Service 邊界規則適用的子規則
    ///
    /// - Parameter file: 要判斷的 Swift 原始碼
    /// - Returns: 此檔案適用的邊界子規則
    static func featureBoundarySubrules(in file: DependencyScanFile) -> [DependencyScanSubrule] {
        guard file.sourceTree == .production else {
            return []
        }

        let components = file.relativePath.split(separator: "/")
        let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
        var subrules: [DependencyScanSubrule] = []
        if components.count >= 2,
           components[0] == "Features",
           components.count < 3 || components[2] != "Data" {
            subrules.append(.featureOutsideData)
        }
        if isServiceFilename(filename) {
            subrules.append(.serviceFile)
        }
        return subrules
    }

    /// 找出 Feature 直接存取儲存與網路依賴，以及 Service 取得其他 Service
    ///
    /// - Parameters:
    ///   - file: 要檢查的 Swift 原始碼
    ///   - subrules: 此檔案適用的 Feature 或 Service 子規則
    /// - Returns: 違反適用子規則的清單
    static func featureBoundaryViolations(
        in file: DependencyScanFile,
        for subrules: [DependencyScanSubrule]
    ) -> [DependencyScanViolation] {
        let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
        let source = DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
        var violations: [DependencyScanViolation] = []

        if subrules.contains(.featureOutsideData) {
            let dependencyPattern = #"(?:\\\.|\\DependencyValues\.|(?:\$0|DependencyValues)(?:\s*\.\s*\w+)*\s*\.\s*)(?:buyLedgerDatabase|httpClient|userDefaultsStore|appConfigurationStore)\b"#
            for match in DependencyConventionMatching.matches(dependencyPattern, in: source) {
                violations.append(
                    violation(
                        in: file,
                        source: source,
                        range: match.range,
                        reason: "Feature 不得直接取得 Database、Client 或 Store"
                    )
                )
            }

            let swiftDataPatterns = [
                #"\b(?:ModelContext|ModelContainer)\b"#,
                #"@Environment\s*\(\s*\\\.modelContext\b"#,
                #"\.modelContainer\s*\("#,
                #"@Query\b"#,
            ]
            for pattern in swiftDataPatterns {
                for match in DependencyConventionMatching.matches(pattern, in: source) {
                    violations.append(
                        violation(
                            in: file,
                            source: source,
                            range: match.range,
                            reason: "Feature 不得直接使用 SwiftData context 或 container"
                        )
                    )
                }
            }
        }

        guard subrules.contains(.serviceFile) else {
            return violations
        }
        let serviceName = String(filename.dropLast(".swift".count).prefix { $0 != "+" })
        let serviceReferencePatterns = [
            #"@Dependency\s*\(\s*(?:\\\.\s*|\\(?:DependencyValues\.)?)([a-z]\w*Service)\b"#,
            #"\bDependencyValues\s*\.\s*_current\s*\.\s*([a-z]\w*Service)\b"#,
            #"(?<!\\)\bDependencyValues\s*\.\s*([a-z]\w*Service)\b"#,
            #"\b([A-Z]\w*Service)\s*\.\s*liveValue\b"#,
        ]
        for pattern in serviceReferencePatterns {
            for match in DependencyConventionMatching.matches(pattern, in: source) {
                guard let referencedService = match.captures.first.flatMap({ $0 }),
                      referencedService.caseInsensitiveCompare(serviceName) != .orderedSame else {
                    continue
                }
                violations.append(
                    violation(
                        in: file,
                        source: source,
                        range: match.range,
                        reason: "Service 不得取得另一個 Service"
                    )
                )
            }
        }
        return violations
    }

    /// 找出讀取 `PersistenceContainer.shared` 的位置，以及 App 程式碼中宣告 `shared` 靜態屬性的位置
    ///
    /// - Parameter file: 要檢查的 Swift 原始碼
    /// - Returns: 讀取 `PersistenceContainer.shared` 或宣告 `shared` 靜態屬性的違規
    static func sharedContainerViolations(
        in file: DependencyScanFile
    ) -> [DependencyScanViolation] {
        let source = DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
        let referencePattern = #"\bPersistenceContainer\s*\.\s*shared\b"#
        var violations = DependencyConventionMatching.matches(referencePattern, in: source).map {
            violation(
                in: file,
                source: source,
                range: $0.range,
                reason: "不得讀取 PersistenceContainer.shared"
            )
        }

        guard file.sourceTree == .production else {
            return violations
        }
        let declarationPattern = #"\b(?:(?:nonisolated(?:\([^)]*\))?|private(?:\(set\))?|fileprivate|internal|public|package)\s+)*static\s+(?:(?:nonisolated(?:\([^)]*\))?|private(?:\(set\))?|fileprivate|internal|public|package)\s+)*(?:let|var)\s+shared\b"#
        for match in DependencyConventionMatching.matches(declarationPattern, in: source) {
            violations.append(
                violation(
                    in: file,
                    source: source,
                    range: match.range,
                    reason: "App 程式碼不得宣告 shared 靜態屬性"
                )
            )
        }
        return violations
    }

    /// 找出 App target 中附掛 SwiftData model container 的呼叫
    ///
    /// - Parameter file: 要檢查的 Swift 原始碼
    /// - Returns: App target 中附掛 model container 的違規
    static func appModelContainerViolations(
        in file: DependencyScanFile
    ) -> [DependencyScanViolation] {
        let source = DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
        let pattern = #"\.modelContainer\s*\("#
        return DependencyConventionMatching.matches(pattern, in: source).map {
            violation(
                in: file,
                source: source,
                range: $0.range,
                reason: "App target 不得出現 `.modelContainer(`"
            )
        }
    }
}
