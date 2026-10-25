//
//  ServiceOwnershipScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

/// 服務擁有權的單元測試，涵蓋專屬服務取用邊界、各功能資料庫服務數量與訂單只讀主檔目錄
struct ServiceOwnershipScanTests {

    /// 驗證正式原始碼中的功能只取得自己擁有或共用的服務，有跨功能引用時列出各處的檔案、行號與鍵值
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時丟出錯誤
    @Test
    func scanTree_正式原始碼_不跨功能取得專屬服務() throws {
        // Given
        let root = ServiceOwnershipScanner.productionRoot

        // When
        let result = try ServiceOwnershipScanner.scanTree(under: root)

        // Then
        #expect(result.foreignReferences.isEmpty, "跨功能服務引用：\(result.foreignReferences)")
    }

    /// 驗證正式原始碼中每個功能的資料庫操作只由一個服務負責，有重複時列出功能與服務名稱
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時丟出錯誤
    @Test
    func scanTree_正式原始碼_每個功能至多一個資料庫服務() throws {
        // Given
        let root = ServiceOwnershipScanner.productionRoot

        // When
        let result = try ServiceOwnershipScanner.scanTree(under: root)

        // Then
        #expect(
            result.duplicateDatabaseServices.isEmpty,
            "資料庫服務重複：\(result.duplicateDatabaseServices)"
        )
    }

    /// 驗證正式原始碼中各功能的資料庫服務與規格「database-backed services per feature after this change」的對照表完全相同
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時丟出錯誤
    /// - Note: 共用服務 (Core 與 App 組合根) 不屬任何功能，不列入對照表
    @Test
    func scanTree_正式原始碼_各功能的資料庫服務符合對照表() throws {
        // Given
        let root = ServiceOwnershipScanner.productionRoot

        // When
        let result = try ServiceOwnershipScanner.scanTree(under: root)

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

    /// 驗證正式原始碼中訂單功能只以 `SharedReader` 讀取主檔目錄，不宣告可寫入的 `Shared`，有可寫入宣告時列出檔案與行號
    ///
    /// - Throws: 原始碼根目錄、宣告收集或檔案讀取失敗時丟出錯誤
    @Test
    func scanTree_正式原始碼_訂單功能只讀主檔目錄() throws {
        // Given
        let root = ServiceOwnershipScanner.productionRoot

        // When
        let result = try ServiceOwnershipScanner.scanTree(under: root)

        // Then
        #expect(
            result.writableLookupCatalogs.isEmpty,
            "訂單功能可寫入主檔目錄：\(result.writableLookupCatalogs)"
        )
    }

    /// 驗證根目錄為不存在的路徑或檔案本身時，掃描丟出帶該路徑的 `sourceRootNotFound`，避免掃不到程式碼卻通過
    ///
    /// - Parameter isMissing: 是否使用必定不存在的子路徑
    /// - Throws: 掃描沒有丟出預期錯誤時由 `#require` 丟出
    @Test(arguments: [false, true])
    func scanTree_根目錄不存在或不是目錄_回報根目錄錯誤(isMissing: Bool) throws {
        // Given
        let sourceFile = URL(fileURLWithPath: #filePath)
        let root = isMissing ? sourceFile.appending(path: "missing") : sourceFile
        var actualError: (any Error)?

        // When
        do {
            _ = try ServiceOwnershipScanner.scanTree(under: root)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? ServiceOwnershipModels.ScanError)
        var reportedPath: String?
        if case .sourceRootNotFound(let path) = error {
            reportedPath = path
        }
        #expect(reportedPath == root.path, "應回報原始碼根目錄錯誤：\(error)")
    }

    /// 驗證沒有檔案或適用的服務宣告時，掃描丟出 `noServiceDeclarations`，不得視為通過
    ///
    /// - Parameter files: 沒有適用服務宣告的記憶體片段
    /// - Throws: 掃描沒有丟出預期錯誤時由 `#require` 丟出
    /// - Note: 服務宣告須位於 `DependencyValues` 擴充內，且檔案宣告 `DependencyKey`
    @Test(arguments: [
        [ServiceOwnershipModels.SourceFile](),
        [
            ServiceOwnershipModels.SourceFile(
                path: "Features/Orders/Data/Order/OrderService+Dependency.swift",
                contents: "struct Other { var orderService: OrderService }"
            ),
        ],
        [
            ServiceOwnershipModels.SourceFile(
                path: "Features/Orders/Data/Order/OrderService+Preview.swift",
                contents: "extension DependencyValues { var orderService: OrderService {} }"
            ),
        ],
    ])
    func scan_沒有適用服務宣告_回報零宣告錯誤(files: [ServiceOwnershipModels.SourceFile]) throws {
        // Given
        var actualError: ServiceOwnershipModels.ScanError?

        // When
        do {
            _ = try ServiceOwnershipScanner.scan(files: files)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let hasNoServiceDeclarations: Bool
        if case .noServiceDeclarations = error {
            hasNoServiceDeclarations = true
        } else {
            hasNoServiceDeclarations = false
        }
        #expect(hasNoServiceDeclarations, "應回報沒有服務宣告：\(error)")
    }

    /// 驗證服務的所屬功能由宣告檔的目錄決定，Core 的服務沒有所屬功能，資料庫分類只看宣告檔是否取得資料庫依賴
    ///
    /// - Throws: 掃描沒有適用的服務宣告時丟出 `noServiceDeclarations`
    @Test
    func scan_功能與共用服務宣告_保留目錄擁有者與資料庫分類() throws {
        // Given
        let files = ServiceOwnershipFixtures.referenceServices

        // When
        let result = try ServiceOwnershipScanner.scan(files: files)

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
