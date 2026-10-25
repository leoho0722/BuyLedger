//
//  CampaignDetailFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignDetailFeature` 的單元測試，以 TestStore 逐步驗證收款切換與送出的請求，並直接讀取 State 的內容與只看未收款
struct CampaignDetailFeatureTests {

    /// 驗證收款鍵依訂單目前的收款狀態送出請求：已收款切回待收款，其他狀態切成已收款
    ///
    /// - Parameter example: 訂單目前的收款狀態與預期請求的下一個狀態
    @Test(arguments: [
        ReceiptToggleExample(current: .pending, expected: .received),
        ReceiptToggleExample(current: .received, expected: .pending),
    ])
    @MainActor
    func receiptToggleTapped_依目前狀態_請求切成相反狀態(example: ReceiptToggleExample) async {
        // Given
        let store = Self.makeStore(orders: [Self.makeOrder(id: "O1", receipt: example.current)])

        // When
        await store.send(.view(.receiptToggleTapped("O1")))

        // Then
        await store.receive(
            \.delegate.requested,
            .toggleReceipt(orderID: "O1", status: example.expected)
        )
    }

    /// 驗證收款鍵指向不存在的訂單時不送出任何請求，訂單與只看未收款的共用值都維持不變
    @Test
    @MainActor
    func receiptToggleTapped_找不到訂單_不送出請求() async {
        // Given
        let store = Self.makeStore(orders: [Self.makeOrder(id: "O1", receipt: .pending)])

        // When
        await store.send(.view(.receiptToggleTapped("missing")))

        // Then
        await store.finish()
        #expect(store.state.orders.map(\.id) == ["O1"])
        #expect(store.state.isShowingUnpaidOnly == false)
    }

    /// 驗證只看未收款切換時，新值寫入共用的篩選值，不送出任何請求
    ///
    /// - Parameter isOn: 切換後的篩選狀態
    @Test(arguments: [true, false])
    @MainActor
    func unpaidOnlyToggled_切換篩選_寫入共用值(isOn: Bool) async {
        // Given
        let store = Self.makeStore(isShowingUnpaidOnly: !isOn)

        // When
        await store.send(.view(.unpaidOnlyToggled(isOn))) {
            $0.$isShowingUnpaidOnly.withLock {
                $0 = isOn
            }
        }

        // Then
        #expect(store.state.isShowingUnpaidOnly == isOn)
    }

    /// 驗證點擊編輯時，詳情只送出編輯該團的請求，自身狀態不變
    @Test
    @MainActor
    func editTapped_點擊編輯_送出編輯請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.editTapped))

        // Then
        await store.receive(\.delegate.requested, .edit("C1"))
    }

    /// 驗證點擊結團時，詳情只送出結團請求，不自行寫入開團
    @Test
    @MainActor
    func settleTapped_點擊結團_送出結團請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.settleTapped))

        // Then
        await store.receive(\.delegate.requested, .settle("C1"))
    }

    /// 驗證選擇新狀態時，詳情只送出變更該團狀態的請求，共用的開團狀態維持原值
    @Test
    @MainActor
    func statusChanged_選擇新狀態_送出變更狀態請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.statusChanged(.closed)))

        // Then
        await store.receive(\.delegate.requested, .changeStatus(id: "C1", status: .closed))
        #expect(store.state.content?.campaign.status == .ongoing)
    }

    /// 驗證點擊刪除時，詳情只送出刪除該團的請求，自身狀態不變
    @Test
    @MainActor
    func deleteTapped_點擊刪除_送出刪除請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.deleteTapped))

        // Then
        await store.receive(\.delegate.requested, .delete("C1"))
    }

    /// 驗證開團存在時，`content` 組出該團內容，並帶入共用的訂單與提醒連結
    ///
    /// - Throws: 內容不存在時由 `try #require` 丟出
    @Test
    func content_開團存在_帶入共用的訂單與提醒連結() throws {
        // Given
        let link = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
        )
        let state = Self.makeState(
            orders: [Self.makeOrder(id: "O1", receipt: .received)],
            links: ["C1": link]
        )

        // When
        let content = state.content

        // Then
        let result = try #require(content)
        #expect(result.campaign == Campaign.fixture(id: "C1", name: "四月團"))
        #expect(result.summary.memberOrders.map(\.id) == ["O1"])
        #expect(result.reminderLink == link)
    }

    /// 驗證共用的開團清單移除該團後，`content` 立即變成 `nil`
    @Test
    func content_共用開團被移除_變成空內容() {
        // Given
        let campaigns = Shared(value: [Campaign.fixture(id: "C1", name: "四月團")])
        let state = CampaignDetailFeature.State(
            campaignID: "C1",
            campaigns: SharedReader(campaigns),
            orders: SharedReader(value: []),
            reminderLinks: SharedReader(value: [:]),
            isShowingUnpaidOnly: Shared(value: false)
        )

        // When
        campaigns.withLock {
            $0 = []
        }

        // Then
        #expect(state.content == nil)
    }

    /// 驗證開啟共用的只看未收款後，`content` 的分貨列只留下仍有未收款的客戶，彙總的分貨仍含全部客戶
    @Test
    func content_開啟只看未收款_只留未收款客戶() {
        // Given
        let state = Self.makeState(orders: [
            Self.makeOrder(id: "O1", customerName: "甲", receipt: .received),
            Self.makeOrder(id: "O2", customerName: "乙", receipt: .pending),
        ])

        // When
        state.$isShowingUnpaidOnly.withLock {
            $0 = true
        }

        // Then
        #expect(state.content?.distribution.map(\.customerName) == ["乙"])
        #expect(state.content?.summary.distribution.count == 2)
    }

    /// 驗證只看未收款時，分貨區的空狀態訊息為全部已收款 (英文為 All orders are paid.)
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func distributionEmptyMessage_只看未收款_顯示全部已收款() throws {
        // Given
        let state = Self.makeState(isShowingUnpaidOnly: true)

        // When
        let message = state.distributionEmptyMessage
        let text = try Self.localizedText(message, language: .english)

        // Then
        #expect(message.key == "campaigns.detail.message.allOrdersPaid")
        #expect(text == "All orders are paid.")
    }

    /// 驗證未開啟只看未收款時，分貨區的空狀態訊息為尚無歸屬此開團的訂單 (英文為 No orders are assigned to this campaign.)
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func distributionEmptyMessage_未只看未收款_顯示尚無歸屬訂單() throws {
        // Given
        let state = Self.makeState()

        // When
        let message = state.distributionEmptyMessage
        let text = try Self.localizedText(message, language: .english)

        // Then
        #expect(message.key == "campaigns.detail.message.ordersAssignedCampaign")
        #expect(text == "No orders are assigned to this campaign.")
    }
}

