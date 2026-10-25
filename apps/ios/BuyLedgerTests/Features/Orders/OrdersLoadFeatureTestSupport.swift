//
//  OrdersLoadFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture

@testable import BuyLedger

/// 提供訂單載入測試共用的獨立記憶體狀態
enum OrdersLoadFeatureTestSupport {}

// MARK: - Internal Method

extension OrdersLoadFeatureTestSupport {

    /// 建立使用獨立記憶體儲存的載入狀態，訂單與載入狀態不外溢到其他測試
    ///
    /// - Parameter orders: 初始訂單
    /// - Returns: 尚未開始讀取的載入狀態
    static func makeState(orders: [LedgerOrder] = []) -> OrdersLoadFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            let shared = Shared<[LedgerOrder]>(value: [])
            shared.withLock {
                $0 = orders
            }
            return OrdersLoadFeature.State(orders: shared)
        }
    }
}
