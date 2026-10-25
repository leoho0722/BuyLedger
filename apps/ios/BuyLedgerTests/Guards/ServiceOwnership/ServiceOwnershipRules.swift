//
//  ServiceOwnershipRules.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 服務擁有權的規則集合，收集服務宣告後依三條規則檢查跨功能引用、資料庫服務數量與訂單端主檔目錄寫入權
enum ServiceOwnershipRules {}

// MARK: - Internal Method

extension ServiceOwnershipRules {

    /// 收集宣告 `DependencyKey` 的檔案中，`DependencyValues` 擴充第一層的服務屬性
    ///
    /// - Parameter files: 已清空非程式碼文字的原始碼
    /// - Returns: 依宣告檔與鍵值排序的服務清單
    static func collectedServices(
        in files: [ServiceOwnershipModels.SourceFile]
    ) -> [ServiceOwnershipModels.ServiceDeclaration] {
        var services: [ServiceOwnershipModels.ServiceDeclaration] = []
        let registrationFiles = files.filter {
            DependencyConventionSyntax.declaresDependencyKey(in: $0.contents)
        }
        for file in registrationFiles {
            let source = file.contents
            let extensionMatches = DependencyConventionMatching.matches(
                #"\bextension\s+DependencyValues\b[^{}]*\{"#,
                in: source
            )
            let extensions = extensionMatches.compactMap {
                DependencyConventionSyntax.matchingDelimiter(
                    in: source,
                    openingAt: source.index(before: $0.range.upperBound)
                )
            }
            let declarations = DependencyConventionMatching.matches(
                #"\bvar\s+(\w+Service)\s*:\s*(\w+)\b"#,
                in: source
            )
            let databaseMatches = DependencyConventionMatching.matches(
                #"\\(?:DependencyValues)?\s*\.\s*buyLedgerDatabase\b"#,
                in: source
            )
            let hasDatabase = !databaseMatches.isEmpty
            for declaration in declarations {
                let isDependencyMember = extensions.contains { range in
                    guard range.contains(declaration.range.lowerBound) else {
                        return false
                    }
                    // 只認擴充第一層大括號內的宣告，避免收集巢狀型別內的同名屬性
                    let depth = source[range.lowerBound..<declaration.range.lowerBound]
                        .reduce(0) { depth, character in
                            depth + (character == "{" ? 1 : 0) - (character == "}" ? 1 : 0)
                        }
                    return depth == 1
                }
                guard isDependencyMember,
                      declaration.captures.count == 2,
                      let key = declaration.captures[0],
                      let typeName = declaration.captures[1] else {
                    continue
                }
                services.append(
                    ServiceOwnershipModels.ServiceDeclaration(
                        key: key,
                        typeName: typeName,
                        file: file.path,
                        owner: featureOwner(of: file.path),
                        isDatabaseBacked: hasDatabase
                    )
                )
            }
        }
        return services.sorted { first, second in
            (first.file, first.key) < (second.file, second.key)
        }
    }

    /// 找出取得其他功能服務的 key path，App 組合根與共用服務不受限制
    ///
    /// - Parameters:
    ///   - files: 已清空非程式碼文字的原始碼
    ///   - services: 依宣告檔收集的服務清單
    /// - Returns: 含引用檔案、key path 起始行與服務鍵值的違規
    static func foreignReferences(
        in files: [ServiceOwnershipModels.SourceFile],
        services: [ServiceOwnershipModels.ServiceDeclaration]
    ) -> [ServiceOwnershipModels.ReferenceViolation] {
        var violations: [ServiceOwnershipModels.ReferenceViolation] = []
        for file in files {
            guard let feature = featureOwner(of: file.path) else {
                continue
            }
            let matches = DependencyConventionMatching.matches(
                #"\\(?:DependencyValues)?\s*\.\s*(\w+Service)\b"#,
                in: file.contents
            )
            for match in matches {
                guard let key = match.captures.first.flatMap({ $0 }),
                      let service = services.first(where: { $0.key == key }),
                      let owner = service.owner,
                      owner != feature else {
                    continue
                }
                let line = file.contents[..<match.range.lowerBound].filter(\.isNewline).count + 1
                violations.append(
                    ServiceOwnershipModels.ReferenceViolation(file: file.path, line: line, key: key)
                )
            }
        }
        return violations.sorted { first, second in
            (first.file, first.line, first.key) < (second.file, second.line, second.key)
        }
    }

    /// 找出同一功能 Data 目錄內重複的資料庫服務型別，系統服務與共用目錄不計入
    ///
    /// - Parameter services: 依宣告檔收集的服務清單
    /// - Returns: 同一功能超過一個資料庫服務時的功能與型別名稱
    static func duplicateDatabaseServices(
        in services: [ServiceOwnershipModels.ServiceDeclaration]
    ) -> [ServiceOwnershipModels.DatabaseViolation] {
        var byFeature: [String: Set<String>] = [:]
        for service in services where service.isDatabaseBacked {
            let components = service.file.split(separator: "/")
            guard let owner = service.owner,
                  components.count >= 4,
                  components[2] == "Data" else {
                continue
            }
            byFeature[owner, default: []].insert(service.typeName)
        }
        return byFeature.keys.sorted().compactMap { feature in
            let names = byFeature[feature, default: []].sorted()
            guard names.count > 1 else {
                return nil
            }
            return ServiceOwnershipModels.DatabaseViolation(feature: feature, services: names)
        }
    }

    /// 找出訂單功能以可寫入形式取得的主檔目錄，`SharedReader` 不算違規
    ///
    /// - Parameter files: 已清空非程式碼文字的原始碼
    /// - Returns: 含檔案、宣告起始行與共享鍵 `lookupCatalog` 的違規
    static func writableLookupCatalogReferences(
        in files: [ServiceOwnershipModels.SourceFile]
    ) -> [ServiceOwnershipModels.ReferenceViolation] {
        var violations: [ServiceOwnershipModels.ReferenceViolation] = []
        for file in files where featureOwner(of: file.path) == "Orders" {
            let matches = DependencyConventionMatching.matches(
                #"\bShared\s*(?:\(\s*\.lookupCatalog\b|<\s*LookupCatalog\s*>)"#,
                in: file.contents
            )
            for match in matches {
                let line = file.contents[..<match.range.lowerBound].filter(\.isNewline).count + 1
                violations.append(
                    ServiceOwnershipModels.ReferenceViolation(
                        file: file.path,
                        line: line,
                        key: "lookupCatalog"
                    )
                )
            }
        }
        return violations.sorted { first, second in
            (first.file, first.line) < (second.file, second.line)
        }
    }
}

// MARK: - Private Method

private extension ServiceOwnershipRules {

    /// 取得正式原始碼相對路徑所屬的功能名稱，Core 與 App 組合根為共用
    ///
    /// - Parameter path: App 根目錄下的相對路徑
    /// - Returns: Features 的第一層功能名稱，其他目錄為 `nil`
    static func featureOwner(of path: String) -> String? {
        let components = path.split(separator: "/")
        guard components.count >= 3, components[0] == "Features" else {
            return nil
        }
        return String(components[1])
    }
}
