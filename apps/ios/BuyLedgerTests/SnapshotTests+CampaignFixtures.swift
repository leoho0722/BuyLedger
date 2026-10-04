//
//  SnapshotTests+CampaignFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Nested Types

extension SnapshotTests {

    /// 單筆快照訂單的客戶、金額、到貨狀態與收款狀態
    struct CampaignOrderRow: Sendable {

        /// 分貨列顯示的客戶名稱
        let customer: String

        /// 向客戶收取的金額
        let amount: Decimal

        /// 訂單目前的到貨狀態
        let status: OrderStatus

        /// 是否已收到這筆訂單的款項
        let isReceived: Bool
    }
}

// MARK: - Internal Method

extension SnapshotTests {

    /// 取得固定現在時間往前推算指定天數的日期，取當天正午以免時區換算後跨日
    ///
    /// - Parameter days: 距離固定現在時間的天數，負數代表之後
    /// - Returns: 對應日期的正午時間
    static func campaignDate(daysAgo days: Int) -> Date {
        // 固定曆法為 UTC，沒有日光節約時間；每一天都相差 86,400 秒
        let offset = TimeInterval(12 * 3_600 - days * 86_400)
        return TestDependencies.fixedNow.addingTimeInterval(offset)
    }

    /// 建立歸屬指定開團的訂單，訂單識別值依開團識別值與順序固定
    ///
    /// - Parameters:
    ///   - campaign: 訂單所屬的開團
    ///   - rows: 每筆訂單的客戶名稱、收款金額、訂單狀態與是否已收款
    /// - Returns: 依傳入順序排列的訂單，每筆訂單一項商品，成本為收款金額的六成
    static func makeOrders(for campaign: Campaign, rows: [CampaignOrderRow]) -> [LedgerOrder] {
        rows.enumerated().map { index, row in
            LedgerOrder.fixture(
                id: "\(campaign.id)-order-\(index + 1)",
                customer: LedgerCustomer(
                    name: row.customer,
                    initials: String(row.customer.prefix(1)),
                    tier: .regular
                ),
                status: row.status,
                date: TestDependencies.fixedNow,
                items: [
                    LedgerOrderItem(
                        id: UUID(0),
                        name: "示範商品",
                        quantity: 2,
                        unitPrice: row.amount / 2
                    ),
                ],
                itemCost: row.amount * 3 / 5,
                chargedAmount: row.amount,
                campaignNames: [campaign.name],
                paymentReceiptStatus: row.isReceived ? .received : .pending
            )
        }
    }
}
