//
//  OrderWritesFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證訂單寫入請求的寫入範圍、共用清單更新，以及失敗時送出的通知
@MainActor
struct OrderWritesFeatureTests {

    // MARK: - Properties

    /// 拒絕或無變更時應維持不變的原訂單
    private static let original = OrderWritesFeatureTestSupport.original

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證狀態變更直接要求為已合併時，拒絕並保留訂單，不呼叫寫入服務，並回報不能改為已合併
    ///
    /// - Note: 未覆寫的 `saveOrder` 被呼叫時測試會失敗
    @Test
    func statusChangeRequested_目標為已合併_拒絕且保留訂單() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.statusChangeRequested(id: "O1", status: .merged))

        // Then
        await store.receive(\.delegate, .failed(.mergedStatusRejected))
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }

    /// 驗證狀態變更的目標訂單不存在或狀態未變時，共用清單保持原樣，且不呼叫寫入服務
    ///
    /// - Parameter isMissing: 是否指定不存在的訂單
    @Test(arguments: [true, false])
    func statusChangeRequested_不存在或狀態未變_不寫入(isMissing: Bool) async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(
            .statusChangeRequested(id: isMissing ? "MISSING" : "O1", status: .confirmed)
        )

        // Then
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }

    /// 驗證批次狀態變更含已合併的目標時整批拒絕，共用清單保持原樣，並回報不能改為已合併，批次路徑不會繞過已合併的寫入守門
    @Test
    func batchStatusChangeRequested_含已合併目標_拒絕整批寫入() async {
        // Given
        let changed = LedgerOrder.fixture(id: "O1", status: .merged, categories: ["美妝"])
        let initial = OrderWritesFeatureTestSupport.makeState()
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.batchStatusChangeRequested([changed]))

        // Then
        await store.receive(\.delegate, .failed(.mergedStatusRejected))
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }

    /// 驗證刪除成功的回應抵達時，目標訂單已不在共用清單中，清單保持原樣，且不送出刪除完成通知
    @Test
    func deleteResponse_目標已移除_保留清單且不發出委派() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.deleteResponse(.success("MISSING")))

        // Then
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }
}
