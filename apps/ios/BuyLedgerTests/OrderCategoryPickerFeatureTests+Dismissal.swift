//
//  OrderCategoryPickerFeatureTests+Dismissal.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderCategoryPickerFeatureTests {

    /// 只改呈現狀態時取消不詢問，直接委派關閉
    @Test
    func cancelTapped_只改搜尋焦點與展開_直接委派取消() async {
        // Given
        var state = Self.makeState(committed: ["beauty"])
        state.searchText = "boo"
        state.isSearchFieldFocused = true
        state.groupExpansion.expandedKinds = [.closed]
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped))

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.discardConfirmation == nil)
        #expect(store.state.pendingCategories == ["beauty"])
    }

    /// 有變更時取消呈現同一組捨棄文案，不先改暫存或提交
    @Test
    func cancelTapped_暫存新增書籍_先詢問捨棄且保留集合() async {
        // Given
        var state = Self.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        let confirmation = Self.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped)) {
            $0.discardConfirmation = confirmation
        }

        // Then
        #expect(store.state.pendingCategories == ["beauty", "books"])
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.discardConfirmation == confirmation)
    }

    /// 類別筆數相同但內容不同時仍詢問，避免只比較數量而靜默捨棄
    @Test
    func cancelTapped_暫存改為另一類別_先詢問捨棄且保留集合() async {
        // Given
        var state = Self.makeState(committed: ["beauty"])
        state.pendingCategories = ["books"]
        let confirmation = Self.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped)) {
            $0.discardConfirmation = confirmation
        }

        // Then
        #expect(store.state.pendingCategories == ["books"])
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.hasUnappliedChanges == true)
    }

    /// 確認捨棄恢復目前比較基準，並委派關閉
    @Test
    func discardConfirmation_確認捨棄變更_還原集合並委派取消() async {
        // Given
        var state = Self.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        state.discardConfirmation = Self.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
            $0.pendingCategories = ["beauty"]
        }

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.hasUnappliedChanges == false)
    }

    /// 關閉確認繼續編輯保留暫存，不委派取消
    @Test
    func discardConfirmation_繼續編輯_保留暫存且不提交() async {
        // Given
        var state = Self.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        state.discardConfirmation = Self.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.discardConfirmation(.dismiss)) {
            $0.discardConfirmation = nil
        }

        // Then
        #expect(store.state.pendingCategories == ["beauty", "books"])
        #expect(store.state.committedCategories == ["beauty"])
    }

    /// 選回原本集合後取消不再詢問，也不送出套用
    @Test
    func cancelTapped_暫存已回到原集合_直接委派取消() async {
        // Given
        let store = TestStore(initialState: Self.makeState(committed: ["snacks"])) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped))

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.discardConfirmation == nil)
        #expect(store.state.pendingCategories == ["snacks"])
    }
}
