//
//  OrderServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 驗證訂單 Service 與共用資料庫依賴
struct OrderServiceTests {

    // MARK: - Tests

    /// 正式依賴連續解析兩次會取得同一資料庫 actor
    @Test
    func liveValue_連續解析兩次_取得同一資料庫實例() {
        // Given

        // When
        let identities = TestContainerCreationLock.withLock {
            withDependencies {
                $0.context = .live
            } operation: {
                @Dependency(\.buyLedgerDatabase) var first
                @Dependency(\.buyLedgerDatabase) var second
                return (ObjectIdentifier(first as AnyObject), ObjectIdentifier(second as AnyObject))
            }
        }

        // Then
        #expect(identities.0 == identities.1)
    }
}

// MARK: - Nested Types

extension OrderServiceTests {

    /// 完整測試訂單的欄位版本
    enum FullFieldOrderVariant: Sendable {

        /// 舊資料欄位
        case original

        /// 欄位已更新的資料
        case updated
    }
}

// MARK: - Internal Method

extension OrderServiceTests {

    /// 建立固定欄位的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - date: 訂單日期
    ///   - photos: 訂單照片
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - campaignNames: 所屬開團名稱
    /// - Returns: 對應測試輸入的訂單
    static func makeOrder(
        id: String,
        date: Date = Date(timeIntervalSince1970: 0),
        photos: [Data] = [],
        categories: [String] = [],
        paymentMethod: String = "測試付款",
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder.fixture(
            id: id,
            date: date,
            categories: categories,
            paymentMethod: paymentMethod,
            campaignNames: campaignNames,
            photos: photos
        )
    }

    /// 建立可區分欄位變更的完整測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - variant: 要建立的欄位版本
    ///   - photos: 要覆寫的照片；未指定時依版本使用固定照片
    /// - Returns: 對應欄位版本的完整訂單
    static func makeFullFieldOrder(
        id: String,
        variant: FullFieldOrderVariant,
        photos: [Data]? = nil
    ) -> LedgerOrder {
        switch variant {
        case .original:
            LedgerOrder.fixture(
                id: id,
                customer: LedgerCustomer(name: "初始客戶", initials: "IN", tier: .regular),
                status: .quoting,
                currency: .usd,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                items: [LedgerOrderItem(name: "商品A", quantity: 2, unitPrice: 150)],
                itemCost: 1_200,
                domesticShipping: 60,
                internationalShipping: 300,
                foreignDomesticShipping: 80,
                cardFeeRate: 0.02,
                platformFeeRate: 0.05,
                paymentFeeRate: 0.01,
                chargedAmount: 5_000,
                cardlessDeductionAmount: 100,
                cardlessSupplementAmount: 50,
                orderSource: "蝦皮",
                categories: ["美妝"],
                paymentMethod: "信用卡",
                notes: "初次備註",
                reconciliationStatus: "待對帳",
                campaignNames: ["春季團"],
                paymentReceiptStatus: .received,
                isCashOnDelivery: true,
                photos: photos ?? [Data([0x01, 0x02])],
                mergedSourceIDs: ["BL-SRC-OLD"]
            )

        case .updated:
            LedgerOrder.fixture(
                id: id,
                customer: LedgerCustomer(name: "更新後客戶", initials: "UD", tier: .vip),
                status: .delivered,
                currency: .jpy,
                date: Date(timeIntervalSince1970: 1_800_000_000),
                items: [LedgerOrderItem(name: "商品B", quantity: 5, unitPrice: 300)],
                itemCost: 2_400,
                domesticShipping: 120,
                internationalShipping: 450,
                foreignDomesticShipping: 160,
                cardFeeRate: 0.03,
                platformFeeRate: 0.08,
                paymentFeeRate: 0.02,
                chargedAmount: 8_000,
                cardlessDeductionAmount: 200,
                cardlessSupplementAmount: 75,
                orderSource: "露天",
                categories: ["3C"],
                paymentMethod: "銀行匯款",
                notes: "更新後備註",
                reconciliationStatus: "對帳完成",
                campaignNames: ["夏季團"],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: photos ?? [Data([0x03, 0x04, 0x05])],
                mergedSourceIDs: ["BL-SRC-NEW-1", "BL-SRC-NEW-2"]
            )
        }
    }

    /// 以單一交易預先寫入訂單與主檔記錄
    ///
    /// - Parameters:
    ///   - orders: 要先寫入的訂單
    ///   - categories: 要先寫入的類別名稱
    ///   - paymentMethods: 要先寫入的付款方式
    ///   - database: 要寫入測試資料的資料庫
    /// - Throws: 儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    static func seed(
        _ orders: [LedgerOrder] = [],
        categories: [String] = [],
        paymentMethods: [PaymentMethodInfo] = [],
        database: BuyLedgerDatabase
    ) async throws(PersistenceError) {
        try await database.write { context throws(PersistenceError) in
            for order in orders {
                context.insert(OrderRecord(order: order))
            }
            for name in categories {
                context.insert(CategoryRecord(name: name))
            }
            for paymentMethod in paymentMethods {
                context.insert(
                    PaymentMethodRecord(
                        name: paymentMethod.name,
                        isCardless: paymentMethod.isCardless,
                        isBankTransfer: paymentMethod.isBankTransfer,
                        isCashOnDelivery: paymentMethod.isCashOnDelivery
                    )
                )
            }
        }
    }

    /// 以指定資料庫建立正式訂單 Service
    ///
    /// - Parameter database: Service 操作時使用的資料庫
    /// - Returns: 已擷取資料庫依賴的訂單 Service
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> OrderService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            OrderService.liveValue
        }
    }

    /// 以新讀取 context 取得指定訂單與完整照片
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - database: 要讀取的資料庫
    /// - Returns: 找到時轉成領域型別的訂單
    /// - Throws: 查詢或記錄轉換失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchOrder(
        id: String,
        from database: any BuyLedgerDatabaseProtocol
    ) async throws(PersistenceError) -> LedgerOrder? {
        try await database.read { context throws(PersistenceError) in
            let descriptor = FetchDescriptor<OrderRecord>(
                predicate: #Predicate {
                    $0.id == id
                }
            )
            let record = try PersistenceError.mapFetch {
                try context.fetch(descriptor).first
            }
            return try record?.toDomain(includingPhotos: true)
        }
    }
}
