//
//  SnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//
//  Snapshot baseline 用於檢查視覺迴歸；第一次跑會自動寫入 baseline，之後改動視覺時若與 baseline 不符會失敗。
//
//  - 圖片檔放在 BuyLedgerTests/__Snapshots__/ （相對於本檔）
//  - 升級設計時請刪掉對應的 baseline 檔案，下次跑測試會自動重建
//

#if canImport(SnapshotTesting) && os(iOS)

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing
@testable import BuyLedger

@MainActor
struct SnapshotTests {

    // MARK: - Tests

    @Test func ordersCompactViewBaseline() {
        let state: OrdersFeature.State = {
            var s = OrdersFeature.State()
            s.orders = LedgerOrder.sampleOrders
            return s
        }()

        let view = OrdersCompactView(
            store: Store(initialState: state) { OrdersFeature() }
        )
        .frame(width: 393, height: 852)

        assertSnapshot(of: view, as: .image)
    }

    @Test func dashboardViewBaseline() {
        let state: RootFeature.State = {
            var s = RootFeature.State()
            s.orders.orders = LedgerOrder.sampleOrders
            return s
        }()

        let view = DashboardView(
            store: Store(initialState: state) { RootFeature() }
        )
        .frame(width: 393, height: 852)

        assertSnapshot(of: view, as: .image)
    }

    @Test func insightsViewBaseline() {
        let state: RootFeature.State = {
            var s = RootFeature.State()
            s.orders.orders = LedgerOrder.sampleOrders
            return s
        }()

        let view = InsightsView(
            store: Store(initialState: state) { RootFeature() }
        )
        .frame(width: 393, height: 852)

        assertSnapshot(of: view, as: .image)
    }

    @Test func orderEditViewBaseline() {
        let state = OrderEditFeature.State(original: LedgerOrder.sampleOrders[0])

        let view = OrderEditView(
            store: Store(initialState: state) { OrderEditFeature() }
        )
        .frame(width: 393, height: 852)

        assertSnapshot(of: view, as: .image)
    }
}

#endif
