//
//  OrderEditFeatureTests+Categories.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 單選分類時以新分類取代原本的所有選取
    @Test
    func pickers_選取分類且已選多個分類_改為只選新分類() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.categories = ["美妝", "服飾"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.categorySelected("精品"))))

        // Then
        await store.receive(\.pickers.delegate.categorySelected, "精品") {
            $0.draft.categories = ["精品"]
        }
        #expect(store.state.draft.categories == ["精品"])
    }

    /// 分類切換會依初始選取狀態加入或移除分類
    ///
    /// - Parameter testCase: 分類切換的起始選取、切換項目與預期結果
    @Test(arguments: [
        CategoryToggleCase(initialCategories: ["美妝"], category: "服飾", expected: ["美妝", "服飾"]),
        CategoryToggleCase(initialCategories: ["美妝", "服飾"], category: "美妝", expected: ["服飾"]),
    ])
    func pickers_切換分類未選或已選_加入或移除選取(testCase: CategoryToggleCase) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.categories = testCase.initialCategories
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.categoryToggled(testCase.category))))

        // Then
        await store.receive(\.pickers.delegate.categoryToggled, testCase.category) {
            $0.draft.categories = testCase.expected
        }
        #expect(store.state.draft.categories == testCase.expected)
    }

    /// 合併或一般情境的新增請求都必須等持久化成功才套用
    ///
    /// - Parameters:
    ///   - scenario: 要建立的訂單起始情境
    ///   - expected: 收到請求後預期保留的分類
    /// - Throws: `makeState(for:)` 只在 `mergedResult` 情境找不到樣本時丟出，本測試的兩個情境不會觸發
    @Test(arguments: [
        (scenario: EditScenario.mergeDraft, expected: ["美妝"]),
        (scenario: EditScenario.newOrder, expected: ["美妝"]),
    ])
    func pickers_合併或一般情境新增分類_尚未落盤時保留原選取(scenario: EditScenario, expected: [String]) async throws {
        // Given
        var initial = try Self.makeState(for: scenario)
        initial.draft.categories = ["美妝"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.addCategoryTapped("服飾"))))

        // Then
        await store.receive(
            \.pickers.delegate,
            .addOptionRequested(kind: .category, name: "服飾", flags: .none)
        )
        await store.receive(
            \.delegate,
            .addOptionRequested(kind: .category, name: "服飾", flags: .none)
        )
        #expect(store.state.pickers.options.categories == initial.pickers.options.categories)
        #expect(store.state.draft.categories == expected)
    }

    /// 尚未開啟選擇器時，點選分類按鈕會推入分類選擇器
    @Test
    func pickers_點選分類按鈕時尚未開啟選擇器_推入分類選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.categoryPickerTapped))) {
            $0.pickers.pickerRoute = .category
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .category)
    }
}
