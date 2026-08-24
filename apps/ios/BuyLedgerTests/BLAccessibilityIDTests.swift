//
//  BLAccessibilityIDTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證 identifier 常數的組成規則
struct BLAccessibilityIDTests {
    
    // MARK: - Tests
    
    @Test func optionJoinsPrefixAndRawValueWithDot() {
        #expect(
            BLAccessibilityID.option("orders.list.statusChip", key: "shipping")
                == "orders.list.statusChip.shipping")
    }
    
    @Test func rowSeparatesBusinessKeyWithColon() {
        #expect(
            BLAccessibilityID.row("orders.list.row", key: "ORD-2026-0007")
                == "orders.list.row:ORD-2026-0007")
    }
    
    @Test func indexedAppendsZeroBasedPosition() {
        #expect(
            BLAccessibilityID.indexed("orderEdit.photo.thumbnail", index: 2)
                == "orderEdit.photo.thumbnail.index.2")
    }
    
    @Test func tabIdentifierUsesTabKeyRawValue() {
        #expect(BLAccessibilityID.Root.tab(.insights) == "root.tab.insights")
    }
    
    @Test func kpiTileIdentifierUsesKPIKeyRawValue() {
        #expect(BLAccessibilityID.Dashboard.kpiTile(.revenue) == "dashboard.kpiTile.revenue")
        #expect(BLAccessibilityID.Dashboard.kpiTile(.netProfit) == "dashboard.kpiTile.netProfit")
    }
    
    @Test func loadFailureRetryButtonDerivesFromItsContainer() {
        #expect(BLAccessibilityID.Common.loadFailure("orders") == "orders.loadFailure")
        #expect(
            BLAccessibilityID.Common.loadFailureRetryButton("orders")
                == "orders.loadFailure.retryButton")
    }
    
    @Test func dashboardStateIdentifiersReuseTheCommonFeaturePrefix() {
        #expect(BLAccessibilityID.Dashboard.loading == "dashboard.loading")
        #expect(BLAccessibilityID.Dashboard.loadFailure == "dashboard.loadFailure")
        #expect(
            BLAccessibilityID.Dashboard.loadFailureRetryButton
                == "dashboard.loadFailure.retryButton")
    }
    
    @Test(arguments: [
        BLAccessibilityID.Root.sidebar,
        BLAccessibilityID.Dashboard.root,
        BLAccessibilityID.Dashboard.emptyState,
        BLAccessibilityID.Settings.languagePicker,
        BLAccessibilityID.Settings.monthlyGoalField,
        BLAccessibilityID.Common.keyboardDoneButton,
    ])
    func staticIdentifiersAreASCIIOnly(_ identifier: String) {
        let isASCIIOnly = identifier.unicodeScalars.allSatisfy { $0.isASCII }
        
        #expect(isASCIIOnly)
        #expect(!identifier.isEmpty)
    }
    
    @Test func everyTabKeyHasAMatchingAppTab() {
        // 兩邊的 case 集合必須一致，否則 App 端的窮舉對應會漏掉分頁
        let appKeys = Set(RootTab.allCases.map(\.accessibilityKey.rawValue))
        let catalogKeys: Set<String> = ["dashboard", "orders", "campaigns", "insights", "more"]
        
        #expect(appKeys == catalogKeys)
    }
}
