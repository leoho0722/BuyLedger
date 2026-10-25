//
//  PrivacyManifestTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import Testing

/// 隱私清單與 Firebase 相關 plist 的單元測試，直接讀取 source tree 內的 plist 逐項檢查
struct PrivacyManifestTests {

    /// 驗證隱私宣告含 `UserDefaults` 的 `CA92.1` 存取理由與指定的五種資料類別，DeviceID 用途為分析與 App 功能，且未追蹤、無追蹤網域
    ///
    /// - Throws: 隱私宣告讀取或必要欄位驗證失敗時丟出錯誤
    @Test
    func propertyList_隱私宣告_包含必要理由與遙測資料() throws {
        // Given
        let path = "BuyLedger/Resources/PrivacyInfo.xcprivacy"

        // When
        let manifest = try Self.propertyList(at: path)

        // Then
        let accessedAPIs = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaultsEntry = try #require(
            accessedAPIs.first {
                $0["NSPrivacyAccessedAPIType"] as? String
                    == "NSPrivacyAccessedAPICategoryUserDefaults"
            }
        )
        let reasons = try #require(
            userDefaultsEntry["NSPrivacyAccessedAPITypeReasons"] as? [String]
        )
        #expect(reasons == ["CA92.1"])

        let collectedDataTypes = try #require(
            manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]]
        )
        let declaredTypes = Set(
            try collectedDataTypes.map {
                try #require($0["NSPrivacyCollectedDataType"] as? String)
            }
        )
        #expect(
            declaredTypes == [
                "NSPrivacyCollectedDataTypeCrashData",
                "NSPrivacyCollectedDataTypeDeviceID",
                "NSPrivacyCollectedDataTypeOtherDiagnosticData",
                "NSPrivacyCollectedDataTypePerformanceData",
                "NSPrivacyCollectedDataTypeProductInteraction",
            ]
        )

        let deviceIDEntry = try #require(
            collectedDataTypes.first {
                $0["NSPrivacyCollectedDataType"] as? String == "NSPrivacyCollectedDataTypeDeviceID"
            }
        )
        let deviceIDPurposes = try #require(
            deviceIDEntry["NSPrivacyCollectedDataTypePurposes"] as? [String]
        )
        #expect(
            Set(deviceIDPurposes) == [
                "NSPrivacyCollectedDataTypePurposeAnalytics",
                "NSPrivacyCollectedDataTypePurposeAppFunctionality",
            ]
        )
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)
    }

    /// 驗證 `Info.plist` 將 `FIREBASE_ANALYTICS_COLLECTION_ENABLED` 設為 `true`，分析收集由 App 的初始設定啟用
    ///
    /// - Throws: App 屬性清單讀取失敗時丟出錯誤
    @Test
    func propertyList_應用程式初始設定_啟用分析收集() throws {
        // Given
        let path = "BuyLedger/Resources/Info.plist"

        // When
        let info = try Self.propertyList(at: path)

        // Then
        #expect(info["FIREBASE_ANALYTICS_COLLECTION_ENABLED"] as? Bool == true)
    }

    /// 驗證 Google 服務設定範本與存在的正式設定檔都不含 `IS_ANALYTICS_ENABLED`，此旗標在 iOS 無效
    ///
    /// - Throws: Google 服務屬性清單讀取失敗時丟出錯誤
    @Test
    func propertyList_服務設定範本與正式檔_不含無效分析旗標() throws {
        // Given
        var configurationPaths = ["BuyLedger/Resources/GoogleService-Info.example.plist"]
        let realConfigurationPath = "BuyLedger/Resources/GoogleService-Info.plist"
        if FileManager.default.fileExists(atPath: Self.sourceURL(for: realConfigurationPath).path) {
            configurationPaths.append(realConfigurationPath)
        }

        // When
        let configurations = try configurationPaths.map { try Self.propertyList(at: $0) }

        // Then
        for servicesConfiguration in configurations {
            #expect(servicesConfiguration["IS_ANALYTICS_ENABLED"] == nil)
        }
    }
}

// MARK: - Private Method

private extension PrivacyManifestTests {

    /// 讀取 source tree 內的 plist，測試不依賴尚未產生的 build bundle
    ///
    /// - Parameter relativePath: 檔案相對路徑
    /// - Returns: plist 內容
    /// - Throws: plist 讀取或解析失敗時丟出錯誤
    static func propertyList(at relativePath: String) throws -> [String: Any] {
        let url = sourceURL(for: relativePath)
        let data = try Data(contentsOf: url)
        return try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }

    /// 以 `TestPaths.iosRoot` 組出 source tree 內的檔案 URL
    ///
    /// - Parameter relativePath: 相對於 source tree 的檔案路徑
    /// - Returns: 對應的檔案 URL
    static func sourceURL(for relativePath: String) -> URL {
        TestPaths.iosRoot
            .appending(path: relativePath)
    }
}
