//
//  CampaignIntegrationNavigationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，涵蓋總覽開團卡深連結推入詳情，以及之後的收款切換與返回列表
@MainActor
struct CampaignIntegrationNavigationTests {

    /// 驗證開團已載入時，點選總覽的開團卡會切到開團分頁並推入對應詳情，各頁的訂單資料都一致
    @Test
    func dashboard_載入後點選開團卡_切換分頁並推入指定詳情() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "四月韓國團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let other = Campaign(
            id: "C2",
            name: "其他團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let order = LedgerOrder(
            id: "O1",
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_507_200),
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "item",
                    quantity: 1,
                    unitPrice: 0
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 100,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: ["四月韓國團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let initial = CampaignIntegrationTestSupport.makeRootState(
            campaigns: [other, campaign],
            orders: [order]
        )
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("四月韓國團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.append(
                CampaignFeatureTestSupport.detailPath("C1", in: initial.campaigns)
            )
        }

        // Then
        await store.finish()
        #expect(store.state.campaigns.path.first?.detail?.campaignID == "C1")
        #expect(store.state.campaigns.path.first?.detail?.orders == [order])
        #expect(store.state.orders.orders == [order])
        #expect(store.state.more.orders == [order])
        #expect(store.state.dashboard.orders == [order])
        #expect(store.state.insights.orders == [order])
    }

    /// 驗證甲團詳情顯示中，點選總覽的乙團開團卡後，切到開團分頁，堆疊只剩乙團的詳情
    @Test
    func dashboard_詳情A顯示中點選開團卡B_堆疊只剩B() async {
        // Given
        let initial = Self.makeDeepLinkState(detailCampaignID: "A", selectedTab: .dashboard)
        let store = Self.makeDeepLinkStore(initial: initial)

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("乙團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.removeAll()
            $0.campaigns.path.append(
                CampaignFeatureTestSupport.detailPath("B", in: initial.campaigns)
            )
        }

        // Then
        #expect(store.state.campaigns.path.count == 1)
        #expect(store.state.campaigns.path.first?.detail?.campaignID == "B")
    }

    /// 驗證深連結到乙團詳情後切換收款，請求依序經開團功能與根功能送到訂單，訂單收款狀態變為已收
    ///
    /// - Throws: 堆疊沒有詳情時由 `try #require` 丟出
    @Test
    func campaigns_深連結後在詳情切換收款_轉送委派並同步訂單() async throws {
        // Given
        let initial = Self.makeDeepLinkState(detailCampaignID: "B", selectedTab: .campaigns)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.saveOrder = { _ in
            }
        }
        let detailID = try #require(store.state.campaigns.path.ids.first)

        // When
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, "O1")

        // Then
        await Self.receiveReceiptToggle(store, detailID: detailID)
        #expect(store.state.orders.orders.map(\.paymentReceiptStatus) == [.received])
    }

    /// 驗證深連結到乙團詳情後返回列表，堆疊清空，不留下任何詳情
    ///
    /// - Throws: 堆疊沒有詳情時由 `try #require` 丟出
    @Test
    func campaigns_深連結後從詳情返回列表_堆疊清空() async throws {
        // Given
        let initial = Self.makeDeepLinkState(detailCampaignID: "B", selectedTab: .campaigns)
        let store = Self.makeDeepLinkStore(initial: initial)
        let detailID = try #require(store.state.campaigns.path.ids.first)

        // When
        await store.send(.campaigns(.path(.popFrom(id: detailID)))) {
            $0.campaigns.path.removeAll()
        }

        // Then
        #expect(store.state.campaigns.path.isEmpty)
    }
}

// MARK: - Private Method

private extension CampaignIntegrationNavigationTests {

    /// 建立含甲團、乙團與乙團待收款訂單，並已推入指定開團詳情的根功能狀態
    ///
    /// - Parameters:
    ///   - detailCampaignID: 堆疊中唯一詳情所屬的開團識別值
    ///   - selectedTab: 目前選取的分頁；從總覽點開團卡前是 `.dashboard`，深連結完成後是 `.campaigns`
    /// - Returns: 含指定詳情與分頁選取的根功能狀態
    static func makeDeepLinkState(
        detailCampaignID: Campaign.ID,
        selectedTab: RootTab
    ) -> RootFeature.State {
        var state = RootFeature.State()
        state.selectedTab = selectedTab
        let order = makeReceiptOrder(status: .pending)
        state.campaigns.$campaigns.withLock {
            $0 = [
                Campaign.fixture(id: "A", name: "甲團"),
                Campaign.fixture(id: "B", name: "乙團"),
            ]
        }
        state.campaigns.$orders.withLock {
            $0 = [order]
        }
        state.more.$orders.withLock {
            $0 = [order]
        }
        state.orders.$orders.withLock {
            $0 = [order]
        }
        state.campaigns.showDetail(campaignID: detailCampaignID)
        return state
    }

    /// 建立歸屬「乙團」的訂單，供深連結後的收款切換使用
    ///
    /// - Parameter status: 收款狀態
    /// - Returns: 識別值為 O1 的訂單
    static func makeReceiptOrder(status: PaymentReceiptStatus) -> LedgerOrder {
        LedgerOrder.fixture(id: "O1", campaignNames: ["乙團"], paymentReceiptStatus: status)
    }

    /// 以固定日期與行事曆建立根功能測試 `TestStore`
    ///
    /// - Parameter initial: Given 自建的根功能初始狀態
    /// - Returns: 以指定狀態啟動的根功能 `TestStore`
    static func makeDeepLinkStore(initial: RootFeature.State) -> TestStoreOf<RootFeature> {
        TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
    }

    /// 接收詳情收款切換經開團功能、根功能到訂單同步的完整序列
    ///
    /// - Parameters:
    ///   - store: 根功能測試 `TestStore`
    ///   - detailID: 乙團詳情在堆疊中的識別值
    static func receiveReceiptToggle(
        _ store: TestStoreOf<RootFeature>,
        detailID: StackElementID
    ) async {
        let receivedOrder = LedgerOrder(
            id: "O1",
            customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 0),
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
            orderSource: "測試來源",
            categories: [],
            paymentMethod: "測試付款方式",
            notes: "",
            reconciliationStatus: "",
            campaignNames: ["乙團"],
            paymentReceiptStatus: .received,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        await store.receive(\.campaigns.path[id: detailID].detail.delegate.requested) {
            $0.campaigns.$orders.withLock {
                $0 = [receivedOrder]
            }
            $0.more.$orders.withLock {
                $0 = [receivedOrder]
            }
            $0.orders.$orders.withLock {
                $0 = [receivedOrder]
            }
        }
        await store.receive(\.campaigns.delegate.receiptStatusToggled)
        await store.receive(\.orders.rootRequest.receiptStatusChange)
        await store.receive(\.orders.writes.receiptToggleRequested)
        await store.receive(\.orders.writes.receiptResponse) {
            $0.dashboard.orders = [receivedOrder]
            $0.insights.orders = [receivedOrder]
        }
    }
}
