//
//  ServiceOwnershipScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 唯讀列舉 App 正式原始碼，收集服務宣告並執行服務擁有權的三條守門規則
enum ServiceOwnershipScanner {}

// MARK: - Computed Properties

extension ServiceOwnershipScanner {

    /// 同一 checkout 的正式原始碼根目錄，由目前測試檔位置定位
    static var productionRoot: URL {
        TestPaths.iosRoot
            .appending(path: "BuyLedger")
    }
}

// MARK: - Internal Method

extension ServiceOwnershipScanner {

    /// 唯讀列舉正式原始碼並執行三條服務守門規則
    ///
    /// - Parameter root: App 正式原始碼根目錄
    /// - Returns: 服務清單與違規，不會寫入檔案
    /// - Throws: 根目錄無效、沒有服務宣告或讀檔失敗時丟出錯誤
    static func scanTree(under root: URL) throws -> ServiceOwnershipModels.ScanResult {
        let root = root.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let enumerator = FileManager.default.enumerator(
                  at: root,
                  includingPropertiesForKeys: nil
              ) else {
            throw ServiceOwnershipModels.ScanError.sourceRootNotFound(path: root.path)
        }
        let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        let urls: [URL] = enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "swift" else {
                return nil
            }
            return url
        }
        var files: [ServiceOwnershipModels.SourceFile] = []
        for url in urls.sorted(by: { first, second in first.path < second.path }) {
            files.append(
                ServiceOwnershipModels.SourceFile(
                    path: String(url.standardizedFileURL.path.dropFirst(prefix.count)),
                    contents: try String(contentsOf: url, encoding: .utf8)
                )
            )
        }
        return try scan(files: files)
    }

    /// 清空非程式碼文字後，收集服務並檢查擁有權、資料庫服務數量與訂單端的主檔目錄寫入權
    ///
    /// - Parameter files: 正式原始碼或測試建立的片段
    /// - Returns: 服務清單與三條規則的違規
    /// - Throws: 沒有適用的服務宣告時丟出 `noServiceDeclarations`
    static func scan(
        files: [ServiceOwnershipModels.SourceFile]
    ) throws(ServiceOwnershipModels.ScanError) -> ServiceOwnershipModels.ScanResult {
        let sources = files.map {
            ServiceOwnershipModels.SourceFile(
                path: $0.path,
                contents: DependencyConventionLexing.blankedCommentsAndStrings(in: $0.contents)
            )
        }
        let services = ServiceOwnershipRules.collectedServices(in: sources)
        guard !services.isEmpty else {
            throw .noServiceDeclarations
        }
        return ServiceOwnershipModels.ScanResult(
            services: services,
            foreignReferences: ServiceOwnershipRules.foreignReferences(
                in: sources,
                services: services
            ),
            duplicateDatabaseServices: ServiceOwnershipRules.duplicateDatabaseServices(
                in: services
            ),
            writableLookupCatalogs: ServiceOwnershipRules.writableLookupCatalogReferences(
                in: sources
            )
        )
    }
}
