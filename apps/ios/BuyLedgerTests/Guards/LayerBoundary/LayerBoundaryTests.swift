//
//  LayerBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import Testing

/// `LayerBoundaryScanner` 的單元測試，守住功能、核心與共用模組之間的分層邊界
struct LayerBoundaryTests {

    // MARK: - Properties

    /// 正式原始碼各根目錄應包含的最低檔案數
    private static let minimumProductionFileCount = 15

    /// 功能層應提供的最低頂層宣告數
    private static let minimumFeatureDeclarationNameCount = 30

    /// 允許持有根功能 store 的三個導覽宿主
    private static let rootStoreWhitelist: Set<String> = [
        "Features/App/Presentation/Root/RootView.swift",
        "Features/App/Presentation/Root/RootTabLayout.swift",
        "Features/App/Presentation/Root/RootSidebarLayout.swift",
    ]

    /// 驗證各正式原始碼目錄至少含 15 個檔案，避免其他分層守門因掃描不足而空轉通過
    ///
    /// - Parameter scenario: 掃描根目錄與失敗訊息所用的目錄名稱
    /// - Throws: 目錄或原始檔讀取失敗時丟出錯誤
    @Test(arguments: [
        ProductionDirectoryCase(root: LayerBoundaryScanner.featuresRoot, name: "功能層"),
        ProductionDirectoryCase(root: LayerBoundaryScanner.coreRoot, name: "核心層"),
        ProductionDirectoryCase(root: LayerBoundaryScanner.sharedRoot, name: "共用層"),
    ])
    func swiftFiles_各正式原始碼目錄_取得足量檔案(scenario: ProductionDirectoryCase) throws {
        // Given
        let root = scenario.root

        // When
        let files = try SwiftSourceFiles.swiftFiles(under: root)

        // Then
        #expect(
            files.count >= Self.minimumProductionFileCount,
            "\(scenario.name)檔案掃描數量不足：\(root.path)"
        )
    }

    /// 驗證功能層至少提供 30 個頂層宣告，避免其他分層守門因宣告不足而空轉通過
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    @Test
    func featureTopLevelDeclarationNames_功能目錄_取得足量宣告() throws {
        // Given

        // When
        let names = try LayerBoundaryScanner.featureTopLevelDeclarationNames()

        // Then
        #expect(names.count >= Self.minimumFeatureDeclarationNameCount, "功能層頂層宣告掃描數量不足")
    }

    /// 驗證核心與共用目錄不引用功能層的頂層宣告
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    @Test
    func findViolations_核心與共用目錄_不引用功能型別() throws {
        // Given
        let names = try LayerBoundaryScanner.featureTopLevelDeclarationNames()
        let roots = [LayerBoundaryScanner.coreRoot, LayerBoundaryScanner.sharedRoot]

        // When
        let violations = try LayerBoundaryScanner.findViolations(featureNames: names, under: roots)

        // Then
        #expect(violations.isEmpty, "核心與共用層不得引用功能層：\(LayerBoundaryFileScan.describe(violations))")
    }

    /// 驗證領域宣告清單收錄手寫與生成檔中的必要型別
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    /// - Note: 領域型別可能分散在手寫檔與生成檔，兩者都要納入掃描
    @Test
    func coreDomainTopLevelDeclarationNames_含生成檔的領域目錄_收錄必要型別() throws {
        // Given
        let requiredNames: Set<String> = [
            "OrderStatus",
            "CurrencyCode",
            "PaymentMethodFlags",
        ]

        // When
        let names = try LayerBoundaryScanner.coreDomainTopLevelDeclarationNames()
        let missingNames = requiredNames.subtracting(names)

        // Then
        #expect(missingNames.isEmpty, "領域目錄掃描遺漏型別：\(missingNames.sorted().joined(separator: "、"))")
    }

    /// 驗證設計系統不引用核心領域型別
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    /// - Note: 設計系統只能接收原始值或自身宣告的型別
    @Test
    func findViolations_設計系統目錄_不引用領域型別() throws {
        // Given
        let domainNames = try LayerBoundaryScanner.coreDomainTopLevelDeclarationNames()

        // When
        let violations = try LayerBoundaryScanner.findViolations(
            featureNames: domainNames,
            under: [LayerBoundaryScanner.designSystemRoot]
        )

        // Then
        #expect(violations.isEmpty, "設計系統不得引用核心領域型別：\(LayerBoundaryFileScan.describe(violations))")
    }

    /// 驗證設計系統不匯入狀態管理套件
    ///
    /// - Throws: 目錄、原始檔讀取或正規表示式建立失敗時丟出錯誤
    /// - Note: 設計系統不匯入 `ComposableArchitecture`，因此取不到 `@Dependency`
    @Test
    func composableArchitectureImportViolations_設計系統目錄_不匯入狀態管理套件() throws {
        // Given
        let expectedViolationCount = 0

        // When
        let violations = try LayerBoundaryScanner.composableArchitectureImportViolations()

        // Then
        #expect(
            violations.count == expectedViolationCount,
            "設計系統不得匯入狀態管理套件：\(LayerBoundaryFileScan.describe(violations))"
        )
    }

    /// 驗證根功能 store 只由白名單內的三個導覽宿主持有
    ///
    /// - Throws: 目錄或原始檔讀取失敗時丟出錯誤
    @Test
    func filesDeclaringRootStore_功能目錄_僅由三個根導覽宿主持有() throws {
        // Given
        let expectedFiles = Self.rootStoreWhitelist

        // When
        let declaringFiles = try LayerBoundaryScanner.filesDeclaringRootStore()

        // Then
        #expect(
            declaringFiles == expectedFiles,
            "根功能 store 宣告位置不符合白名單：\(declaringFiles.sorted().joined(separator: "、"))"
        )
    }
}

// MARK: - Nested Types

extension LayerBoundaryTests {

    /// 正式原始碼目錄的掃描輸入與診斷名稱
    struct ProductionDirectoryCase: Sendable {

        /// 要掃描的正式原始碼根目錄
        let root: URL

        /// 失敗訊息中的目錄名稱
        let name: String
    }
}
