//
//  ServiceOwnershipScanTests+DatabaseCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

extension ServiceOwnershipScanTests {

    /// 資料庫服務依功能與型別計數，系統服務、非程式碼與共用目錄不誤判
    ///
    /// - Parameter testCase: 服務宣告片段與字面值違規
    /// - Throws: 服務宣告收集失敗時拋出錯誤
    @Test(arguments: ServiceOwnershipScanTests.databaseCases)
    func scan_資料庫服務宣告形式與位置_回傳精確功能與服務清單(testCase: DatabaseCase) throws {
        // Given
        let files = testCase.files

        // When
        let result = try Self.scan(files: files)

        // Then
        #expect(result.duplicateDatabaseServices == testCase.expected)
        #expect(result.foreignReferences == [])
    }
}

// MARK: - Private Method

private extension ServiceOwnershipScanTests {

    /// 涵蓋縮寫、完整與跨行資料庫 key path，以及不應計數的服務與目錄
    static var databaseCases: [DatabaseCase] {
        let campaign = serviceSource(
            path: "Features/Campaigns/Data/Campaign/CampaignService+Dependency.swift",
            key: "campaignService",
            typeName: "CampaignService",
            databaseCode: #"@Dependency(\.buyLedgerDatabase) var database"#
        )
        let short = serviceSource(
            path: "Features/Campaigns/Data/ExtraCampaignService+Dependency.swift",
            key: "extraCampaignService",
            typeName: "ExtraCampaignService",
            databaseCode: #"@Dependency(\.buyLedgerDatabase) var database"#
        )
        let full = serviceSource(
            path: "Features/Campaigns/Data/ExtraCampaignService+Dependency.swift",
            key: "extraCampaignService",
            typeName: "ExtraCampaignService",
            databaseCode: #"@Dependency(\DependencyValues.buyLedgerDatabase) var database"#
        )
        let multiline = serviceSource(
            path: "Features/Campaigns/Data/ExtraCampaignService+Dependency.swift",
            key: "extraCampaignService",
            typeName: "ExtraCampaignService",
            databaseCode: """
            @Dependency(
                \\DependencyValues.buyLedgerDatabase
            ) var database
            """
        )
        let system = serviceSource(
            path: "Features/Campaigns/Data/CalendarReminder/CalendarReminderService+Dependency.swift",
            key: "calendarReminderService",
            typeName: "CalendarReminderService"
        )
        let nonCode = serviceSource(
            path: "Features/Campaigns/Data/CalendarReminder/CalendarReminderService+Dependency.swift",
            key: "calendarReminderService",
            typeName: "CalendarReminderService",
            databaseCode: #"""
            // @Dependency(\.buyLedgerDatabase) var database
            let note = #"@Dependency(\DependencyValues.buyLedgerDatabase)"#
            """#
        )
        let coreFirst = SourceFile(
            path: "Core/Dependencies/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let coreSecond = SourceFile(
            path: "Core/Dependencies/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let appFirst = SourceFile(
            path: "App/Data/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let appSecond = SourceFile(
            path: "App/Data/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let featureAppFirst = SourceFile(
            path: "Features/App/Data/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let featureAppSecond = SourceFile(
            path: "Features/App/Data/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let outsideDataFirst = SourceFile(
            path: "Features/Campaigns/CampaignService+Dependency.swift",
            contents: campaign.contents
        )
        let outsideDataSecond = SourceFile(
            path: "Features/Campaigns/ExtraCampaignService+Dependency.swift",
            contents: full.contents
        )
        let aliases = SourceFile(
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
            DatabaseCase(
                files: [campaign, short],
                expected: [
                    DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            DatabaseCase(
                files: [campaign, full],
                expected: [
                    DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            DatabaseCase(
                files: [campaign, multiline],
                expected: [
                    DatabaseViolation(
                        feature: "Campaigns",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            DatabaseCase(files: [campaign, system], expected: []),
            DatabaseCase(files: [campaign, nonCode], expected: []),
            DatabaseCase(files: [coreFirst, coreSecond], expected: []),
            DatabaseCase(files: [appFirst, appSecond], expected: []),
            DatabaseCase(
                files: [featureAppFirst, featureAppSecond],
                expected: [
                    DatabaseViolation(
                        feature: "App",
                        services: ["CampaignService", "ExtraCampaignService"]
                    ),
                ]
            ),
            DatabaseCase(files: [outsideDataFirst, outsideDataSecond], expected: []),
            DatabaseCase(files: [aliases], expected: []),
        ]
    }
}
