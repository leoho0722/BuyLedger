//
//  RootFeatureTests+DefaultCurrency.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 在訂單分頁開新訂單時，表單以預設的日圓建立；幣別算作初始內容，表單不算已修改
    @Test
    func orders_預設日圓開新訂單_草稿為日圓且未修改() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.defaultCurrency = .jpy
        var initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        initial.selectedTab = .orders
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.create))))) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
                    currentDate: TestDependencies.fixedNow,
                    defaultCurrency: .jpy
                )
            )
        }

        // Then
        #expect(store.state.orders.defaultCurrency == .jpy)
        #expect(store.state.orders.presentation.destination?.edit?.draft.currency == .jpy)
        #expect(store.state.orders.presentation.destination?.edit?.initialDraft.currency == .jpy)
        #expect(store.state.orders.presentation.destination?.edit?.isDirty == false)
    }

    /// 在總覽頁按新增訂單時，根功能套用預設日圓；初始表單不算已修改
    @Test
    func dashboard_預設日圓開新訂單_草稿為日圓且未修改() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.defaultCurrency = .jpy
        let initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped))) {
            $0.selectedTab = .orders
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
                    currentDate: TestDependencies.fixedNow,
                    defaultCurrency: .jpy
                )
            )
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.presentation.destination?.edit?.draft.currency == .jpy)
        #expect(store.state.orders.presentation.destination?.edit?.initialDraft.currency == .jpy)
        #expect(store.state.orders.presentation.destination?.edit?.isDirty == false)
    }

    /// 編輯既有韓圓訂單時，表單沿用訂單原幣別，不受預設日圓影響
    @Test
    func orders_預設日圓編輯既有韓圓訂單_保留韓圓() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.defaultCurrency = .jpy
        let primary = LedgerOrder.fixture(
            id: "PRIMARY",
            currency: .krw,
            date: TestDependencies.fixedNow,
            orderSource: "",
            paymentMethod: ""
        )
        let secondary = LedgerOrder.fixture(
            id: "SECONDARY",
            currency: .krw,
            date: TestDependencies.fixedNow,
            orderSource: "",
            paymentMethod: ""
        )
        let initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        initial.orders.$orders.withLock {
            $0 = [primary, secondary]
        }
        let options = OrderEditOptions(calendar: TestDependencies.fixedCalendar)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.edit("PRIMARY")))))) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    original: primary,
                    id: UUID(0),
                    options: options,
                    currentDate: TestDependencies.fixedNow,
                    defaultCurrency: .jpy
                )
            )
        }

        // Then
        #expect(store.state.orders.presentation.destination?.edit?.draft.currency == .krw)
        #expect(store.state.orders.presentation.destination?.edit?.initialDraft.currency == .krw)
        #expect(store.state.orders.presentation.destination?.edit?.isDirty == false)
    }

    /// 合併確認韓圓訂單時，合併表單沿用原幣別，不受預設日圓影響
    @Test
    func orders_預設日圓合併確認韓圓訂單_保留韓圓() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.defaultCurrency = .jpy
        let primary = LedgerOrder.fixture(
            id: "PRIMARY",
            currency: .krw,
            date: TestDependencies.fixedNow,
            orderSource: "",
            paymentMethod: ""
        )
        let secondary = LedgerOrder.fixture(
            id: "SECONDARY",
            currency: .krw,
            date: TestDependencies.fixedNow,
            orderSource: "",
            paymentMethod: ""
        )
        let initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        initial.orders.$orders.withLock {
            $0 = [primary, secondary]
        }
        let options = OrderEditOptions(calendar: TestDependencies.fixedCalendar)
        let merge = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: TestDependencies.fixedNow,
            isCardless: { _ in false }
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(
            .orders(.presentation(.delegate(.mergeConfirmationDue(draft: merge, keptPhotos: []))))
        ) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: options,
                    currentDate: TestDependencies.fixedNow,
                    defaultCurrency: .jpy,
                    prefill: OrderEditFeature.State.Prefill(
                        draft: OrderDraft(
                            original: primary,
                            currentDate: TestDependencies.fixedNow
                        ),
                        mergeSourceIDs: ["PRIMARY", "SECONDARY"],
                        keptPhotos: []
                    )
                )
            )
        }

        // Then
        #expect(store.state.orders.presentation.destination?.edit?.draft.currency == .krw)
        #expect(store.state.orders.presentation.destination?.edit?.initialDraft.currency == .krw)
        #expect(store.state.orders.presentation.destination?.edit?.isDirty == false)
        #expect(store.state.orders.orders.map(\.currency) == [.krw, .krw])
    }

    /// 改預設幣別時，已開啟的草稿與既有訂單維持新台幣，不受新的預設值影響
    @Test
    func more_改預設幣別時已開草稿_維持原幣別() async {
        // Given
        let existing = LedgerOrder.fixture(currency: .twd, orderSource: "", paymentMethod: "")
        let options = OrderEditOptions(calendar: TestDependencies.fixedCalendar)
        var initial = Self.makeIsolatedRootState()
        initial.orders.$orders.withLock {
            $0 = [existing]
        }
        initial.orders.presentation.destination = .edit(
            OrderEditFeature.State(
                id: UUID(1),
                options: options,
                currentDate: TestDependencies.fixedNow
            )
        )
        var preferences = SettingsSnapshot.default
        preferences.defaultCurrency = .jpy
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.more(.delegate(.preferencesChanged(preferences)))) {
            $0.preferences = preferences
            $0.more.preferences = preferences
            $0.orders.defaultCurrency = .jpy
        }

        // Then
        #expect(store.state.orders.presentation.destination?.edit?.draft.currency == .twd)
        #expect(store.state.orders.presentation.destination?.edit?.isDirty == false)
        #expect(store.state.orders.orders == [existing])
        #expect(store.state.orders.orders.first?.currency == .twd)
    }

    /// 改預設幣別後開新訂單，新表單以新的預設幣別建立，既有訂單維持新台幣
    @Test
    func orders_預設改為日圓後開新訂單_只影響之後的新草稿() async {
        // Given
        let existing = LedgerOrder.fixture(currency: .twd, orderSource: "", paymentMethod: "")
        let options = OrderEditOptions(calendar: TestDependencies.fixedCalendar)
        var preferences = SettingsSnapshot.default
        preferences.defaultCurrency = .jpy
        var initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        initial.orders.$orders.withLock {
            $0 = [existing]
        }
        initial.orders.presentation.destination = .edit(
            OrderEditFeature.State(
                id: UUID(1),
                options: options,
                currentDate: TestDependencies.fixedNow
            )
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.create))))) {
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: options,
                    currentDate: TestDependencies.fixedNow,
                    defaultCurrency: .jpy
                )
            )
        }

        // Then
        #expect(store.state.orders.presentation.destination?.edit?.draft.currency == .jpy)
        #expect(store.state.orders.presentation.destination?.edit?.isDirty == false)
        #expect(store.state.orders.orders == [existing])
        #expect(store.state.orders.orders.first?.currency == .twd)
    }
}
