//
//  CampaignIntegrationTests+Navigation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignIntegrationTests {

    /// 開團由列表 Service 載入後，總覽的開團卡深連結推入對應詳情並共用訂單投影
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
        let fetches = LockIsolated(0)
        let initial = Self.makeRootState(campaigns: [], orders: [order])
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                fetches.withValue {
                    $0 += 1
                }
                return [other, campaign]
            }
        }
        await Self.loadCampaigns([other, campaign], into: store)

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("四月韓國團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.append(CampaignFeatureTests.detailPath("C1", in: $0.campaigns))
        }

        // Then
        await store.finish()
        #expect(fetches.value == 1)
        #expect(store.state.campaigns.path.first?.detail?.campaignID == "C1")
        #expect(store.state.campaigns.path.first?.detail?.orders == [order])
        #expect(store.state.orders.orders == [order])
        #expect(store.state.more.orders == [order])
        #expect(store.state.dashboard.orders == [order])
        #expect(store.state.insights.orders == [order])
    }

    /// 甲團詳情經列表推入後，深連結改開乙團，堆疊只剩乙團
    @Test
    func dashboard_詳情A顯示中點選開團卡B_堆疊只剩B() async {
        // Given
        let store = Self.makeDeepLinkStore()
        await Self.pushFirstDetail(store)

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("乙團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.removeAll()
            $0.campaigns.path.append(CampaignFeatureTests.detailPath("B", in: $0.campaigns))
        }

        // Then
        #expect(store.state.campaigns.path.count == 1)
        #expect(store.state.campaigns.path.first?.detail?.campaignID == "B")
    }

    /// 深連結換成乙團之後，對乙團的收款切換經詳情請求轉送到根功能並同步訂單
    ///
    /// - Throws: 堆疊沒有詳情時由 `try #require` 丟出
    @Test
    func campaigns_深連結後在詳情切換收款_轉送委派並同步訂單() async throws {
        // Given
        let store = Self.makeDeepLinkStore()
        await Self.pushFirstDetail(store)
        await Self.deepLinkSecondDetail(store)
        let detailID = try #require(store.state.campaigns.path.ids.first)

        // When
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, "O1")

        // Then
        await Self.receiveReceiptToggle(store, detailID: detailID)
        #expect(store.state.orders.orders.map(\.paymentReceiptStatus) == [.received])
    }

    /// 深連結換成乙團並操作後返回列表，堆疊清空且沒有遺留的詳情
    ///
    /// - Throws: 堆疊沒有詳情時由 `try #require` 丟出
    @Test
    func campaigns_深連結後從詳情返回列表_堆疊清空() async throws {
        // Given
        let store = Self.makeDeepLinkStore()
        await Self.pushFirstDetail(store)
        await Self.deepLinkSecondDetail(store)
        let detailID = try #require(store.state.campaigns.path.ids.first)
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, "O1")
        await Self.receiveReceiptToggle(store, detailID: detailID)

        // When
        await store.send(.campaigns(.path(.popFrom(id: detailID)))) {
            $0.campaigns.path.removeAll()
        }

        // Then
        #expect(store.state.campaigns.path.isEmpty)
    }
}

// MARK: - Private Method

private extension CampaignIntegrationTests {

    /// 建立含甲團、乙團與乙團待收款訂單的根功能測試 `TestStore`
    ///
    /// - Returns: 訂單寫入已替身化的根功能 `TestStore`
    static func makeDeepLinkStore() -> TestStoreOf<RootFeature> {
        let state = RootFeature.State()
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
        return TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.saveOrder = { _ in
            }
        }
    }

    /// 建立歸屬「乙團」的訂單，供深連結後的收款切換使用
    ///
    /// - Parameter status: 收款狀態
    /// - Returns: 識別值為 `O1` 的訂單
    static func makeReceiptOrder(status: PaymentReceiptStatus) -> LedgerOrder {
        LedgerOrder.fixture(id: "O1", campaignNames: ["乙團"], paymentReceiptStatus: status)
    }

    /// 經列表點擊的請求流程推入甲團詳情
    ///
    /// - Parameter store: 根功能測試 `TestStore`
    static func pushFirstDetail(_ store: TestStoreOf<RootFeature>) async {
        await store.send(.campaigns(.list(.view(.campaignTapped("A")))))
        await store.receive(\.campaigns.list.delegate.requested) {
            $0.campaigns.path[id: 0] = CampaignFeatureTests.detailPath("A", in: $0.campaigns)
        }
    }

    /// 以根功能的深連結把堆疊換成乙團詳情
    ///
    /// - Parameter store: 根功能測試 `TestStore`
    static func deepLinkSecondDetail(_ store: TestStoreOf<RootFeature>) async {
        await store.send(.dashboard(.delegate(.campaignTapped("乙團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.removeAll()
            $0.campaigns.path.append(CampaignFeatureTests.detailPath("B", in: $0.campaigns))
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
