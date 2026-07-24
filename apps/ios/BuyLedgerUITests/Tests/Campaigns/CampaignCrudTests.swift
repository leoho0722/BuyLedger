//
//  CampaignCrudTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團的新增與刪除流程測試
///
/// 一律以 accessibility identifier 定位；找不到 App 元素即附診斷失敗、不 skip。
/// 新增以空資料庫驗「新增後列表多一列」，刪除走「取消」分支只驗確認 alert 有出現又能收回、開團未被刪除，不真的刪除資料
final class CampaignCrudTests: BLUITestCase {

    // MARK: - Static Properties

    /// 新增開團填入的名稱 (使用者資料，中英兩語言皆可輸入)
    private static let newCampaignName = "測試開團"

    /// campaignsWithOrders 用來進詳情的四月韓國團開團 id (進行中)
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    // MARK: - Tests

    /// 完整新增：點新增 → 表單就緒 → 填名稱 → 儲存 → 回列表且列表多出一列
    @MainActor
    func testCreateCampaignAppearsInList() {
        let app = launch(LaunchOptions(seed: .empty))

        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒")
        }

        let campaigns = CampaignsScreen(app: app)
        campaigns.tapAdd()

        let edit = CampaignEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點新增後編輯表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現"
            )
        }

        edit.typeName(Self.newCampaignName)
        edit.tapSave()

        // 回到開團列表：empty 原本無開團，建立後列表容器應出現且至少有一列
        if !campaigns.waitUntilReady() {
            failWithDiagnostics(in: app, "儲存後開團列表根 identifier「\(campaigns.rootIdentifier)」逾時仍未出現")
        }

        let prefix = BLAccessibilityID.Campaigns.row(campaignID: "")
        let anyCampaignRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .firstMatch
        if !anyCampaignRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "建立開團後列表仍無任何開團列")
        }
    }

    /// 刪除流程：更多 → 刪除 → 確認 alert → 取消；alert 收回且開團未被刪除
    @MainActor
    func testDeleteFlowCancelKeepsCampaign() {
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = openCampaignDetail(app, campaignID: Self.koreaCampaignID)

        detail.openMoreMenu()
        if !detail.tapDelete() {
            failWithDiagnostics(in: app, "更多選單的刪除項目未出現或不可點")
        }

        if !detail.deleteConfirmExists() {
            failWithDiagnostics(in: app, "點刪除後，刪除確認 alert 未呈現")
        }

        detail.cancelDelete()

        // 取消後 alert 應收回，且開團未被刪除、詳情仍停留
        if !detail.confirmationDismissed() {
            failWithDiagnostics(in: app, "點取消後，刪除確認 alert 未收回")
        }
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消刪除後詳情頁應仍停留，根 identifier 卻消失")
        }
    }
}

// MARK: - Private Method

private extension CampaignCrudTests {

    /// 切到開團分頁、點指定開團進詳情並等就緒，回傳詳情 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - campaignID: 要進入詳情的開團 id
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的開團詳情 Page Object
    @MainActor
    func openCampaignDetail(
        _ app: XCUIApplication,
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CampaignDetailScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒", file: file, line: line)
        }

        let campaigns = CampaignsScreen(app: app)
        if !campaigns.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "開團列表根 identifier「\(campaigns.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        campaigns.tapCampaign(campaignID: campaignID)

        let detail = CampaignDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點開團「\(campaignID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return detail
    }
}
