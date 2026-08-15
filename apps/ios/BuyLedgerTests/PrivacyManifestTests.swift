//
//  PrivacyManifestTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import Testing
/// 驗證隱私宣告
struct PrivacyManifestTests {
    
    // MARK: - Tests
    
    @Test func privacyManifestDeclaresRequiredReasonAndLinkedTelemetryData() throws(any Error) {
        let manifest = try Self.propertyList(at: "BuyLedger/Resources/PrivacyInfo.xcprivacy")
        
        let accessedAPIs = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaultsEntry = try #require(
            accessedAPIs.first {
                $0["NSPrivacyAccessedAPIType"] as? String
                    == "NSPrivacyAccessedAPICategoryUserDefaults"
            }
        )
        let reasons = try #require(
            userDefaultsEntry["NSPrivacyAccessedAPITypeReasons"] as? [String])
        #expect(reasons == ["CA92.1"])
        
        let collectedDataTypes = try #require(
            manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        let declaredTypes = Set(
            try collectedDataTypes.map { entry in
                try #require(entry["NSPrivacyCollectedDataType"] as? String)
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
    
    @Test func analyticsInitialStateUsesApplicationInfoPlist() throws(any Error) {
        let info = try Self.propertyList(at: "BuyLedger/Resources/Info.plist")
        
        #expect(info["FIREBASE_ANALYTICS_COLLECTION_ENABLED"] as? Bool == true)
    }
    
    @Test func servicesConfigurationDoesNotContainTheInvalidAnalyticsFlag() throws(any Error) {
        var configurationPaths = ["BuyLedger/Resources/GoogleService-Info.example.plist"]
        let realConfigurationPath = "BuyLedger/Resources/GoogleService-Info.plist"
        if FileManager.default.fileExists(atPath: Self.sourceURL(for: realConfigurationPath).path) {
            configurationPaths.append(realConfigurationPath)
        }
        
        for path in configurationPaths {
            let servicesConfiguration = try Self.propertyList(at: path)
            #expect(servicesConfiguration["IS_ANALYTICS_ENABLED"] == nil)
        }
    }
}

// MARK: - Private Method

private extension PrivacyManifestTests {
    
    /// 讀取 source tree 內的 plist，測試不依賴尚未產生的 build bundle
    /// - Parameter relativePath: 檔案相對路徑
    /// - Returns: plist 內容
    /// - Throws: plist 讀取或解析失敗時拋出錯誤
    static func propertyList(at relativePath: String) throws(any Error) -> [String: Any] {
        let url = sourceURL(for: relativePath)
        let data = try Data(contentsOf: url)
        return try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }
    
    /// 由測試檔位置組出 source tree 內的檔案 URL
    /// - Parameter relativePath: 相對於 source tree 的檔案路徑
    /// - Returns: 對應的檔案 URL
    static func sourceURL(for relativePath: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: relativePath)
    }
}
