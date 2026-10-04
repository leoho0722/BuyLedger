//
//  CampaignDetailContentTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團詳情的彙總、分貨篩選與提醒連結
struct CampaignDetailContentTests {

    /// 切換只看未收款時只篩選可見客戶，彙總與客戶所屬訂單維持完整
    ///
    /// - Parameters:
    ///   - showsUnpaidOnly: 是否只顯示尚未全部收款的客戶
    ///   - expectedNames: 預期可見的客戶名稱
    /// - Throws: 詳情內容或未收款客戶不存在時拋出測試錯誤
    @Test(arguments: [(false, ["Alice", "Bob"]), (true, ["Bob"])])
    func make_切換只看未收款_保留對應客戶分貨列(showsUnpaidOnly: Bool, expectedNames: [String]) throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C2",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 0)
        )
        let otherCampaign = Campaign.fixture(
            id: "C1",
            name: "其他團",
            openDate: Date(timeIntervalSince1970: 0)
        )
        let orders = [
            Self.makeOrder(
                id: "A",
                customerName: "Alice",
                receipt: .received,
                amount: 100,
                quantity: 2
            ),
            Self.makeOrder(
                id: "B",
                customerName: "Bob",
                receipt: .pending,
                amount: 50,
                quantity: 1
            ),
            Self.makeOrder(
                id: "C",
                customerName: "Bob",
                receipt: .received,
                amount: 25,
                quantity: 3
            ),
            Self.makeOrder(
                id: "D",
                customerName: "Carol",
                receipt: .pending,
                amount: 999,
                quantity: 1,
                campaignName: "其他團"
            ),
        ]

        // When
        let result = CampaignDetailContent.make(
            campaignID: "C2",
            campaigns: [otherCampaign, campaign],
            orders: orders,
            links: [:],
            showsUnpaidOnly: showsUnpaidOnly
        )

        // Then
        let content = try #require(result)
        #expect(content.campaign == campaign)
        #expect(content.summary.memberOrders.map(\.id) == ["A", "B", "C"])
        #expect(content.summary.orderCount == 3)
        #expect(content.summary.totalItemQuantity == 6)
        #expect(content.summary.receivables == 175)
        #expect(content.summary.receivedAmount == 125)
        #expect(content.summary.outstandingAmount == 50)
        #expect(content.summary.distribution.map(\.customerName) == ["Alice", "Bob"])
        #expect(content.distribution.map(\.customerName) == expectedNames)
        #expect(content.reminderLink == nil)
        let bob = try #require(content.distribution.first { $0.customerName == "Bob" })
        #expect(bob.totalQuantity == 4)
        #expect(bob.totalAmount == 75)
        #expect(bob.isFullyReceived == false)
        #expect(bob.orders.map(\.id).sorted() == ["B", "C"])
    }

    /// 指定開團不存在時，即使清單中有其他開團也不組出詳情
    @Test
    func make_指定開團不存在_回傳空內容() {
        // Given
        let campaigns = [Campaign.fixture(
            id: "C1",
            name: "其他團",
            openDate: Date(timeIntervalSince1970: 0)
        )]
        let orders = [
            Self.makeOrder(
                id: "A",
                customerName: "Alice",
                receipt: .pending,
                amount: 100,
                quantity: 1
            ),
        ]

        // When
        let content = CampaignDetailContent.make(
            campaignID: "missing",
            campaigns: campaigns,
            orders: orders,
            links: [:],
            showsUnpaidOnly: false
        )

        // Then
        #expect(content == nil)
    }

    /// 多個開團的提醒連結同時存在時，只取得指定識別值的連結
    ///
    /// - Parameter hasMatchingLink: 是否提供指定開團的提醒連結
    /// - Throws: 指定開團的詳情內容不存在時拋出測試錯誤
    @Test(arguments: [true, false])
    func make_提醒連結有無對應識別值_只取得指定開團的連結(hasMatchingLink: Bool) throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C2",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 0)
        )
        let matchingLink = CampaignReminderLink(
            eventIdentifier: "EVENT-C2",
            reminderTimestamp: Date(timeIntervalSince1970: 3_600)
        )
        var links = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVENT-C1",
                reminderTimestamp: Date(timeIntervalSince1970: 7_200)
            ),
        ]
        if hasMatchingLink {
            links["C2"] = matchingLink
        }

        // When
        let result = CampaignDetailContent.make(
            campaignID: "C2",
            campaigns: [campaign],
            orders: [],
            links: links,
            showsUnpaidOnly: false
        )

        // Then
        let content = try #require(result)
        #expect(content.reminderLink == (hasMatchingLink ? matchingLink : nil))
        #expect(content.summary.orderCount == 0)
        #expect(content.distribution.isEmpty)
    }
}

// MARK: - Private Method

private extension CampaignDetailContentTests {

    /// 建立固定識別值與成本的訂單，隔離分貨篩選所需的資料
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customerName: 分貨列使用的客戶名稱
    ///   - receipt: 訂單收款狀態
    ///   - amount: 向客戶收取的金額
    ///   - quantity: 商品件數
    ///   - campaignName: 訂單所屬的開團名稱
    /// - Returns: 固定內容的測試訂單
    static func makeOrder(
        id: String,
        customerName: String,
        receipt: PaymentReceiptStatus,
        amount: Decimal,
        quantity: Int,
        campaignName: String = "四月團"
    ) -> LedgerOrder {
        LedgerOrder.fixture(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "TC", tier: .regular),
            items: [
                LedgerOrderItem(
                    id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
                    name: "商品",
                    quantity: quantity,
                    unitPrice: 0
                ),
            ],
            chargedAmount: amount,
            campaignNames: [campaignName],
            paymentReceiptStatus: receipt
        )
    }
}
