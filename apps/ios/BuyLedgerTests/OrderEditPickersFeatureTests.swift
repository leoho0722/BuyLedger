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

/// 驗證選項子功能的新增請求與父層草稿套用，新增請求完成前不改動清單與草稿
@MainActor
struct OrderEditPickersFeatureTests {

    /// 子層只送出整理後的新增請求，清單維持原值
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

    /// 父層接收新增請求時保留草稿，僅轉送對外 delegate
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
