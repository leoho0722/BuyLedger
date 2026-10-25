//
//  OrderEditFeatureDatesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋日期選擇器保留注入的秒數，以及回到初始值時的修改判定
@MainActor
struct OrderEditFeatureDatesTests {

    /// 驗證重選與開啟時同一分鐘的時間時，草稿維持開啟時的日期，不寫入注入時間的非零秒數，也不標記為修改
    ///
    /// - Parameter pickedTimestamp: 同一分鐘內的選擇器時間戳
    @Test(arguments: [1_777_213_800.0, 1_777_213_837.0])
    func dateComponentsChanged_重選同分鐘且注入秒數非零_草稿不變且未修改(pickedTimestamp: TimeInterval) async {
        // Given
        let initialDate = Date(timeIntervalSince1970: 1_777_213_800) // 2026-04-26 14:30:00 UTC
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: initialDate)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow.addingTimeInterval(37))
        }

        // When
        await store.send(
            .view(.dateComponentsChanged(Date(timeIntervalSince1970: pickedTimestamp)))
        )

        // Then
        #expect(store.state.draft == initial.draft)
        #expect(store.state.draft.date == Date(timeIntervalSince1970: 1_777_213_800))
        #expect(store.state.isDirty == false)
    }

    /// 驗證日期選擇器先轉到別的分鐘再選回開啟時的分鐘，草稿恢復開啟時的日期，且不算修改
    @Test
    func dateComponentsChanged_轉走再選回開啟時的分鐘_恢復開啟時的值且未修改() async {
        // Given
        let initialDate = Date(timeIntervalSince1970: 1_777_213_800) // 2026-04-26 14:30:00 UTC
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: initialDate)
        let openedDraft = initial.draft
        // 已轉走到 14:31:37，秒數取自注入時間的 37
        initial.draft.date = Date(timeIntervalSince1970: 1_777_213_897)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow.addingTimeInterval(37))
        }

        // When
        await store.send(
            .view(.dateComponentsChanged(Date(timeIntervalSince1970: 1_777_213_800)))
        ) {
            $0.draft.date = Date(timeIntervalSince1970: 1_777_213_800)
        }

        // Then
        #expect(store.state.draft == openedDraft)
        #expect(store.state.isDirty == false)
    }

    /// 驗證日期選擇器改選另一分鐘時，草稿取所選的分鐘並加上注入時間的秒數，且標記為修改
    @Test
    func dateComponentsChanged_改選另一分鐘_合併注入秒數並標記修改() async {
        // Given
        let initialDate = Date(timeIntervalSince1970: 1_777_213_800) // 2026-04-26 14:30:00 UTC
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: initialDate)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow.addingTimeInterval(37))
        }

        // When
        await store.send(
            .view(.dateComponentsChanged(Date(timeIntervalSince1970: 1_777_213_860)))
        ) {
            $0.draft.date = Date(timeIntervalSince1970: 1_777_213_897)
        }

        // Then
        #expect(store.state.draft.date == Date(timeIntervalSince1970: 1_777_213_897))
        #expect(store.state.isDirty)
    }

    /// 驗證日期選擇器送出新的年月日時分時，草稿取所選的時間，秒數沿用注入時間的 42 秒
    @Test
    func dateComponentsChanged_更新年月日時分_保留注入秒數() async {
        // Given
        let picked = Date(timeIntervalSince1970: 1_781_515_800) // 2026-06-15 09:30:00 UTC
        let expected = Date(timeIntervalSince1970: 1_781_515_842) // 同一分鐘，秒數取自注入時間的 42
        let injectedNow = TestDependencies.fixedNow.addingTimeInterval(42)
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(injectedNow)
        }

        // When
        await store.send(.view(.dateComponentsChanged(picked))) {
            $0.draft.date = expected
        }

        // Then
        #expect(store.state.draft.date == expected)
    }
}
