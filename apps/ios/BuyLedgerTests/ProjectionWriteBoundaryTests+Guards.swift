//
//  ProjectionWriteBoundaryTests+Guards.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation
import Testing

extension ProjectionWriteBoundaryTests {

    /// 確認投影持有者檔案都存在
    @Test
    func projectionOwners_檢查主檔路徑_全部存在() {
        // Given
        let owners = Self.projectionOwners

        // When
        let missingOwners = owners.filter {
            !FileManager.default.fileExists(
                atPath: Self.productionRoot.appending(path: $0.homeFileRelativePath).path
            )
        }

        // Then
        #expect(missingOwners.isEmpty, "找不到主檔，投影清單已過時：\(missingOwners.map(\.homeFileRelativePath))")
    }

    /// 驗證掃描涵蓋足夠的 App 檔案並找到投影擁有者宣告
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    @Test
    func hasStructDeclaration_正式原始碼_找到所有擁有者() throws(any Error) {
        // Given
        let files = try Self.swiftFiles(under: Self.productionRoot)
        let owners = Self.projectionOwners

        // When
        let declarations = try owners.map {
            try Self.hasStructDeclaration(owner: $0, in: files)
        }

        // Then
        #expect(
            files.count >= Self.minimumProductionFileCount,
            "App target Swift 檔案數量不足，productionRoot：\(Self.productionRoot.path)"
        )
        for (owner, isFound) in zip(owners, declarations) {
            #expect(isFound, "掃描不到 `struct \(owner.name)` 的宣告，掃描機制或 projectionOwners.name 疑似與現況脫節")
        }
    }

    /// 驗證投影屬性只能由 `RootFeature.swift` 寫入
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    @Test
    func findViolations_掃描正式原始碼_只有根功能寫入投影() throws(any Error) {
        // Given
        let expectedViolationCount = 0

        // When
        let violations = try Self.findViolations()

        // Then
        #expect(
            violations.count == expectedViolationCount,
            "以下位置寫入了唯讀投影，投影一律只能由 RootFeature 寫入：\(Self.describe(violations))"
        )
    }

    /// 共享訂單只允許擁有者寫入，開團與更多功能只能轉成唯讀參考
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    @Test
    func sharedOrderViolations_掃描正式原始碼_沒有投影寫入或可寫參考外傳() throws(any Error) {
        // Given
        let files = try Self.swiftFiles(under: Self.productionRoot)
        var violations: [Violation] = []

        // When
        for file in files {
            let relativePath = Self.relativePath(of: file, under: Self.productionRoot)
            let source = try String(contentsOf: file, encoding: .utf8)
            violations += try Self.sharedOrderViolations(relativePath: relativePath, source: source)
        }

        // Then
        #expect(files.count >= Self.minimumProductionFileCount)
        #expect(violations.isEmpty, "共享訂單投影違規：\(Self.describe(violations))")
    }

    /// 以原始碼片段驗證共享訂單的寫入邊界與唯讀轉換規則
    ///
    /// - Parameter scenario: 檔案路徑、原始碼與預期違規筆數
    /// - Throws: 規則建立失敗時拋出錯誤
    @Test(arguments: Self.sharedOrderScenarios + Self.sharedOrderWriterScenarios)
    func sharedOrderViolations_套用路徑與原始碼_符合預期違規筆數(scenario: SharedOrderScenario) throws(any Error) {
        // Given
        let relativePath = scenario.relativePath
        let source = scenario.source

        // When
        let violations = try Self.sharedOrderViolations(relativePath: relativePath, source: source)

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}

// MARK: - Computed Properties

extension ProjectionWriteBoundaryTests {

    /// App target 的掃描根目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
