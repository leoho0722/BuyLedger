//
//  ServiceOwnershipScanDatabaseCasesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

/// 資料庫服務歸屬規則的單元測試，涵蓋各種依賴寫法與目錄位置下每個功能至多一個服務的限制
struct ServiceOwnershipScanDatabaseCasesTests {

    /// 驗證各種資料庫依賴寫法與目錄位置下，同一功能的重複資料庫服務名單精確符合預期，系統服務、非程式碼與共用目錄不計入
    ///
    /// - Parameter testCase: 服務宣告片段與字面值違規
    /// - Throws: 掃描沒有適用的服務宣告時丟出 `noServiceDeclarations`
    @Test(arguments: ServiceOwnershipScanDatabaseCasesTests.databaseCases)
    func scan_資料庫服務宣告形式與位置_回傳精確功能與服務清單(testCase: ServiceOwnershipModels.DatabaseCase) throws {
        // Given
        let files = testCase.files

        // When
        let result = try ServiceOwnershipScanner.scan(files: files)

        // Then
        #expect(result.duplicateDatabaseServices == testCase.expected)
        #expect(result.foreignReferences == [])
    }
}

// MARK: - Private Method

private extension ServiceOwnershipScanDatabaseCasesTests {

    /// 資料庫服務數量規則的片段案例，涵蓋縮寫、完整與跨行的資料庫 key path、寫在 Service 主檔的依賴註冊，以及不應計數的服務與目錄
    static var databaseCases: [ServiceOwnershipModels.DatabaseCase] {
        let campaign = ServiceOwnershipFixtures.serviceSource(
            path: "Features/Campaigns/Data/Campaign/CampaignService+Dependency.swift",
            key: "campaignService",
            typeName: "CampaignService",
            databaseCode: #"@Dependency(\.buyLedgerDatabase) var database"#
        )
        let short = ServiceOwnershipFixtures.serviceSource(
            path: "Features/Campaigns/Data/ExtraCampaignService+Dependency.swift",
            key: "extraCampaignService",
            typeName: "ExtraCampaignService",
            databaseCode: #"@Dependency(\.buyLedgerDatabase) var database"#
        )
        let full = ServiceOwnershipFixtures.serviceSource(
            path: "Features/Campaigns/Data/ExtraCampaignService+Dependency.swift",
            key: "extraCampaignService",
            typeName: "ExtraCampaignService",
            databaseCode: #"@Dependency(\DependencyValues.buyLedgerDatabase) var database"#
        )
        let multiline = ServiceOwnershipFixtures.serviceSource(
            path: "Features/Campaigns/Data/ExtraCampaignService+Dependency.swift",
            key: "extraCampaignService",
            typeName: "ExtraCampaignService",
            databaseCode: """
            @Dependency(
                \\DependencyValues.buyLedgerDatabase
            ) var database
            """
        )
        let system = ServiceOwnershipFixtures.serviceSource(
            path: "Features/Campaigns/Data/CalendarReminder/CalendarReminderService+Dependency.swift",
            key: "calendarReminderService",
            typeName: "CalendarReminderService"
        )
        let nonCode = ServiceOwnershipFixtures.serviceSource(
            path: "Features/Campaigns/Data/CalendarReminder/CalendarReminderService+Dependency.swift",
            key: "calendarReminderService",
            typeName: "CalendarReminderService",
            databaseCode: #"""
            // @Dependency(\.buyLedgerDatabase) var database
            let note = #"@Dependency(\DependencyValues.buyLedgerDatabase)"#
            """#
        )
        let merged = ServiceOwnershipModels.SourceFile(
            path: "Features/Campaigns/Data/Campaign/CampaignService.swift",
            contents: campaign.contents
        )
        let coreFirst = ServiceOwnershipModels.SourceFile(
            path: "Core/Currency/CampaignService.swift",
            contents: campaign.contents
        )
        let coreSecond = ServiceOwnershipModels.SourceFile(
            path: "Core/Currency/ExtraCampaignService.swift",
            contents: full.contents
        )
        let appFirst = ServiceOwnershipModels.SourceFile(
            path: "App/Data/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let appSecond = ServiceOwnershipModels.SourceFile(
            path: "App/Data/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let featureAppFirst = ServiceOwnershipModels.SourceFile(
            path: "Features/App/Data/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let featureAppSecond = ServiceOwnershipModels.SourceFile(
            path: "Features/App/Data/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let outsideDataFirst = ServiceOwnershipModels.SourceFile(
            path: "Features/Campaigns/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let outsideDataSecond = ServiceOwnershipModels.SourceFile(
            path: "Features/Campaigns/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let aliases = ServiceOwnershipModels.SourceFile(
            path: campaign.path,
            contents: campaign.contents + """

            extension DependencyValues {
                var alternateCampaignService: CampaignService {
                    get { self[CampaignService.self] }
                    set { self[CampaignService.self] = newValue }
                }
            }
            """
        )
        return [
            ServiceOwnershipModels.DatabaseCase(
                files: [campaign, short],
                expected: [
                    ServiceOwnershipModels.DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            ServiceOwnershipModels.DatabaseCase(
                files: [campaign, full],
                expected: [
                    ServiceOwnershipModels.DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            ServiceOwnershipModels.DatabaseCase(
                files: [campaign, multiline],
                expected: [
                    ServiceOwnershipModels.DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            ServiceOwnershipModels.DatabaseCase(
                files: [merged, short],
                expected: [
                    ServiceOwnershipModels.DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            ServiceOwnershipModels.DatabaseCase(files: [campaign, system], expected: []),
            ServiceOwnershipModels.DatabaseCase(files: [campaign, nonCode], expected: []),
            ServiceOwnershipModels.DatabaseCase(files: [coreFirst, coreSecond], expected: []),
            ServiceOwnershipModels.DatabaseCase(files: [appFirst, appSecond], expected: []),
            ServiceOwnershipModels.DatabaseCase(
                files: [featureAppFirst, featureAppSecond],
                expected: [
                    ServiceOwnershipModels.DatabaseViolation(
                        feature: "App",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            ServiceOwnershipModels.DatabaseCase(
                files: [outsideDataFirst, outsideDataSecond],
                expected: []
            ),
            ServiceOwnershipModels.DatabaseCase(files: [aliases], expected: []),
        ]
    }
}
