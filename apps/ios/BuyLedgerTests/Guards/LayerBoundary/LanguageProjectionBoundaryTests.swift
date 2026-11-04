//
//  LanguageProjectionBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/30.
//

import Testing

/// `LanguageProjectionScanner` 的守門測試，守住功能 View 不經跨功能投影取得語言的邊界
///
/// - Note: 禁止的是跨功能投影的讀法：功能目錄的 View 讀取根功能偏好投影 (`preferences.language`)，
///   或以 `@Shared` 讀取語言相關的共享鍵
/// - Note: 允許功能 View 以 `@Environment(\.locale)` 換算 `AppLanguage(locale:)`，
///   依 `.claude/rules/ios-accessibility-localization.md` 第 35 行
/// - Note: 功能自有的 `store.language` 也不在禁止範圍
struct LanguageProjectionBoundaryTests {

    // MARK: - Properties

    /// 唯一可讀取根功能偏好投影的根畫面，須與掃描命中的檔案精確相等 (`RootNavigationLayout` 以建構參數接收語言)
    private static let rootHostWhitelist: Set<String> = [
        "Features/App/Presentation/Root/RootView.swift",
    ]

    /// 驗證功能目錄掃描到足量檔案，避免守門因掃描路徑失效而空轉通過
    ///
    /// - Throws: 目錄列舉或原始檔讀取失敗時丟出錯誤
    @Test
    func scan_功能目錄_取得足量檔案() throws {
        // Given
        let minimumScannedFileCount = 1

        // When
        let result = try LanguageProjectionScanner.scan()

        // Then
        #expect(result.scannedFileCount >= minimumScannedFileCount, "功能目錄掃描檔數不足")
    }

    /// 驗證跨功能語言投影只出現在根畫面，命中檔案須與白名單精確相等
    ///
    /// - Throws: 目錄列舉或原始檔讀取失敗時丟出錯誤
    /// - Note: 不把 `AppLanguage(locale:)` 或功能自有的 `store.language` 算作違規，見類型說明
    @Test
    func languageProjection_功能目錄檢視_跨功能語言投影僅限根宿主() throws {
        // Given
        let expectedFiles = Self.rootHostWhitelist

        // When
        let result = try LanguageProjectionScanner.scan()
        let hitFiles = Set(result.hits.map(\.file))

        // Then
        #expect(
            hitFiles == expectedFiles,
            "跨功能語言投影命中與白名單不符：\(LanguageProjectionScanner.describe(result.hits))"
        )
    }
}
