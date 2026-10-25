//
//  OrderEditFeatureCategoriesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 TestStore 逐步驗證分類選擇器的選取、切換、新增請求與推入
@MainActor
struct OrderEditFeatureCategoriesTests {

    /// 驗證選取分類時，草稿原有的多個分類被所選的新分類取代，只留下新分類
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

    /// 驗證切換分類時，未選取的分類附加到清單末端，已選取的分類移除，其餘選取維持不變
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

    /// 驗證合併草稿與新訂單情境新增分類時，落盤前分類選項與草稿都保持原值，請求依序由選擇器與編輯表單送往上層
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    /// - Throws: `OrderEditFeatureTestSupport.makeState(for:)` 只在 `mergedResult` 情境找不到樣本時丟出，
    ///   本測試的兩個情境不會觸發
    @Test(arguments: [
        AddCategoryScenarioCase(scenario: .mergeDraft, expected: ["美妝"]),
        AddCategoryScenarioCase(scenario: .newOrder, expected: ["美妝"]),
    ])
    func pickers_合併或一般情境新增分類_尚未落盤時保留原選取(testCase: AddCategoryScenarioCase) async throws {
        // Given
        var initial = try OrderEditFeatureTestSupport.makeState(for: testCase.scenario)
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
        #expect(store.state.draft.categories == testCase.expected)
    }

    /// 驗證尚未開啟選擇器時，點選分類按鈕會推入分類選擇器，並把 `pickerRoute` 設為 `.category`
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

// MARK: - Nested Types

extension OrderEditFeatureCategoriesTests {

    /// 新增分類請求的訂單情境與預期選取
    struct AddCategoryScenarioCase: Sendable {

        /// 要建立的訂單起始情境
        let scenario: OrderEditFeatureTestSupport.EditScenario

        /// 收到請求後預期保留的分類
        let expected: [String]
    }

    /// 分類切換測試使用的輸入與預期結果
    struct CategoryToggleCase: Sendable {

        /// 送出 action 前已選取的分類
        let initialCategories: [String]

        /// 要切換的分類
        let category: String

        /// 切換後預期保留的分類
        let expected: [String]
    }
}
