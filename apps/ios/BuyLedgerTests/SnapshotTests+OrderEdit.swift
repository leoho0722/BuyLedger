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
            let state = try Self.makeOrderEditSnapshotState(original: LedgerOrder.sampleOrders[0])

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
            let state = try Self.makeOrderEditSnapshotState(original: mergedOrder)

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
            let state = try Self.makeOrderEditSnapshotState(original: longIDOrder)

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

    /// 訂單編輯快照首次或再次出現時，不讀取服務或改變表單內容
    ///
    /// - Parameter shouldRepeatTask: 是否先送過一次表單出現事件
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    @Test(arguments: [false, true])
    func task_訂單編輯快照出現_不啟動服務(shouldRepeatTask: Bool) async throws {
        // Given
        let initialState = try Self.makeOrderEditSnapshotState(
            original: LedgerOrder.sampleOrders[0]
        )
        let store = TestDependencies.withFixedNow {
            TestStore(initialState: initialState) {
                OrderEditFeature()
            }
        }
        if shouldRepeatTask {
            await store.send(.view(.task))
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.finish()
        #expect(store.state == initialState)
        #expect(store.state.photos.photoLoadPhase == .loaded)
    }

    /// 訂單編輯快照的照片區段首次或再次出現時，不重新讀取照片服務
    ///
    /// - Parameter shouldRepeatTask: 是否先送過一次照片區段出現事件
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    @Test(arguments: [false, true])
    func photos_訂單編輯快照照片區段出現_不啟動服務(shouldRepeatTask: Bool) async throws {
        // Given
        let initialState = try Self.makeOrderEditSnapshotState(
            original: LedgerOrder.sampleOrders[0]
        )
        let store = TestDependencies.withFixedNow {
            TestStore(initialState: initialState) {
                OrderEditFeature()
            }
        }
        if shouldRepeatTask {
            await store.send(.photos(.view(.task)))
        }

        // When
        await store.send(.photos(.view(.task)))

        // Then
        await store.finish()
        #expect(store.state == initialState)
        #expect(store.state.photos.photoLoadPhase == .loaded)
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立內容固定且照片已載入的訂單編輯快照，避免區段出現時啟動讀取
    ///
    /// - Parameter original: 快照要顯示的既有訂單
    /// - Returns: 沿用訂單內容、固定時間與已載入照片的表單狀態
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeOrderEditSnapshotState(original: LedgerOrder) throws -> OrderEditFeature.State {
        var state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(calendar: try makeOrderEditCalendar()),
            currentDate: TestDependencies.fixedNow
        )
        // key window 渲染可能觸發照片區段的載入，快照只呈現已備妥的內容
        state.photos.photoLoadPhase = .loaded
        return state
    }

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
