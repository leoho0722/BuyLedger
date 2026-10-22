//
//  ServiceOwnershipScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

/// 掃描專屬服務的取用邊界、每個功能的資料庫服務數量，以及訂單功能只讀主檔目錄
struct ServiceOwnershipScanTests {

    /// 正式功能只能取得自己擁有或共用的服務
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時拋出錯誤
    @Test
    func scanTree_正式原始碼_不跨功能取得專屬服務() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let result = try Self.scanTree(under: root)

        // Then
        #expect(result.foreignReferences.isEmpty, "跨功能服務引用：\(result.foreignReferences)")
    }

    /// 每個功能的資料庫操作只能由一個服務負責
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時拋出錯誤
    @Test
    func scanTree_正式原始碼_每個功能至多一個資料庫服務() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let result = try Self.scanTree(under: root)

        // Then
        #expect(
            result.duplicateDatabaseServices.isEmpty,
            "資料庫服務重複：\(result.duplicateDatabaseServices)"
        )
    }

    /// 規格範例「database-backed services per feature after this change」：各功能的資料庫服務對照表
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時拋出錯誤
    /// - Note: 共用服務 (Core 與 App 組合根) 不屬任何功能，不列入對照表
    @Test
    func scanTree_正式原始碼_各功能的資料庫服務符合對照表() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let result = try Self.scanTree(under: root)

        // Then
        let databaseServices = result.services.filter { $0.isDatabaseBacked && $0.owner != nil }
        let featureServices = Dictionary(grouping: databaseServices) { $0.owner ?? "" }
            .mapValues { $0.map(\.typeName).sorted() }
        #expect(
            featureServices == [
                "App": ["PersistenceRecoveryService"],
                "Campaigns": ["CampaignService"],
                "Lookups": ["LookupService"],
                "Orders": ["OrderService"],
            ]
        )
    }

    /// 訂單功能只以 `SharedReader` 讀取主檔目錄，不宣告可寫入的 `Shared`
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時拋出錯誤
    @Test
    func scanTree_正式原始碼_訂單功能只讀主檔目錄() throws(any Error) {
        // Given
        let root = Self.productionRoot

        // When
        let result = try Self.scanTree(under: root)

        // Then
        #expect(
            result.writableLookupCatalogs.isEmpty,
            "訂單功能可寫入主檔目錄：\(result.writableLookupCatalogs)"
        )
    }

    /// 根目錄不存在或實際是檔案時拋出錯誤，避免掃不到程式碼卻通過
    ///
    /// - Parameter isMissing: 是否使用必定不存在的子路徑
    /// - Throws: 掃描沒有拋出預期錯誤時由 `#require` 丟出
    @Test(arguments: [false, true])
    func scanTree_根目錄不存在或不是目錄_回報根目錄錯誤(isMissing: Bool) throws {
        // Given
        let sourceFile = URL(fileURLWithPath: #filePath)
        let root = isMissing ? sourceFile.appending(path: "missing") : sourceFile
        var actualError: (any Error)?

        // When
        do {
            _ = try Self.scanTree(under: root)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? ScanError)
        if case .sourceRootNotFound(let path) = error {
            #expect(path == root.path)
        } else {
            Issue.record("應回報原始碼根目錄錯誤")
        }
    }

    /// 沒有檔案、宣告不在依賴擴充或檔名不適用時都不得視為通過
    ///
    /// - Parameter files: 沒有適用服務宣告的記憶體片段
    /// - Throws: 掃描沒有拋出預期錯誤時由 `#require` 丟出
    @Test(arguments: [
        [SourceFile](),
        [
            SourceFile(
                path: "Features/Orders/Data/OrderService+Dependency.swift",
                contents: "struct Other { var orderService: OrderService }"
            ),
        ],
        [
            SourceFile(
                path: "Features/Orders/Data/OrderService+Preview.swift",
                contents: "extension DependencyValues { var orderService: OrderService {} }"
            ),
        ],
    ])
    func scan_沒有適用服務宣告_回報零宣告錯誤(files: [SourceFile]) throws {
        // Given
        var actualError: ScanError?

        // When
        do {
            _ = try Self.scan(files: files)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        switch error {
        case .noServiceDeclarations:
            break

        case .sourceRootNotFound:
            Issue.record("應回報沒有服務宣告")
        }
    }

    /// 服務的所屬功能由宣告目錄決定，核心與 App 組合根保持共用
    ///
    /// - Throws: 片段沒有收集到服務宣告時拋出錯誤
    @Test
    func scan_功能與共用服務宣告_保留目錄擁有者與資料庫分類() throws {
        // Given
        let files = Self.referenceServices

        // When
        let result = try Self.scan(files: files)

        // Then
        #expect(
            result.services.map(\.key).sorted() == [
                "currencyMetadataService",
                "lookupService",
                "orderService",
                "telemetryService",
            ]
        )
        #expect(result.services.filter { $0.owner == "Orders" }.map(\.key) == ["orderService"])
        #expect(result.services.filter { $0.owner == "Lookups" }.map(\.key) == ["lookupService"])
        #expect(
            result.services.filter { $0.owner == nil }.map(\.key).sorted() == [
                "currencyMetadataService",
                "telemetryService",
            ]
        )
        #expect(
            result.services.filter(\.isDatabaseBacked).map(\.key).sorted() == [
                "currencyMetadataService",
                "lookupService",
                "orderService",
            ]
        )
    }
}
