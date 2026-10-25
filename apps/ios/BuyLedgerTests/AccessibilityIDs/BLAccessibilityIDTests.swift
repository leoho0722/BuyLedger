//
//  BLAccessibilityIDTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation
import Testing

@testable import BuyLedger

/// `BLAccessibilityID` 的單元測試
struct BLAccessibilityIDTests {

    /// 驗證 `option` 把鍵值原樣接在前綴後，中間以點號分隔
    @Test
    func option_給定前綴與鍵值_以點號串接() {
        // Given
        let prefix: String = "orders.list.statusChip"
        let key: String = "shipping"

        // When
        let identifier = BLAccessibilityID.option(prefix, key: key)

        // Then
        #expect(identifier == "orders.list.statusChip.shipping")
    }

    /// 驗證 `row` 把業務鍵原樣接在前綴後，中間以冒號分隔
    @Test
    func row_給定前綴與業務鍵_以冒號分隔() {
        // Given
        let prefix: String = "orders.list.row"
        let key: String = "ORD-2026-0007"

        // When
        let identifier = BLAccessibilityID.row(prefix, key: key)

        // Then
        #expect(identifier == "orders.list.row:ORD-2026-0007")
    }

    /// 驗證 `indexed` 在前綴後接上 index 段與從零起算的索引值
    @Test
    func indexed_給定前綴與索引_附加從零起算的位置() {
        // Given
        let prefix: String = "orderEdit.photo.thumbnail"
        let index: Int = 2

        // When
        let identifier = BLAccessibilityID.indexed(prefix, index: index)

        // Then
        #expect(identifier == "orderEdit.photo.thumbnail.index.2")
    }

    /// 驗證分頁識別碼的前綴固定為根導覽，後接分頁鍵的原始值
    @Test
    func tab_分頁鍵_使用原始值組成識別碼() {
        // Given

        // When
        let identifier = BLAccessibilityID.Root.tab(.insights)

        // Then
        #expect(identifier == "root.tab.insights")
    }

    /// 驗證營收與淨利的 KPI 格識別碼，分別以各鍵的原始值接在總覽前綴後
    ///
    /// - Parameter scenario: KPI 鍵與預期的完整識別碼
    @Test(arguments: [
        KPIIdentifierCase(key: .revenue, expectedIdentifier: "dashboard.kpiTile.revenue"),
        KPIIdentifierCase(key: .netProfit, expectedIdentifier: "dashboard.kpiTile.netProfit"),
    ])
    func kpiTile_KPI鍵_使用原始值組成識別碼(scenario: KPIIdentifierCase) {
        // Given

        // When
        let identifier = BLAccessibilityID.Dashboard.kpiTile(scenario.key)

        // Then
        #expect(identifier == scenario.expectedIdentifier)
    }

    /// 驗證訂單容器的載入失敗區塊識別碼，在容器前綴後接上失敗區域
    @Test
    func loadFailure_容器識別碼_附加載入失敗區域() {
        // Given

        // When
        let loadFailure = BLAccessibilityID.Common.loadFailure("orders")

        // Then
        #expect(loadFailure == "orders.loadFailure")
    }

    /// 驗證訂單容器的重試鈕識別碼，接在該容器的載入失敗區域後
    @Test
    func loadFailureRetryButton_容器識別碼_附加重試按鈕區域() {
        // Given

        // When
        let retryButton = BLAccessibilityID.Common.loadFailureRetryButton("orders")

        // Then
        #expect(retryButton == "orders.loadFailure.retryButton")
    }

    /// 驗證總覽的載入中區塊識別碼，使用固定的總覽前綴
    @Test
    func loading_總覽載入中_使用總覽前綴() {
        // Given

        // When
        let loading = BLAccessibilityID.Dashboard.loading

        // Then
        #expect(loading == "dashboard.loading")
    }

    /// 驗證總覽的載入失敗區塊識別碼，在總覽前綴後接上失敗區域
    @Test
    func loadFailure_總覽載入失敗_使用總覽前綴() {
        // Given

        // When
        let loadFailure = BLAccessibilityID.Dashboard.loadFailure

        // Then
        #expect(loadFailure == "dashboard.loadFailure")
    }

    /// 驗證總覽的重試鈕識別碼，接在總覽的載入失敗區域後
    @Test
    func loadFailureRetryButton_總覽重試按鈕_接在失敗區域後() {
        // Given

        // When
        let loadFailureRetryButton = BLAccessibilityID.Dashboard.loadFailureRetryButton

        // Then
        #expect(loadFailureRetryButton == "dashboard.loadFailure.retryButton")
    }

    /// 驗證每個靜態識別碼都只含 ASCII 字元且不為空
    ///
    /// - Parameter identifier: 要檢查的靜態識別碼
    @Test(arguments: [
        BLAccessibilityID.Root.sidebar,
        BLAccessibilityID.Dashboard.root,
        BLAccessibilityID.Dashboard.emptyState,
        BLAccessibilityID.Settings.languagePicker,
        BLAccessibilityID.Settings.monthlyGoalField,
        BLAccessibilityID.Common.keyboardDoneButton,
    ])
    func staticIdentifiers_靜態識別碼_皆為ASCII字元(_ identifier: String) {
        // Given

        // When
        let isASCIIOnly = identifier.unicodeScalars.allSatisfy { $0.isASCII }

        // Then
        #expect(isASCIIOnly)
        #expect(!identifier.isEmpty)
    }

    /// 驗證 `RootTab` 的無障礙分頁鍵與測試端的分頁目錄完全相同，新增或改名分頁時此測試會轉紅
    @Test
    func accessibilityKey_每個分頁鍵_皆有對應的App分頁() {
        // Given
        let catalogKeys: Set<String> = ["dashboard", "orders", "campaigns", "insights", "more"]

        // When
        let appKeys = Set(RootTab.allCases.map(\.accessibilityKey.rawValue))

        // Then
        #expect(appKeys == catalogKeys)
    }
}

// MARK: - Nested Types

extension BLAccessibilityIDTests {

    /// KPI 識別碼案例，將鍵與固定的完整預期配對
    struct KPIIdentifierCase: Sendable {

        /// 用來組成識別碼的總覽 KPI 鍵
        let key: BLAccessibilityID.Dashboard.KPI

        /// 對應該鍵的完整識別碼
        let expectedIdentifier: String
    }
}
