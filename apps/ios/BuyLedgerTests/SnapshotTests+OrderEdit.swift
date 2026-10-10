//
//  SnapshotTests+OrderEdit.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 編輯既有訂單時，表單帶入第一筆範例訂單的內容
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
    @Test
    func orderEditView_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            var state = OrderEditFeature.State(
                original: LedgerOrder.sampleOrders[0],
                id: UUID(0),
                options: OrderEditOptions(calendar: try Self.makeOrderEditCalendar()),
                currentDate: TestDependencies.fixedNow
            )
            // 選項在建立表單時帶入；key window 渲染仍會執行照片子 Feature 的 `.task`
            // 先標記照片已載入，避免快照測試讀取照片服務
            state.photos.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 編輯合併產生的訂單時，商品類別與開團欄位把多個值以「、」串接顯示
    ///
    /// - Throws: 範例訂單沒有合併訂單或 `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
    @Test
    func orderEditView_合併訂單情境_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let mergedOrder = try #require(
                LedgerOrder.sampleOrders.first {
                    !$0.mergedSourceIDs.isEmpty
                }
            )
            var state = OrderEditFeature.State(
                original: mergedOrder,
                id: UUID(0),
                options: OrderEditOptions(calendar: try Self.makeOrderEditCalendar()),
                currentDate: TestDependencies.fixedNow
            )
            // 選項在建立表單時帶入；key window 渲染仍會執行照片子 Feature 的 `.task`
            // 先標記照片已載入，避免快照測試讀取照片服務
            state.photos.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 訂單編號很長時，編輯表單版面不被撐壞，短版識別碼 (`displayID`) 也依規則截短
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 截圖只守住表單可見部分，「原始訂單」段不在截圖範圍內
    /// - Note: 短識別碼的截短規則由下方的 `#expect` 守住
    /// - Note: 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
    @Test
    func orderEditView_長訂單識別碼_顯示短識別碼() throws {
        try TestDependencies.withFixedNow {
            // Given
            let longIDOrder = LedgerOrder(
                id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
                customer: LedgerCustomer(name: "長編號測試", initials: "LI", tier: .regular),
                status: .quoting,
                currency: .twd,
                date: TestDependencies.fixedNow,
                items: [LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 1_000)],
                itemCost: 600,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 1_000,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "蝦皮",
                categories: ["美妝"],
                paymentMethod: "信用卡",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
            var state = OrderEditFeature.State(
                original: longIDOrder,
                id: UUID(0),
                options: OrderEditOptions(calendar: try Self.makeOrderEditCalendar()),
                currentDate: TestDependencies.fixedNow
            )
            // 選項在建立表單時帶入；key window 渲染仍會執行照片子 Feature 的 `.task`
            // 先標記照片已載入，避免快照測試讀取照片服務
            state.photos.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            #expect(longIDOrder.displayID == "BL-DRAFT-000000")
        }
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立時區固定為 `Asia/Taipei` 的西曆，供表單的完整時間格式化使用
    ///
    /// - Returns: 時區明確設為 `Asia/Taipei` 的西曆
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeOrderEditCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Taipei"))
        return calendar
    }
}