// MARK: - Nested Types

extension CampaignDetailFeatureTests {

    /// 收款鍵的案例：訂單目前狀態與預期請求的下一個狀態
    struct ReceiptToggleExample: Sendable {

        /// 訂單目前的收款狀態
        let current: PaymentReceiptStatus

        /// 預期請求切成的收款狀態
        let expected: PaymentReceiptStatus
    }
}

// MARK: - Private Method

private extension CampaignDetailFeatureTests {

    /// 建立詳情的測試 store
    ///
    /// - Parameters:
    ///   - orders: 唯讀的訂單投影
    ///   - isShowingUnpaidOnly: 「只看未收款」的初始值
    /// - Returns: 顯示開團 C1 詳情的 store
    @MainActor
    static func makeStore(
        orders: [LedgerOrder] = [],
        isShowingUnpaidOnly: Bool = false
    ) -> TestStoreOf<CampaignDetailFeature> {
        TestStore(
            initialState: makeState(orders: orders, isShowingUnpaidOnly: isShowingUnpaidOnly)
        ) {
            CampaignDetailFeature()
        }
    }

    /// 建立顯示開團 C1 的詳情狀態
    ///
    /// - Parameters:
    ///   - orders: 唯讀的訂單投影
    ///   - links: 唯讀的提醒連結
    ///   - isShowingUnpaidOnly: 「只看未收款」的初始值
    /// - Returns: 以獨立共用引用建立的詳情狀態
    static func makeState(
        orders: [LedgerOrder] = [],
        links: [Campaign.ID: CampaignReminderLink] = [:],
        isShowingUnpaidOnly: Bool = false
    ) -> CampaignDetailFeature.State {
        CampaignDetailFeature.State(
            campaignID: "C1",
            campaigns: SharedReader(value: [Campaign.fixture(id: "C1", name: "四月團")]),
            orders: SharedReader(value: orders),
            reminderLinks: SharedReader(value: links),
            isShowingUnpaidOnly: Shared(value: isShowingUnpaidOnly)
        )
    }

    /// 建立歸屬開團 C1 的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customerName: 客戶名稱
    ///   - receipt: 收款狀態
    /// - Returns: 金額 100 的訂單
    static func makeOrder(
        id: String,
        customerName: String = "甲",
        receipt: PaymentReceiptStatus
    ) -> LedgerOrder {
        LedgerOrder.fixture(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "客", tier: .regular),
            chargedAmount: 100,
            campaignNames: ["四月團"],
            paymentReceiptStatus: receipt
        )
    }

    /// 以指定語言的資源目錄解析本地化值，不受測試程序預設語言影響
    ///
    /// - Parameters:
    ///   - resource: 畫面狀態或內容提供的本地化值
    ///   - language: 測試指定的 App 語言
    /// - Returns: 以指定語言解析後的文字
    /// - Throws: 指定語言的資源目錄不存在時由 `#require` 丟出
    static func localizedText(
        _ resource: LocalizedStringResource,
        language: AppLanguage
    ) throws -> String {
        let bundleURL = try #require(
            Bundle.main.url(forResource: language.localeIdentifier, withExtension: "lproj")
        )
        let bundle = try #require(Bundle(url: bundleURL))
        return String(
            localized: resource.defaultValue,
            table: resource.table,
            bundle: bundle,
            locale: language.locale
        )
    }
}
