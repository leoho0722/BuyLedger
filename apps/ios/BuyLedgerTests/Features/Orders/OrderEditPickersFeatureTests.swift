//
//  OrderEditPickersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditPickersFeature` 與 `OrderEditFeature` 的單元測試，涵蓋新增選項請求與完成前的清單、草稿維持原值
@MainActor
struct OrderEditPickersFeatureTests {

    /// 驗證分類輸入的首尾空白與換行去除後送出新增請求，清單維持原值
    @Test
    func addCategoryTapped_子層新增選項_保留清單並送出寫入請求() async {
        // Given
        let draft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        let initial = OrderEditPickersFeature.State(
            options: OrderEditOptions(categories: ["A"], calendar: TestDependencies.fixedCalendar),
            draft: draft
        )
        let store = TestStore(initialState: initial) {
            OrderEditPickersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.addCategoryTapped(" B \n")))

        // Then
        await store.receive(
            \.delegate,
            .addOptionRequested(kind: .category, name: "B", flags: .none)
        )
        #expect(store.state.options.categories == ["A"])
    }

    /// 驗證選項選擇器送來新增分類的請求時，編輯表單保留清單與草稿，只把請求原樣送出
    @Test
    func pickers_子層新增分類_保留清單草稿並轉送主檔請求() async {
        // Given
        var initial = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(categories: ["A"], calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )
        initial.draft.categories = ["A"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.addCategoryTapped("B"))))

        // Then
        await store.receive(
            \.pickers.delegate,
            .addOptionRequested(kind: .category, name: "B", flags: .none)
        )
        await store.receive(
            \.delegate,
            .addOptionRequested(kind: .category, name: "B", flags: .none)
        )
        #expect(store.state.pickers.options.categories == ["A"])
        #expect(store.state.draft.categories == ["A"])
    }
}
