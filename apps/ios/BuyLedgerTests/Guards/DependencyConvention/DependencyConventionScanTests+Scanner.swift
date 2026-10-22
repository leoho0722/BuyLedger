//
//  DependencyConventionScanTests+Scanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

// MARK: - Computed Properties

extension DependencyConventionScanTests {

    /// 所有規則共用的 App 與單元測試根目錄，供主檔測試跨檔使用
    static var appAndTestRoots: [ScanRoot] {
        [
            ScanRoot(url: iosRoot.appending(path: "BuyLedger"), sourceTree: .production),
            ScanRoot(url: iosRoot.appending(path: "BuyLedgerTests"), sourceTree: .unitTests),
        ]
    }
}

// MARK: - Internal Method

extension DependencyConventionScanTests {

    /// 遞迴掃描指定根目錄並收集依賴規則違規，供主檔測試跨檔使用
    ///
    /// - Parameters:
    ///   - rule: 要執行的依賴規則
    ///   - roots: 要掃描的根目錄
    /// - Returns: 違規清單，先依檔案路徑再依行號排序
    /// - Throws: 根目錄不存在或不是目錄時丟 `ScanError.sourceRootNotFound(path:)`；檔案不在根目錄下時丟
    ///   `ScanError.sourceFileOutsideRoot(path:)`；沒有任何適用檔案時丟
    ///   `ScanError.noApplicableSourceFiles(rule:)`；子規則沒有適用檔案時丟
    ///   `ScanError.noApplicableSubruleFiles(rule:subrule:)`；讀檔失敗時丟系統錯誤
    static func scanTree(rule: ScanRule, roots: [ScanRoot]) throws(any Error) -> [ScanViolation] {
        let requiredSubrules: [ScanSubrule]
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
            viewTypeNames = collectViewTypeNames(in: files)
        }
        var allViolations: [ScanViolation] = []
        var applicableSourceCount = 0
        var applicableSubruleCounts: [ScanSubrule: Int] = [:]

        for file in files {
            guard let fileScan = Self.violations(
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
            throw ScanError.noApplicableSourceFiles(rule: rule)
        }
        for subrule in requiredSubrules {
            guard applicableSubruleCounts[subrule, default: 0] > 0 else {
                throw ScanError.noApplicableSubruleFiles(rule: rule, subrule: subrule)
            }
        }
        return sorted(allViolations)
    }

    /// 對測試片段執行指定依賴檢查，供主檔測試跨檔使用
    ///
    /// - Parameters:
    ///   - file: 案例建立的檔案掃描資料
    ///   - rules: 此案例要驗證的規則
    /// - Returns: 違規清單，先依檔案路徑再依行號排序
    static func fragmentViolations(in file: ScanFile, rules: [ScanRule]) -> [ScanViolation] {
        let viewTypeNames = collectViewTypeNames(in: [file])
        let fileViolations = rules.flatMap {
            Self.violations(of: $0, in: file, viewTypeNames: viewTypeNames)?.violations ?? []
        }
        return sorted(fileViolations)
    }
}

// MARK: - Private Method

private extension DependencyConventionScanTests {

    /// `BuyLedger` 與 `BuyLedgerTests` 的共同上層目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// 讀取所有根目錄下的 Swift 檔並標上來源類型，供跨檔規則先收集整樹資訊再逐檔檢查
    ///
    /// - Parameter roots: 要遞迴讀取的根目錄，依序處理
    /// - Returns: 各根目錄下的 Swift 檔，依根目錄順序與路徑排序
    /// - Throws: 根目錄不存在或不是目錄時丟 `ScanError.sourceRootNotFound(path:)`；檔案不在根目錄下時丟
    ///   `ScanError.sourceFileOutsideRoot(path:)`；讀檔失敗時丟系統錯誤
    static func readFiles(under roots: [ScanRoot]) throws(any Error) -> [ScanFile] {
        var files: [ScanFile] = []
        for root in roots {
            let rootPath = root.url.standardizedFileURL.path
            let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
            for url in try swiftFiles(under: root.url) {
                let filePath = url.standardizedFileURL.path
                guard filePath.hasPrefix(prefix) else {
                    throw ScanError.sourceFileOutsideRoot(path: filePath)
                }
                let contents = try String(contentsOf: url, encoding: .utf8)
                files.append(
                    ScanFile(
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
    /// - Throws: 根目錄不存在或不是目錄時丟 `ScanError.sourceRootNotFound(path:)`
    static func swiftFiles(under root: URL) throws(ScanError) -> [URL] {
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
}
