//
//  SnapshotTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 提供快照測試共用的開團訂單資料與編輯狀態建構輔助
enum SnapshotTestSupport {}

// MARK: - Nested Types

extension SnapshotTestSupport {

    /// 單筆快照訂單的客戶、金額、訂單狀態與收款狀態
    struct CampaignOrderRow: Sendable {

        /// 分貨列顯示的客戶名稱
        let customer: String

        /// 向客戶收取的金額
        let amount: Decimal

        /// 訂單目前的狀態
        let status: OrderStatus

        /// 是否已收到這筆訂單的款項
        let isReceived: Bool
    }
}

// MARK: - Internal Method

extension SnapshotTestSupport {

    /// 取得距固定現在時間指定天數的正午時間，以免時區換算後跨日
    ///
    /// - Parameter days: 距離固定現在時間的天數，負數代表之後
    /// - Returns: 對應日期的正午時間
    static func campaignDate(daysAgo days: Int) -> Date {
        // UTC 沒有日光節約時間，每一天都是 86,400 秒
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

    /// 建立內容固定且照片已載入的訂單編輯快照，避免區段出現時啟動讀取
    ///
    /// - Parameter original: 快照要顯示的既有訂單
    /// - Returns: 沿用訂單內容、固定時間與已載入照片的表單狀態
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeOrderEditSnapshotState(original: LedgerOrder) throws -> OrderEditFeature.State {
        var state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(calendar: try makeOrderEditCalendar()),
            currentDate: TestDependencies.fixedNow
        )
        // key window 渲染可能觸發照片區段的載入，快照只呈現已備妥的內容
        state.photos.photoLoadPhase = .loaded
        return state
    }
}

// MARK: - Private Method

private extension SnapshotTestSupport {

    /// 建立時區固定為 `Asia/Taipei` 的西曆，供表單的完整時間格式化使用
    ///
    /// - Returns: 時區明確設為 `Asia/Taipei` 的西曆
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeOrderEditCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Taipei"))
        return calendar
    }
}
