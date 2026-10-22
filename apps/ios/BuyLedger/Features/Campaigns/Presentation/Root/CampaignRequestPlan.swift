//
//  CampaignRequestPlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

/// 依開團快照解析請求，交由容器套用的操作值
enum CampaignRequestPlan {

    /// 請求目前不適用
    case none

    /// 顯示開團詳情
    ///
    /// - Parameter id: 開團識別值
    case showDetail(Campaign.ID)

    /// 建立新增或編輯表單
    ///
    /// - Parameters:
    ///   - original: 編輯的開團；新增時為 `nil`
    ///   - link: 既有提醒連結
    case edit(original: Campaign?, link: CampaignReminderLink?)

    /// 呈現刪除或結團確認
    ///
    /// - Parameter destination: 確認目的地
    case present(CampaignPresentationFeature.Destination.State)

    /// 轉送寫入請求或向 Root 委派收款變更
    ///
    /// - Parameter action: 容器要送出的事件
    case send(CampaignFeature.Action)
}

// MARK: - Internal Method

extension CampaignRequestPlan {

    /// 以目前資料解析操作，不改動容器或取用環境相依
    ///
    /// - Parameters:
    ///   - request: 列表或詳情送出的請求
    ///   - campaigns: 目前開團快照
    ///   - reminderLinks: 目前提醒連結快照
    /// - Returns: 容器接續執行的操作
    static func fulfill(
        _ request: CampaignRequest,
        campaigns: [Campaign],
        reminderLinks: [Campaign.ID: CampaignReminderLink]
    ) -> Self {
        switch request {
        case .showDetail(let id):
            return .showDetail(id)

        case .create:
            return .edit(original: nil, link: nil)

        case .edit(let id):
            guard let campaign = campaigns.first(where: { $0.id == id }) else {
                return .none
            }
            return .edit(original: campaign, link: reminderLinks[id])

        case .delete(let id):
            guard let campaign = campaigns.first(where: { $0.id == id }) else {
                return .none
            }
            return .present(.deleteConfirmation(for: campaign))

        case .settle(let id):
            guard let campaign = campaigns.first(where: { $0.id == id }),
                  campaign.settledDate == nil else {
                return .none
            }
            return .present(.settlementConfirmation(for: campaign))

        case .changeStatus(let id, let status):
            return .send(.writes(.statusChangeRequested(id: id, status: status)))

        case .toggleReceipt(let orderID, let status):
            return .send(.delegate(.receiptStatusToggled(orderID: orderID, status: status)))
        }
    }
}
