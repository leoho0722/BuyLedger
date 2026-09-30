//
//  DependencyConventionScanTests+Rules.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

// MARK: - Internal Method

extension DependencyConventionScanTests {

    /// 執行單一檔案的依賴規則檢查，供掃描入口跨檔使用
    ///
    /// - Parameters:
    ///   - rule: 要套用的依賴規則
    ///   - file: 要檢查的 Swift 原始碼
    /// - Returns: 此檔案適用的子規則與違規；規則不適用此檔案時回傳 nil
    static func violations(of rule: ScanRule, in file: ScanFile) -> FileScanResult? {
        switch rule {
        case .dependencyTypeSubscript:
            return FileScanResult(
                applicableSubrules: [],
                violations: dependencyTypeSubscriptViolations(in: file)
            )

        case .featureBoundary:
            let subrules = featureBoundarySubrules(in: file)
            guard !subrules.isEmpty else {
                return nil
            }
            return FileScanResult(
                applicableSubrules: subrules,
                violations: featureBoundaryViolations(in: file, for: subrules)
            )

        case .testValue:
            guard file.sourceTree == .production,
                  file.relativePath.hasSuffix("+Dependency.swift") else {
                return nil
            }
            let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
            let subrule: ScanSubrule = isServiceFilename(filename)
                ? .serviceDependency
                : .nonServiceDependency
            return FileScanResult(
                applicableSubrules: [subrule],
                violations: testValueViolations(in: file)
            )

        case .sharedContainer:
            return FileScanResult(
                applicableSubrules: [],
                violations: sharedContainerViolations(in: file)
            )

        case .appModelContainer:
            guard file.sourceTree == .production else {
                return nil
            }
            return FileScanResult(
                applicableSubrules: [],
                violations: appModelContainerViolations(in: file)
            )
        }
    }

    /// 比對大寫開頭、以 Service 結尾且可帶分類的 Swift 檔名，供邊界與測試值規則共用
    ///
    /// - Parameter filename: Swift 檔案名稱
    /// - Returns: 是否符合上述 Service 檔名格式
    static func isServiceFilename(_ filename: String) -> Bool {
        !matches(#"^[A-Z]\w*Service(\+\w+)?\.swift$"#, in: filename).isEmpty
    }
}

// MARK: - Private Method

private extension DependencyConventionScanTests {

    /// 找出檔案中以型別注入或型別下標存取依賴的違規
    ///
    /// - Parameter file: 要檢查的 Swift 原始碼
    /// - Returns: 型別注入或型別下標存取的違規
    static func dependencyTypeSubscriptViolations(in file: ScanFile) -> [ScanViolation] {
        let source = blankedCommentsAndStrings(in: file.contents)
        let extensionRanges = matches(#"\bextension\s+DependencyValues\b[^{}]*\{"#, in: source)
            .compactMap { match in
                let openingBrace = source.index(before: match.range.upperBound)
                return matchingDelimiter(in: source, openingAt: openingBrace)
            }
        var violations: [ScanViolation] = []

        let dependencyPattern = #"@Dependency\s*\(\s*[A-Za-z_][A-Za-z0-9_]*(?:<[^<>]+>)?(?:\.[A-Za-z_][A-Za-z0-9_]*(?:<[^<>]+>)?)*\.self\s*\)"#
        for match in matches(dependencyPattern, in: source) {
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
        for match in matches(typeSubscriptPattern, in: source) {
            let base = match.captures.first.flatMap { $0 }
            let start = match.range.lowerBound
            let isWithinDependencyValuesExtension = extensionRanges.contains { $0.contains(start) }
            let isDependencyValuesAccessor = base == "self"
                && file.relativePath.hasSuffix("+Dependency.swift")
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
    static func featureBoundarySubrules(in file: ScanFile) -> [ScanSubrule] {
        guard file.sourceTree == .production else {
            return []
        }

        let components = file.relativePath.split(separator: "/")
        let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
        var subrules: [ScanSubrule] = []
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
        in file: ScanFile,
        for subrules: [ScanSubrule]
    ) -> [ScanViolation] {
        let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
        let source = blankedCommentsAndStrings(in: file.contents)
        var violations: [ScanViolation] = []

        if subrules.contains(.featureOutsideData) {
            let dependencyPattern = #"(?:\\\.|\\DependencyValues\.|(?:\$0|DependencyValues)(?:\s*\.\s*\w+)*\s*\.\s*)(?:buyLedgerDatabase|httpClient|userDefaultsStore|appConfigurationStore)\b"#
            for match in matches(dependencyPattern, in: source) {
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
                for match in matches(pattern, in: source) {
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
            for match in matches(pattern, in: source) {
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

    /// 找出共用容器引用與 App 程式碼的 `shared` 靜態屬性宣告
    ///
    /// - Parameter file: 要檢查的 Swift 原始碼
    /// - Returns: 共用容器引用或靜態屬性宣告的違規
    static func sharedContainerViolations(in file: ScanFile) -> [ScanViolation] {
        let source = blankedCommentsAndStrings(in: file.contents)
        let referencePattern = #"\bPersistenceContainer\s*\.\s*shared\b"#
        var violations = matches(referencePattern, in: source).map {
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
        for match in matches(declarationPattern, in: source) {
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
    static func appModelContainerViolations(in file: ScanFile) -> [ScanViolation] {
        let source = blankedCommentsAndStrings(in: file.contents)
        let pattern = #"\.modelContainer\s*\("#
        return matches(pattern, in: source).map {
            violation(
                in: file,
                source: source,
                range: $0.range,
                reason: "App target 不得出現 `.modelContainer(`"
            )
        }
    }
}
