//
//  DependencyConventionScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

/// 讀取 App 與單元測試原始碼，逐檔套用依賴規則並彙整違規
enum DependencyConventionScanner {}

// MARK: - Computed Properties

extension DependencyConventionScanner {

    /// 所有規則共用的 App 與單元測試根目錄
    static var appAndTestRoots: [DependencyScanRoot] {
        [
            DependencyScanRoot(url: iosRoot.appending(path: "BuyLedger"), sourceTree: .production),
            DependencyScanRoot(
                url: iosRoot.appending(path: "BuyLedgerTests"),
                sourceTree: .unitTests
            ),
        ]
    }
}

// MARK: - Internal Method

extension DependencyConventionScanner {

    /// 遞迴掃描指定根目錄並收集依賴規則違規
    ///
    /// - Parameters:
    ///   - rule: 要執行的依賴規則
    ///   - roots: 要掃描的根目錄
    /// - Returns: 違規清單，先依檔案路徑再依行號排序
    /// - Throws: 根目錄不存在或不是目錄時丟 `DependencyScanError.sourceRootNotFound(path:)`；
    ///   檔案不在根目錄下時丟 `DependencyScanError.sourceFileOutsideRoot(path:)`；沒有任何適用檔案時丟
    ///   `DependencyScanError.noApplicableSourceFiles(rule:)`；子規則沒有適用檔案時丟
    ///   `DependencyScanError.noApplicableSubruleFiles(rule:subrule:)`；讀檔失敗時丟系統錯誤
    static func scanTree(
        rule: DependencyScanRule,
        roots: [DependencyScanRoot]
    ) throws -> [DependencyScanViolation] {
        let requiredSubrules: [DependencyScanSubrule]
        switch rule {
        case .featureBoundary:
            requiredSubrules = [.featureOutsideData, .serviceFile]

        case .testValue:
            requiredSubrules = [.serviceDependency, .nonServiceDependency]

        case .dependencyTypeSubscript, .sharedContainer, .appModelContainer, .viewDependency:
            requiredSubrules = []
        }

        let files = try readFiles(under: roots)
        var viewTypeNames: Set<String> = []
        if rule == .viewDependency {
            viewTypeNames = DependencyConventionViewRules.collectViewTypeNames(in: files)
        }
        var allViolations: [DependencyScanViolation] = []
        var applicableSourceCount = 0
        var applicableSubruleCounts: [DependencyScanSubrule: Int] = [:]

        for file in files {
            guard let fileScan = DependencyConventionRules.violations(
                of: rule,
                in: file,
                viewTypeNames: viewTypeNames
            ) else {
                continue
            }
            applicableSourceCount += 1
            for subrule in fileScan.applicableSubrules {
                applicableSubruleCounts[subrule, default: 0] += 1
            }
            allViolations.append(contentsOf: fileScan.violations)
        }

        guard applicableSourceCount > 0 else {
            throw DependencyScanError.noApplicableSourceFiles(rule: rule)
        }
        for subrule in requiredSubrules {
            guard applicableSubruleCounts[subrule, default: 0] > 0 else {
                throw DependencyScanError.noApplicableSubruleFiles(rule: rule, subrule: subrule)
            }
        }
        return sorted(allViolations)
    }

    /// 對測試片段執行指定依賴檢查
    ///
    /// - Parameters:
    ///   - file: 案例建立的檔案掃描資料
    ///   - rules: 此案例要驗證的規則
    /// - Returns: 違規清單，先依檔案路徑再依行號排序
    static func fragmentViolations(
        in file: DependencyScanFile,
        rules: [DependencyScanRule]
    ) -> [DependencyScanViolation] {
        let viewTypeNames = DependencyConventionViewRules.collectViewTypeNames(in: [file])
        let fileViolations = rules.flatMap { rule in
            let scan = DependencyConventionRules.violations(
                of: rule,
                in: file,
                viewTypeNames: viewTypeNames
            )
            return scan?.violations ?? []
        }
        return sorted(fileViolations)
    }
}

// MARK: - Private Method

private extension DependencyConventionScanner {

    /// `BuyLedger` 與 `BuyLedgerTests` 的共同上層目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// 讀取所有根目錄下的 Swift 檔並標上來源類型，供跨檔規則先收集整樹資訊再逐檔檢查
    ///
    /// - Parameter roots: 要遞迴讀取的根目錄，依序處理
    /// - Returns: 各根目錄下的 Swift 檔，依根目錄順序與路徑排序
    /// - Throws: 根目錄不存在或不是目錄時丟 `DependencyScanError.sourceRootNotFound(path:)`；
    ///   檔案不在根目錄下時丟 `DependencyScanError.sourceFileOutsideRoot(path:)`；讀檔失敗時丟系統錯誤
    static func readFiles(under roots: [DependencyScanRoot]) throws -> [DependencyScanFile] {
        var files: [DependencyScanFile] = []
        for root in roots {
            let rootPath = root.url.standardizedFileURL.path
            let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
            for url in try swiftFiles(under: root.url) {
                let filePath = url.standardizedFileURL.path
                guard filePath.hasPrefix(prefix) else {
                    throw DependencyScanError.sourceFileOutsideRoot(path: filePath)
                }
                let contents = try String(contentsOf: url, encoding: .utf8)
                files.append(
                    DependencyScanFile(
                        relativePath: String(filePath.dropFirst(prefix.count)),
                        sourceTree: root.sourceTree,
                        contents: contents
                    )
                )
            }
        }
        return files
    }

    /// 列出根目錄底下含子資料夾的 Swift 檔
    ///
    /// - Parameter root: 要列舉的根目錄
    /// - Returns: 按路徑排序的 Swift 檔案
    /// - Throws: 根目錄不存在或不是目錄時丟 `DependencyScanError.sourceRootNotFound(path:)`
    static func swiftFiles(under root: URL) throws(DependencyScanError) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let enumerator = FileManager.default.enumerator(
                  at: root,
                  includingPropertiesForKeys: nil
              ) else {
            throw .sourceRootNotFound(path: root.standardizedFileURL.path)
        }

        return enumerator
            .compactMap { item in
                guard let url = item as? URL, url.pathExtension == "swift" else {
                    return nil
                }
                return url
            }
            .sorted { lhs, rhs in lhs.path < rhs.path }
    }

    /// 依檔案與行號排序違規
    ///
    /// - Parameter violations: 原始違規清單
    /// - Returns: 按檔名與行號遞增的清單
    static func sorted(_ violations: [DependencyScanViolation]) -> [DependencyScanViolation] {
        violations.sorted { lhs, rhs in
            (lhs.file, lhs.line) < (rhs.file, rhs.line)
        }
    }
}
