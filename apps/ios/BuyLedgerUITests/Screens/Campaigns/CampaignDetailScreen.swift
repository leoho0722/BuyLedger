//
//  CampaignDetailScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情頁的 Page Object
struct CampaignDetailScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Screen

extension CampaignDetailScreen: Screen {

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.detailRoot
    }
}
