//
//  BLUITestSeedDataTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

#if DEBUG

/// 驗證 UI 測試種子寫入的主檔與訂單欄位都是使用者資料
struct BLUITestSeedDataTests {

    // MARK: - Properties

    /// String Catalog 結構化 key 的格式，與 `LocalizationCatalogTests` 的檢查相同
    private static let localizationKeyPattern = "^[a-z]+(\\.[a-z][a-zA-Z0-9]*){2,3}$"

    /// 每個種子組合寫入的主檔名稱與訂單引用的主檔欄位都不是本地化 key
    ///
    /// - Parameter profile: 要寫入的種子組合
    /// - Throws: 讀回 store 失敗時重新丟出 `SwiftData` 的錯誤
    @Test(arguments: BLUITestSeedProfile.allCases)
    func seed_各種子組合_主檔與訂單欄位不含本地化Key(profile: BLUITestSeedProfile) throws(any Error) {
        // Given
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }

        // When
        BLUITestSeedData.seed(profile, into: container, referenceDate: TestDependencies.fixedNow)

        // Then
        let violations = try Self.seededValues(in: ModelContext(container))
            .filter {
                $0.value.range(of: Self.localizationKeyPattern, options: .regularExpression) != nil
            }
            .map {
                "\($0.field)：\($0.value)"
            }
        #expect(violations.isEmpty, "種子組合 \(profile.rawValue) 含本地化 key 形狀的資料值：\(violations)")
    }

    /// 主檔種子的付款方式名稱與分類旗標符合規格範例表
    ///
    /// - Throws: 讀回 store 失敗時重新丟出 `SwiftData` 的錯誤
    @Test
    func seed_主檔種子組合_付款方式名稱與旗標符合規格範例() throws(any Error) {
        // Given
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        let expected: [String: PaymentMethodFlags] = [
            "信用卡": PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
            "銀行轉帳": PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            ),
            "無卡": PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
            "貨到付款": PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            ),
            "LINE Pay": PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
            "Apple Pay": PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
        ]

        // When
        BLUITestSeedData.seed(
            .lookupsOnly,
            into: container,
            referenceDate: TestDependencies.fixedNow
        )

        // Then
        let records = try ModelContext(container).fetch(FetchDescriptor<PaymentMethodRecord>())
        let actual = Dictionary(
            uniqueKeysWithValues: records.map {
                (
                    $0.name,
                    PaymentMethodFlags(
                        isCardless: $0.isCardless,
                        isBankTransfer: $0.isBankTransfer,
                        isCashOnDelivery: $0.isCashOnDelivery
                    )
                )
            }
        )
        #expect(actual == expected)
    }
}

// MARK: - Private Method

private extension BLUITestSeedDataTests {

    /// 讀回 store 中所有主檔名稱與訂單引用的主檔欄位
    ///
    /// - Parameter context: 查詢用的 `SwiftData` context
    /// - Returns: 欄位名稱與值的配對
    /// - Throws: 讀取失敗時重新丟出 `SwiftData` 的錯誤
    static func seededValues(
        in context: ModelContext
    ) throws(any Error) -> [(field: String, value: String)] {
        var values: [(field: String, value: String)] = []
        for record in try context.fetch(FetchDescriptor<OrderSourceRecord>()) {
            values.append((field: "OrderSourceRecord.name", value: record.name))
        }
        for record in try context.fetch(FetchDescriptor<CategoryRecord>()) {
            values.append((field: "CategoryRecord.name", value: record.name))
        }
        for record in try context.fetch(FetchDescriptor<PaymentMethodRecord>()) {
            values.append((field: "PaymentMethodRecord.name", value: record.name))
        }
        for record in try context.fetch(FetchDescriptor<ReconciliationStatusRecord>()) {
            values.append((field: "ReconciliationStatusRecord.name", value: record.name))
        }
        for order in try context.fetch(FetchDescriptor<OrderRecord>()) {
            values.append((field: "OrderRecord.orderSource", value: order.orderSource))
            values.append(
                contentsOf: order.categories.map {
                    (field: "OrderRecord.categories", value: $0)
                }
            )
            values.append((field: "OrderRecord.paymentMethod", value: order.paymentMethod))
            values.append(
                (field: "OrderRecord.reconciliationStatus", value: order.reconciliationStatus)
            )
        }
        return values
    }
}

#endif
