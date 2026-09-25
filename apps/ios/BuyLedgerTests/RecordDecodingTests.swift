//
//  RecordDecodingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證持久化記錄的 raw value 解析
@MainActor
struct RecordDecodingTests {

    // MARK: - Tests

    /// 無法解析的訂單收款狀態應保留四個診斷欄位
    ///
    /// - Parameter rawValue: 要寫入持久化記錄的非法狀態字串
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test(arguments: ["legacy-status", ""])
    func invalidOrderPaymentReceiptStatusThrowsRecordDecodingError(
        rawValue: String
    ) async throws(any Error) {
        // Given

        let container = PersistenceContainer.makeInMemory(for: .testing)
        let context = ModelContext(container)
        let record = OrderRecord(order: Self.makeOrder(id: "order-001"))
        record.paymentReceiptStatus = rawValue
        context.insert(record)
        try context.save()

        let persistence = OrderPersistence(modelContainer: container)

        do {
            // When

            _ = try await persistence.fetchAll()
            // Then

            Issue.record("預期無法解析的收款狀態會讓讀取失敗。")
        } catch {
            switch error {
            case let .fetchFailed(underlying):
                if let decodingError = underlying as? RecordDecodingError {
                    #expect(decodingError.entity == "OrderRecord")
                    #expect(decodingError.identifier == "order-001")
                    #expect(decodingError.field == "paymentReceiptStatus")
                    #expect(decodingError.rawValue == rawValue)
                } else {
                    Issue.record("底層錯誤應保留 RecordDecodingError。")
                }
            case .saveFailed:
                Issue.record("預期讀取失敗，實際得到寫入失敗。")
            case .containerCreationFailed:
                Issue.record("預期讀取失敗，實際得到容器建立失敗。")
            }
        }
    }

    /// 無法解析的開團狀態應保留四個診斷欄位
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func invalidCampaignStatusThrowsRecordDecodingError() async throws(any Error) {
        // Given

        let container = PersistenceContainer.makeInMemory(for: .testing)
        let context = ModelContext(container)
        let record = CampaignRecord(campaign: Self.makeCampaign(id: "campaign-001"))
        record.statusRaw = "legacy-status"
        context.insert(record)
        try context.save()

        let persistence = CampaignPersistence(modelContainer: container)

        do {
            // When

            _ = try await persistence.fetchAll()
            // Then

            Issue.record("預期無法解析的開團狀態會讓讀取失敗。")
        } catch {
            switch error {
            case let .fetchFailed(underlying):
                if let decodingError = underlying as? RecordDecodingError {
                    #expect(decodingError.entity == "CampaignRecord")
                    #expect(decodingError.identifier == "campaign-001")
                    #expect(decodingError.field == "status")
                    #expect(decodingError.rawValue == "legacy-status")
                } else {
                    Issue.record("底層錯誤應保留 RecordDecodingError。")
                }
            case .saveFailed:
                Issue.record("預期讀取失敗，實際得到寫入失敗。")
            case .containerCreationFailed:
                Issue.record("預期讀取失敗，實際得到容器建立失敗。")
            }
        }
    }

    /// 合法的訂單與開團狀態 rawValue 應原樣轉回領域值
    ///
    /// - Throws: 測試容器建立或資料讀取失敗時拋出錯誤
    @Test func legalRawValuesRoundTripWithoutFallback() async throws(any Error) {
        // Given

        let container = PersistenceContainer.makeInMemory(for: .testing)
        let context = ModelContext(container)

        let pendingOrder = OrderRecord(order: Self.makeOrder(id: "order-pending"))
        pendingOrder.paymentReceiptStatus = PaymentReceiptStatus.pending.rawValue
        let receivedOrder = OrderRecord(order: Self.makeOrder(id: "order-received"))
        receivedOrder.paymentReceiptStatus = PaymentReceiptStatus.received.rawValue
        context.insert(pendingOrder)
        context.insert(receivedOrder)

        let ongoingCampaign = CampaignRecord(campaign: Self.makeCampaign(id: "campaign-ongoing"))
        ongoingCampaign.statusRaw = CampaignStatus.ongoing.rawValue
        let closedCampaign = CampaignRecord(
            campaign: Self.makeCampaign(id: "campaign-closed", status: .closed)
        )
        closedCampaign.statusRaw = CampaignStatus.closed.rawValue
        context.insert(ongoingCampaign)
        context.insert(closedCampaign)
        try context.save()

        let orderPersistence = OrderPersistence(modelContainer: container)
        // When

        let fetchedOrders = try await orderPersistence.fetchAll()
        let orderStatuses = Dictionary(
            uniqueKeysWithValues: fetchedOrders.map { ($0.id, $0.paymentReceiptStatus) }
        )

        let campaignPersistence = CampaignPersistence(modelContainer: container)
        let fetchedCampaigns = try await campaignPersistence.fetchAll()
        let campaignStatuses = Dictionary(
            uniqueKeysWithValues: fetchedCampaigns.map { ($0.id, $0.status) }
        )

        // Then

        #expect(orderStatuses["order-pending"] == .pending)
        #expect(orderStatuses["order-received"] == .received)
        #expect(campaignStatuses["campaign-ongoing"] == .ongoing)
        #expect(campaignStatuses["campaign-closed"] == .closed)
    }
}

// MARK: - Private Method

private extension RecordDecodingTests {

    /// 建立測試用訂單
    /// - Parameter id: 訂單識別值
    /// - Returns: 最小測試訂單
    static func makeOrder(id: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .new),
            status: .quoting,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_770_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立測試用開團
    /// - Parameters:
    ///   - id: 開團識別值
    ///   - status: 開團狀態
    /// - Returns: 最小測試開團
    static func makeCampaign(
        id: String,
        status: CampaignStatus = .ongoing
    ) -> Campaign {
        Campaign(
            id: id,
            name: "測試開團",
            openDate: Date(timeIntervalSince1970: 1_770_000_000),
            closeDate: nil,
            status: status,
            settledDate: nil,
            notes: ""
        )
    }
}
