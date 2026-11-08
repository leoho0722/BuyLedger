//
//  OrderWriteOperationsFailureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/8.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderWriteOperations.Failure` 的單元測試，涵蓋寫入失敗訊息的 key 與兩種 App 語言的完整文字
struct OrderWriteOperationsFailureTests {

    /// 驗證每個失敗原因的訊息 key，並在兩種 App 語言各解析出完整文字
    ///
    /// - Parameter scenario: 失敗原因與預期的 key、正體中文及英文文字
    @Test(arguments: MessageCase.allCases)
    func message_各失敗原因_依App語言解析完整文字(scenario: MessageCase) {
        // Given
        let failure = scenario.failure

        // When
        let message = failure.message

        // Then
        #expect(message.key == scenario.key)
        #expect(AppLanguage.traditionalChinese.resolve(message) == scenario.traditionalChinese)
        #expect(AppLanguage.english.resolve(message) == scenario.english)
    }
}

// MARK: - Nested Types

extension OrderWriteOperationsFailureTests {

    /// 失敗原因與其預期訊息的測試案例
    struct MessageCase: Sendable {

        /// 十一種失敗原因 (狀態寫入與已合併狀態拒絕共用同一個 key)
        static let allCases = [
            Self(
                failure: .save,
                key: "orders.general.message.orderSavedTry",
                traditionalChinese: "訂單儲存失敗，請稍後再試。",
                english: "The order could not be saved. Try again later."
            ),
            Self(
                failure: .status,
                key: "orders.general.message.orderStatusUpdated",
                traditionalChinese: "訂單狀態更新失敗，請稍後再試。",
                english: "The order status could not be updated. Try again later."
            ),
            Self(
                failure: .mergedStatusRejected,
                key: "orders.general.message.orderStatusUpdated",
                traditionalChinese: "訂單狀態更新失敗，請稍後再試。",
                english: "The order status could not be updated. Try again later."
            ),
            Self(
                failure: .batchStatus,
                key: "orders.general.message.batchStatusUpdate",
                traditionalChinese: "批次更新狀態失敗，請稍後再試。",
                english: "The batch status update failed. Try again later."
            ),
            Self(
                failure: .receipt,
                key: "orders.general.message.receiptStatusUpdated",
                traditionalChinese: "收款狀態更新失敗，請稍後再試。",
                english: "The receipt status could not be updated. Try again later."
            ),
            Self(
                failure: .delete,
                key: "orders.general.message.orderDeletedTry",
                traditionalChinese: "訂單刪除失敗，請稍後再試。",
                english: "The order could not be deleted. Try again later."
            ),
            Self(
                failure: .merge,
                key: "orders.general.message.mergedOrderSaved",
                traditionalChinese: "合併訂單儲存失敗，請稍後再試。",
                english: "The merged order could not be saved. Try again later."
            ),
            Self(
                failure: .option(.orderSource),
                key: "orders.general.message.orderSourceAdded",
                traditionalChinese: "訂單來源新增失敗，請稍後再試。",
                english: "The order source could not be added. Try again later."
            ),
            Self(
                failure: .option(.category),
                key: "orders.general.message.categoryAddedTry",
                traditionalChinese: "商品類別新增失敗，請稍後再試。",
                english: "The category could not be added. Try again later."
            ),
            Self(
                failure: .option(.paymentMethod),
                key: "orders.general.message.paymentMethodAdded",
                traditionalChinese: "付款方式新增失敗，請稍後再試。",
                english: "The payment method could not be added. Try again later."
            ),
            Self(
                failure: .option(.reconciliationStatus),
                key: "orders.general.message.reconciliationStatusAdded",
                traditionalChinese: "對帳狀態新增失敗，請稍後再試。",
                english: "The reconciliation status could not be added. Try again later."
            ),
        ]

        /// 寫入操作回報的失敗原因
        let failure: OrderWriteOperations.Failure

        /// 預期的 catalog key
        let key: String

        /// 預期的正體中文文字
        let traditionalChinese: String

        /// 預期的英文文字
        let english: String
    }
}
