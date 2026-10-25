//
//  OrdersFeatureMergePrefillTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證合併草稿的預填欄位與未儲存變更判斷
@MainActor
struct OrdersFeatureMergePrefillTests {

    /// 驗證合併確認表單帶著預填內容與照片開啟，未改動時按取消會直接關閉
    @Test
    func presentation_合併預填草稿未修改_取消直接關閉() async {
        // Given
        let fixture = Self.makeMergePrefillFixture()
        var initial = fixture.initial
        initial.presentation.destination = .edit(fixture.expected)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.cancelTapped))))))

        // Then
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.finish()
        #expect(store.state.presentation.destination?.edit == nil)
        #expect(store.state.orders == fixture.orders)
    }

    /// 驗證合併確認表單經畫面綁定修改客戶名稱後才判定為已修改，保留的照片不計為變更
    ///
    /// - Throws: 合併確認的編輯表單未呈現時由 `#require` 丟出測試斷言錯誤
    @Test
    func presentation_合併確認修改顧客名稱_才判定已修改() throws {
        // Given
        let fixture = Self.makeMergePrefillFixture()
        var initial = fixture.initial
        initial.presentation.destination = .edit(fixture.expected)
        let store = Store(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)
        let editStore = try #require(
            $presentation.scope(state: \.$destination, action: \.destination).edit.wrappedValue
        )
        @Bindable var edit = editStore

        // When
        $edit.draft.customerName.wrappedValue = "更名客戶"

        // Then
        #expect(store.state.presentation.destination?.edit?.isDirty == true)
        #expect(store.state.presentation.destination?.edit?.draft.customerName == "更名客戶")
        #expect(store.state.presentation.destination?.edit?.initialDraft.customerName == "測試客戶")
        #expect(store.state.presentation.destination?.edit?.photos.draftPhotos == [Data([2])])
        #expect(store.state.presentation.destination?.edit?.photos.hasEditedPhotos == false)
    }
}

// MARK: - Nested Types

private extension OrdersFeatureMergePrefillTests {

    /// 合併預填測試的起始狀態、初始訂單與預期表單
    struct MergePrefillFixture {

        /// 放入兩筆待合併訂單的訂單分頁初始狀態
        let initial: OrdersFeature.State

        /// 初始狀態放入的兩筆訂單 (斷言訂單未被改動時比對)
        let orders: [LedgerOrder]

        /// 金額為字面值 1,500、帶著預填內容與保留照片的預期表單狀態
        let expected: OrderEditFeature.State
    }
}

// MARK: - Private Method

private extension OrdersFeatureMergePrefillTests {

    /// 建立兩筆韓圓訂單與金額為字面值的預期表單，預期表單不由合併結果算出
    ///
    /// - Returns: 訂單分頁初始狀態、初始訂單與預期的表單狀態
    static func makeMergePrefillFixture() -> MergePrefillFixture {
        let primary = LedgerOrder.fixture(
            id: "PRIMARY",
            currency: .krw,
            date: TestDependencies.fixedNow,
            chargedAmount: 1_200,
            orderSource: "",
            paymentMethod: "",
            photos: [Data([1])]
        )
        let secondary = LedgerOrder.fixture(
            id: "SECONDARY",
            currency: .krw,
            date: TestDependencies.fixedNow,
            chargedAmount: 300,
            orderSource: "",
            paymentMethod: "",
            photos: [Data([2])]
        )
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        let orders = [primary, secondary]
        initial.$orders.withLock {
            $0 = orders
        }
        var expectedDraft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        expectedDraft.customerName = "測試客戶"
        expectedDraft.orderSource = ""
        expectedDraft.categories = []
        expectedDraft.status = .confirmed
        expectedDraft.currency = .krw
        expectedDraft.chargedAmount = 1_500
        expectedDraft.cardlessDeductionAmount = 0
        expectedDraft.cardlessSupplementAmount = 0
        expectedDraft.itemCost = 0
        expectedDraft.domesticShipping = 0
        expectedDraft.internationalShipping = 0
        expectedDraft.foreignDomesticShipping = 0
        expectedDraft.cardFeeRate = 0
        expectedDraft.platformFeeRate = 0
        expectedDraft.paymentFeeRate = 0
        expectedDraft.items = []
        expectedDraft.notes = ""
        expectedDraft.date = TestDependencies.fixedNow
        expectedDraft.paymentMethod = ""
        expectedDraft.reconciliationStatus = ""
        expectedDraft.campaignNames = []
        expectedDraft.paymentReceiptStatus = .pending
        let expected = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow,
            prefill: OrderEditFeature.State.Prefill(
                draft: expectedDraft,
                mergeSourceIDs: ["PRIMARY", "SECONDARY"],
                keptPhotos: [Data([2])]
            )
        )
        return MergePrefillFixture(initial: initial, orders: orders, expected: expected)
    }
}
