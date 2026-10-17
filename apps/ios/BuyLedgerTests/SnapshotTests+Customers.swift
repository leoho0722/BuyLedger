//
//  SnapshotTests+Customers.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 客戶頁以範例訂單彙總後顯示的名單，前三名以名次徽章與排行卡強調
    ///
    /// - Note: 包在 `NavigationStack` 內，與預覽相同
    /// - Note: 使用 `EmptyReducer`，畫面不會送出任何 Service 呼叫
    /// - Note: 名單較長，高度加到 1800 露出完整列表
    /// - Note: 版面不依尺寸分類分流
    @Test
    func customersView_一般客戶資料_顯示名次徽章與排行卡() {
        TestDependencies.withFixedNow {
            // Given
            let state = CustomersFeature.State(
                orders: SharedReader(value: LedgerOrder.sampleOrders)
            )

            // When
            let view = NavigationStack {
                CustomersView(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
            }
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 1_800)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 客戶頁沒有任何訂單時顯示空狀態，不顯示名次徽章與排行卡
    ///
    /// - Note: 包在 `NavigationStack` 內，與預覽相同
    /// - Note: 使用 `EmptyReducer`，畫面不會送出任何 Service 呼叫
    /// - Note: 尺寸與 iPhone 直向相同，維持 393 × 852
    @Test
    func customersView_無客戶資料_顯示空狀態() {
        TestDependencies.withFixedNow {
            // Given
            let state = CustomersFeature.State(orders: SharedReader(value: []))

            // When
            let view = NavigationStack {
                CustomersView(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
            }
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}
