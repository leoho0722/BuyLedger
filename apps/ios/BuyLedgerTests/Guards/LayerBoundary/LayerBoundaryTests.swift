//
//  LayerBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import Testing

/// 掃描分層邊界，確保核心與共用元件不依賴功能層
struct LayerBoundaryTests {

    // MARK: - Properties

    /// 一般掃描排除的生成檔目錄名稱
    static let excludedDirectoryName = "Generated"

    /// 正式原始碼各根目錄應包含的最低檔案數
    private static let minimumProductionFileCount = 15

    /// 功能層應提供的最低頂層宣告數
    private static let minimumFeatureDeclarationNameCount = 30

    /// 頂層宣告前允許的屬性標記與存取修飾詞
    static let modifierPrefix = #"^(?:@\w+(?:\([^)]*\))?\s+|"#
        + #"(?:public|internal|package|private|fileprivate|open|final)\s+)*"#

    /// 允許持有根功能 store 的三個導覽宿主
    private static let rootStoreWhitelist: Set<String> = [
        "Features/App/Presentation/Root/RootView.swift",
        "Features/App/Presentation/Root/RootTabLayout.swift",
        "Features/App/Presentation/Root/RootSidebarLayout.swift",
    ]

    /// 確認掃描涵蓋足量的正式原始碼與功能層宣告
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時拋出錯誤
    @Test
    func swiftFiles_正式原始碼目錄_取得足量檔案與宣告() throws(any Error) {
        // Given
        let featuresRoot = Self.featuresRoot
        let coreRoot = Self.coreRoot
        let sharedRoot = Self.sharedRoot

        // When
        let featuresFiles = try Self.swiftFiles(under: featuresRoot)
        let coreFiles = try Self.swiftFiles(under: coreRoot)
        let sharedFiles = try Self.swiftFiles(under: sharedRoot)
        let names = try Self.featureTopLevelDeclarationNames()

        // Then
        #expect(
            featuresFiles.count >= Self.minimumProductionFileCount,
            "功能層檔案掃描數量不足：\(featuresRoot.path)"
        )
        #expect(coreFiles.count >= Self.minimumProductionFileCount, "核心層檔案掃描數量不足：\(coreRoot.path)")
        #expect(
            sharedFiles.count >= Self.minimumProductionFileCount,
            "共用層檔案掃描數量不足：\(sharedRoot.path)"
        )
        #expect(names.count >= Self.minimumFeatureDeclarationNameCount, "功能層頂層宣告掃描數量不足")
    }

    /// 確認核心與共用目錄不引用功能層的頂層宣告
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時拋出錯誤
    @Test
    func findViolations_核心與共用目錄_不引用功能型別() throws(any Error) {
        // Given
        let names = try Self.featureTopLevelDeclarationNames()
        let roots = [Self.coreRoot, Self.sharedRoot]

        // When
        let violations = try Self.findViolations(featureNames: names, under: roots)

        // Then
        #expect(violations.isEmpty, "核心與共用層不得引用功能層：\(Self.describe(violations))")
    }

    /// 確認領域宣告清單包含手寫與生成檔中的必要型別
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時拋出錯誤
    /// - Note: 領域型別可能分散在手寫檔與生成檔，三個守門目標都必須納入
    @Test
    func coreDomainTopLevelDeclarationNames_含生成檔的領域目錄_收錄必要型別() throws(any Error) {
        // Given
        let requiredNames: Set<String> = [
            "OrderStatus",
            "CurrencyCode",
            "PaymentMethodFlags",
        ]

        // When
        let names = try Self.coreDomainTopLevelDeclarationNames()
        let missingNames = requiredNames.subtracting(names)

        // Then
        #expect(missingNames.isEmpty, "領域目錄掃描遺漏型別：\(missingNames.sorted().joined(separator: "、"))")
    }

    /// 確認設計系統不引用核心領域型別
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時拋出錯誤
    /// - Note: 設計系統只能接收原始值或自身宣告的型別
    @Test
    func findViolations_設計系統目錄_不引用領域型別() throws(any Error) {
        // Given
        let domainNames = try Self.coreDomainTopLevelDeclarationNames()

        // When
        let violations = try Self.findViolations(
            featureNames: domainNames,
            under: [Self.designSystemRoot]
        )

        // Then
        #expect(violations.isEmpty, "設計系統不得引用核心領域型別：\(Self.describe(violations))")
    }

    /// 確認設計系統不匯入狀態管理套件
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時拋出錯誤
    /// - Note: 設計系統不應取得功能層的相依注入容器
    @Test
    func composableArchitectureImportViolations_設計系統目錄_不匯入狀態管理套件() throws(any Error) {
        // Given
        let expectedViolationCount = 0

        // When
        let violations = try Self.composableArchitectureImportViolations()

        // Then
        #expect(
            violations.count == expectedViolationCount,
            "設計系統不得匯入狀態管理套件：\(Self.describe(violations))"
        )
    }

    /// 確認根功能 store 僅由白名單內的三個導覽宿主持有
    ///
    /// - Throws: 目錄或原始檔讀取失敗時拋出錯誤
    @Test
    func filesDeclaringRootStore_功能目錄_僅由三個根導覽宿主持有() throws(any Error) {
        // Given
        let expectedFiles = Self.rootStoreWhitelist

        // When
        let declaringFiles = try Self.filesDeclaringRootStore()

        // Then
        #expect(
            declaringFiles == expectedFiles,
            "根功能 store 宣告位置不符合白名單：\(declaringFiles.sorted().joined(separator: "、"))"
        )
    }
}
