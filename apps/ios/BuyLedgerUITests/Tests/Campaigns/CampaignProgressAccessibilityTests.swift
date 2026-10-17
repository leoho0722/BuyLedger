//
//  CampaignProgressAccessibilityTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/6.
//

import XCTest

/// 開團列合併朗讀的進度標題與目前值測試，守住標題依 App 語言顯示且接在目前值之前
final class CampaignProgressAccessibilityTests: BLUITestCase {

    // MARK: - Properties

    /// `campaignsWithOrders` 的四月韓國團開團 id
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 正體中文模式下，四月韓國團列依序朗讀每個進度標題與其後的目前值
    @MainActor
    func testCampaignRowLabel_正體中文_進度標題後接目前值() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let expectedFragment = "到貨、0/3、收款、$11,800"

        // When
        let label = readKoreaCampaignRowLabel(in: app, awaiting: expectedFragment)

        // Then
        XCTAssertTrue(
            label.contains(expectedFragment),
            "四月韓國團列的 label 應含「\(expectedFragment)」，實際為「\(label)」"
        )
    }

    /// 英文模式下，四月韓國團列的進度標題為英文且各自接在目前值之前
    @MainActor
    func testCampaignRowLabel_英文_進度標題為英文且後接目前值() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders, language: .english))
        let expectedFragment = "Arrived, 0/3, Payment, NT$11,800"

        // When
        let label = readKoreaCampaignRowLabel(in: app, awaiting: expectedFragment)

        // Then
        XCTAssertTrue(
            label.contains(expectedFragment),
            "四月韓國團列的 label 應含「\(expectedFragment)」，實際為「\(label)」"
        )
    }
}

// MARK: - Private Method

private extension CampaignProgressAccessibilityTests {

    /// 切到開團分頁，等四月韓國團列的 label 含指定片段後回傳當下的 label
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - fragment: 預期 label 含有的片段
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 四月韓國團列當下的無障礙標籤
    /// - Note: 只等片段出現以避開載入中的中間狀態，逾時不判失敗，是否符合預期由呼叫端斷言
    @MainActor
    func readKoreaCampaignRowLabel(
        in app: XCUIApplication,
        awaiting fragment: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到開團分頁後畫面未就緒",
                file: file,
                line: line
            )
        }

        let campaigns = CampaignsScreen(app: app)
        if !campaigns.hasCampaign(campaignID: Self.koreaCampaignID, timeout: 10) {
            failWithDiagnostics(
                in: app,
                "開團列表未見四月韓國團的列",
                file: file,
                line: line
            )
        }

        let row = campaigns.campaignRow(campaignID: Self.koreaCampaignID)
        row.wait(for: NSPredicate(format: "label CONTAINS %@", fragment), timeout: 10)
        return row.label
    }
}
