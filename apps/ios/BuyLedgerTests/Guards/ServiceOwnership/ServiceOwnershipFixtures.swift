//
//  ServiceOwnershipFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 服務擁有權守門測試共用的服務宣告片段
enum ServiceOwnershipFixtures {}

// MARK: - Computed Properties

extension ServiceOwnershipFixtures {

    /// 引用案例共用的服務宣告清單，擁有者由各檔的字面值路徑決定
    static var referenceServices: [ServiceOwnershipModels.SourceFile] {
        [
            serviceSource(
                path: "Features/Orders/Data/Order/OrderService+Dependency.swift",
                key: "orderService",
                typeName: "OrderService",
                databaseCode: #"@Dependency(\.buyLedgerDatabase) var database"#
            ),
            serviceSource(
                path: "Features/Lookups/Data/LookupService+Dependency.swift",
                key: "lookupService",
                typeName: "LookupService",
                databaseCode: #"@Dependency(\DependencyValues.buyLedgerDatabase) var database"#
            ),
            serviceSource(
                path: "Core/Currency/CurrencyMetadataService.swift",
                key: "currencyMetadataService",
                typeName: "CurrencyMetadataService",
                databaseCode: #"@Dependency(\.buyLedgerDatabase) var database"#
            ),
            serviceSource(
                path: "Core/Telemetry/TelemetryService.swift",
                key: "telemetryService",
                typeName: "TelemetryService"
            ),
        ]
    }
}

// MARK: - Internal Method

extension ServiceOwnershipFixtures {

    /// 以測試字面值組成一個服務的依賴宣告片段，不執行片段程式碼
    ///
    /// - Parameters:
    ///   - path: 宣告所在的相對路徑
    ///   - key: `DependencyValues` 的屬性名稱
    ///   - typeName: 服務型別名稱
    ///   - databaseCode: 放入正式實作的資料庫依賴或非程式碼片段
    /// - Returns: 含正式實作與依賴鍵值宣告的測試原始碼
    static func serviceSource(
        path: String,
        key: String,
        typeName: String,
        databaseCode: String = ""
    ) -> ServiceOwnershipModels.SourceFile {
        ServiceOwnershipModels.SourceFile(
            path: path,
            contents: """
            extension \(typeName): DependencyKey {
                static var liveValue: Self {
                    \(databaseCode)
                    return Self()
                }
            }
            extension DependencyValues {
                var \(key): \(typeName) {
                    get { self[\(typeName).self] }
                    set { self[\(typeName).self] = newValue }
                }
            }
            """
        )
    }
}
