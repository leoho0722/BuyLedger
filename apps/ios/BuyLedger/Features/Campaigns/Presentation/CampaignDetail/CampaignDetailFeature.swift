//
//  CampaignDetailFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

/// 開團詳情：提供畫面內容與「只看未收款」，其餘操作都以請求交給開團容器處理 (沒有非同步 effect)
@Reducer
struct CampaignDetailFeature {

    // MARK: - State

    /// 詳情狀態，只讀開團、訂單與提醒連結，只寫共用的「只看未收款」
    @ObservableState
    struct State: Equatable {

        /// 要顯示詳情的開團識別值
        let campaignID: Campaign.ID

        /// 開團清單，由容器持有、這裡唯讀
        @SharedReader var campaigns: [Campaign]

        /// 訂單投影，由根功能同步、這裡唯讀
        @SharedReader var orders: [LedgerOrder]

        /// 各開團的提醒連結，由提醒子 Feature 寫入、這裡唯讀
        @SharedReader var reminderLinks: [Campaign.ID: CampaignReminderLink]

        /// 「只看未收款」篩選，跨導覽保留，只有本 Feature 寫入
        @Shared var isShowingUnpaidOnly: Bool

        /// 詳情畫面要呈現的內容；開團不存在時為 `nil`
        var content: CampaignDetailContent? {
            CampaignDetailContent.make(
                campaignID: campaignID,
                campaigns: campaigns,
                orders: orders,
                links: reminderLinks,
                isShowingUnpaidOnly: isShowingUnpaidOnly
            )
        }

        /// 分貨區沒有可見客戶時的空狀態文案；只看未收款時表示客戶都已收款
        var distributionEmptyMessage: LocalizedStringResource {
            isShowingUnpaidOnly ? "campaigns.detail.message.allOrdersPaid" : "campaigns.detail.message.ordersAssignedCampaign"
        }

        /// 以容器共用的資料建立詳情狀態
        ///
        /// - Parameters:
        ///   - campaignID: 要顯示詳情的開團識別值
        ///   - campaigns: 唯讀的開團清單
        ///   - orders: 唯讀的訂單投影
        ///   - reminderLinks: 唯讀的提醒連結
        ///   - isShowingUnpaidOnly: 可寫的「只看未收款」篩選
        init(
            campaignID: Campaign.ID,
            campaigns: SharedReader<[Campaign]>,
            orders: SharedReader<[LedgerOrder]>,
            reminderLinks: SharedReader<[Campaign.ID: CampaignReminderLink]>,
            isShowingUnpaidOnly: Shared<Bool>
        ) {
            self.campaignID = campaignID
            self._campaigns = campaigns
            self._orders = orders
            self._reminderLinks = reminderLinks
            self._isShowingUnpaidOnly = isShowingUnpaidOnly
        }
    }

    // MARK: - Action

    /// 詳情畫面的操作與交給容器的請求
    enum Action {

        /// 使用者在詳情畫面上的操作
        ///
        /// - Parameter action: 實際的操作
        case view(View)

        /// 交給開團容器處理的請求
        ///
        /// - Parameter action: 容器要處理的事件
        case delegate(Delegate)

        /// 使用者在詳情畫面送出的操作
        @CasePathable
        enum View {

            /// 點擊編輯開團
            case editTapped

            /// 點擊結團
            case settleTapped

            /// 選擇新的開團狀態
            ///
            /// - Parameter status: 選定的開團狀態
            case statusChanged(CampaignStatus)

            /// 點擊刪除開團
            case deleteTapped

            /// 點擊單筆訂單的收款鍵
            ///
            /// - Parameter orderID: 要切換收款狀態的訂單識別值
            case receiptToggleTapped(LedgerOrder.ID)

            /// 切換「只看未收款」
            ///
            /// - Parameter isOn: 是否只顯示未收款的客戶
            case unpaidOnlyToggled(Bool)
        }

        /// 交給開團容器處理的事件
        @CasePathable
        enum Delegate: Equatable {

            /// 要求容器執行開團操作
            ///
            /// - Parameter request: 開團操作
            case requested(CampaignRequest)
        }
    }

    // MARK: - Body

    /// 只組合 reducer，操作由 `core(state:action:)` 處理
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension CampaignDetailFeature {

    /// 把詳情操作轉成容器請求，只有「只看未收款」在本層寫入共用值
    ///
    /// - Parameters:
    ///   - state: 詳情狀態
    ///   - action: 使用者操作
    /// - Returns: 交給容器的請求；寫入共用值或找不到訂單時不送出
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.editTapped):
            return .send(.delegate(.requested(.edit(state.campaignID))))

        case .view(.settleTapped):
            return .send(.delegate(.requested(.settle(state.campaignID))))

        case .view(.statusChanged(let status)):
            return .send(.delegate(.requested(.changeStatus(id: state.campaignID, status: status))))

        case .view(.deleteTapped):
            return .send(.delegate(.requested(.delete(state.campaignID))))

        case .view(.receiptToggleTapped(let orderID)):
            guard let order = state.orders.first(where: { $0.id == orderID }) else {
                return .none
            }
            let nextStatus: PaymentReceiptStatus = order.paymentReceiptStatus == .received
                ? .pending
                : .received
            return .send(
                .delegate(.requested(.toggleReceipt(orderID: orderID, status: nextStatus)))
            )

        case .view(.unpaidOnlyToggled(let isOn)):
            state.$isShowingUnpaidOnly.withLock { $0 = isOn }
            return .none

        case .delegate:
            return .none
        }
    }
}
