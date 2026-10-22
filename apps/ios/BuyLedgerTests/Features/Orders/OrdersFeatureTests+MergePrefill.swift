//
//  OrdersFeatureTests+MergePrefill.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 合併確認開啟的表單帶著預填內容與照片，未改動時按取消直接關閉
    ///
    /// - Throws: 合併確認表單不存在時由 `#require` 丟出
    @Test
    func presentation_合併預填草稿未修改_取消直接關閉() async throws {
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
        let edit = try #require(store.state.presentation.destination?.edit)

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.cancelTapped))))))

        // Then
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.finish()
        #expect(!edit.isDirty)
        #expect(edit.isMergeContext)
        #expect(edit.draft.customerName == "測試客戶")
        #expect(edit.draft.chargedAmount == 1_500)
        #expect(edit.initialDraft == fixture.expected.draft)
        #expect(edit.mergeSourceIDs == ["PRIMARY", "SECONDARY"])
        #expect(edit.photos.draftPhotos == [Data([2])])
        #expect(edit.photos.photoLoadPhase == .loaded)
        #expect(!edit.photos.hasEditedPhotos)
        #expect(!edit.isCardlessDeductionCapped)
        #expect(store.state.presentation.destination?.edit == nil)
        #expect(store.state.orders == fixture.orders)
    }

    /// 合併確認開啟後，改了客戶名稱才算有未儲存的變更
    ///
    /// - Throws: 合併確認表單不存在時由 `#require` 丟出
    @Test
    func presentation_合併確認修改顧客名稱_才判定已修改() async throws {
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
        let opened = try #require(store.state.presentation.destination?.edit)
        var changed = opened.draft
        changed.customerName = "更名客戶"

        // When
        await store.send(
            .presentation(.destination(.presented(.edit(.binding(.set(\.draft, changed))))))
        ) {
            $0.presentation.destination?.modify(\.edit) {
                $0.draft = changed
            }
        }

        // Then
        #expect(!opened.isDirty)
        #expect(store.state.presentation.destination?.edit?.isDirty == true)
        #expect(store.state.presentation.destination?.edit?.draft.customerName == "更名客戶")
        #expect(store.state.presentation.destination?.edit?.initialDraft.customerName == "測試客戶")
        #expect(store.state.presentation.destination?.edit?.photos.draftPhotos == [Data([2])])
        #expect(store.state.presentation.destination?.edit?.photos.hasEditedPhotos == false)
    }
}

// MARK: - Nested Types

private extension OrdersFeatureTests {

    /// 合併預填測試的起始狀態、初始訂單與預期表單
    struct MergePrefillFixture {

        /// 放入兩筆待合併訂單的訂單分頁初始狀態
        let initial: OrdersFeature.State

        /// 放入初始狀態的兩筆訂單，斷言訂單未被改動時比對
        let orders: [LedgerOrder]

        /// 金額寫死為 1,500、帶著預填內容與保留照片的預期表單狀態
        let expected: OrderEditFeature.State
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 建立兩筆韓圓訂單與金額寫死的預期表單，預期表單不由合併結果算出
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
        var expectedDraft = OrderDraft(original: primary, currentDate: TestDependencies.fixedNow)
        expectedDraft.chargedAmount = 1_500
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
