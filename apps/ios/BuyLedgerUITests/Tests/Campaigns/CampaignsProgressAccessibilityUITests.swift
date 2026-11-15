//
//  CampaignsProgressAccessibilityUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/6.
//

import XCTest

/// 開團列進度的 UI 測試，以無障礙標籤確認語言與朗讀順序
@MainActor
final class CampaignsProgressAccessibilityUITests: BLUITestCase {

    /// 驗證正體中文下，四月韓國團列標籤依序含到貨、0/3、收款與 $11,800
    ///
    /// - Throws: 開團列或測試前置條件未就緒時丟出測試錯誤
    func testCampaignRow_正體中文_進度標題後接目前值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let expectedFragment = "到貨、0/3、收款、$11,800"

        // When
        let label = try readKoreaCampaignRowLabel(in: app, awaiting: expectedFragment)

        // Then
        XCTAssertTrue(
            label.contains(expectedFragment),
            "四月韓國團列的 label 應含「\(expectedFragment)」，實際為「\(label)」"
        )
    }

    /// 驗證英文下，四月韓國團列標籤依序含 Arrived、0/3、Payment 與 NT$11,800
    ///
    /// - Throws: 開團列或測試前置條件未就緒時丟出測試錯誤
    func testCampaignRow_英文_進度標題為英文且後接目前值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders, language: .english))
        let expectedFragment = "Arrived, 0/3, Payment, NT$11,800"

        // When
        let label = try readKoreaCampaignRowLabel(in: app, awaiting: expectedFragment)

        // Then
        XCTAssertTrue(
            label.contains(expectedFragment),
            "四月韓國團列的 label 應含「\(expectedFragment)」，實際為「\(label)」"
        )
    }
}

// MARK: - Private Method

private extension CampaignsProgressAccessibilityUITests {

    /// 開啟開團列表，等指定片段出現後回傳四月韓國團列標籤
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - fragment: 預期出現在標籤中的片段
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 四月韓國團列當下的無障礙標籤
    /// - Throws: 開團畫面或測試前置條件未就緒時丟出測試錯誤
    /// - Note: 只等待片段出現，避開載入中的中間狀態
    /// - Note: 等待逾時交由呼叫端比對預期標籤
    func readKoreaCampaignRowLabel(
        in app: XCUIApplication,
        awaiting fragment: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> String {
        let campaigns = try CampaignsScreen.open(in: app, file: file, line: line)
        try requireCondition(
            campaigns.hasCampaign(campaignID: CampaignSeedFixture.koreaCampaignID, timeout: 10),
            in: app,
            "開團列表未見四月韓國團的列",
            file: file,
            line: line
        )
        let row = campaigns.campaignRow(campaignID: CampaignSeedFixture.koreaCampaignID)
        // 等待逾時由呼叫端斷言標籤
        _ = row.wait(for: NSPredicate(format: "label CONTAINS %@", fragment), timeout: 10)
        return row.label
    }
}
