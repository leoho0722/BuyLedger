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
    @Test
    func orderEditView_一般既有訂單_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = OrderEditFeature.State(
                original: LedgerOrder.sampleOrders[0],
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            // 快照不經過 .task，直接標記照片載入完成
            state.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 編輯合併產生的訂單時，商品類別與開團欄位把多個值以「、」串接顯示
    ///
    /// - Throws: 範例訂單沒有合併訂單時由 `#require` 丟出
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
                currentDate: TestDependencies.fixedNow
            )
            // 快照不經過 .task，直接標記照片載入完成
            state.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 訂單編號很長時，編輯表單版面不被撐壞，短版識別碼 (`displayID`) 也依規則截短
    ///
    /// - Note: 截圖守住的是表單可見部分，短識別碼的截短規則由字面值斷言守住，「原始訂單」段不在截圖範圍內
    @Test
    func orderEditView_長訂單識別碼_顯示短識別碼() {
        TestDependencies.withFixedNow {
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
                currentDate: TestDependencies.fixedNow
            )
            // 快照不經過 .task，直接標記照片載入完成
            state.photoLoadPhase = .loaded

            let store = Store(initialState: state) {
                OrderEditFeature()
            }

            // When
            let view = OrderEditView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            // 工具列的 prominent 玻璃按鈕在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            #expect(longIDOrder.displayID == "BL-DRAFT-000000")
        }
    }
}
