//
//  CampaignWritesFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

/// 執行開團寫入，成功後更新共用開團並交回改名、刪除與提醒意圖
@Reducer
struct CampaignWritesFeature {

    // MARK: - State

    /// 與開團容器共用的寫入成功資料
    @ObservableState
    struct State: Equatable {

        /// 開團清單，只有成功的寫入回應更新
        @Shared var campaigns: [Campaign]

        /// 接收父層持有的共用開團引用
        ///
        /// - Parameter campaigns: 父層的共用開團清單
        init(campaigns: Shared<[Campaign]>) {
            self._campaigns = campaigns
        }
    }

    // MARK: - Action

    /// 父層請求、持久化回應與交回父層的寫入結果
    enum Action {

        /// 交回父層的結果
        ///
        /// - Parameter action: 寫入失敗、完成或跨功能同步意圖
        case delegate(Delegate)

        /// 刪除開團與本機提醒連結
        ///
        /// - Parameters:
        ///   - id: 開團識別值
        ///   - name: 要清除的訂單歸屬名稱
        case deleteRequested(id: Campaign.ID, name: String)

        /// 本機刪除交易的回應
        ///
        /// - Parameter result: 刪除資料與事件識別碼，或持久化錯誤
        case deleteResponse(Result<Deletion, PersistenceError>)

        /// 儲存開團，成功後接續改名與提醒意圖
        ///
        /// - Parameter plan: 已驗證並組裝完成的儲存計畫
        case saveRequested(CampaignSavePlan)

        /// 開團儲存的回應
        ///
        /// - Parameter result: 已儲存的計畫或持久化錯誤
        case saveResponse(Result<CampaignSavePlan, PersistenceError>)

        /// 寫入結算日期
        ///
        /// - Parameter id: 要結團的開團識別值
        case settleRequested(Campaign.ID)

        /// 結算日期寫入的回應
        ///
        /// - Parameter result: 寫入時的開團快照或持久化錯誤
        case settleResponse(Result<Campaign, PersistenceError>)

        /// 寫入開團狀態
        ///
        /// - Parameters:
        ///   - id: 開團識別值
        ///   - status: 要套用的新狀態
        case statusChangeRequested(id: Campaign.ID, status: CampaignStatus)

        /// 開團狀態寫入的回應
        ///
        /// - Parameter result: 寫入時的開團快照或持久化錯誤
        case statusResponse(Result<Campaign, PersistenceError>)

        /// 由容器呈現或轉送的寫入結果
        @CasePathable
        enum Delegate: Equatable {

            /// 寫入失敗，需要容器呈現提示
            ///
            /// - Parameter failure: 失敗的寫入種類
            case failed(Failure)

            /// 儲存與改名已處理完成，可接續提醒
            ///
            /// - Parameter reminder: 待執行的提醒調解；無需調解時為 `nil`
            case saved(CampaignReminderRequest?)

            /// 訂單歸屬已改名，需要根功能同步副本
            ///
            /// - Parameters:
            ///   - from: 原名稱
            ///   - to: 新名稱
            case renamed(from: String, to: String)

            /// 本機刪除成功，需要同步訂單副本與移除行事曆事件
            ///
            /// - Parameter deletion: 刪除的開團與交易回傳的事件識別碼
            case deleted(Deletion)
        }
    }

    // MARK: - Dependencies

    /// 開團儲存與刪除交易
    @Dependency(\.campaignService) private var campaignService

    /// 確認結團當下的結算時間
    @Dependency(\.date) private var date

    // MARK: - Body

    /// 組合寫入流程，不持有畫面或提示
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension CampaignWritesFeature {

    /// 刪除交易完成後要同步的開團與提醒事件
    struct Deletion: Equatable, Sendable {

        /// 已刪除的開團識別值
        let id: Campaign.ID

        /// 已刪除的開團名稱
        let name: String

        /// 本機交易刪除的提醒連結事件識別碼；沒有連結時為 `nil`
        let eventIdentifier: String?
    }

    /// 由容器對應成提示文案的寫入種類
    enum Failure: Equatable, Sendable {

        /// 開團儲存失敗
        case save

        /// 本機刪除交易失敗
        case delete

        /// 開團狀態寫入失敗
        case status

        /// 結算日期寫入失敗
        case settle
    }
}

// MARK: - Private Method

private extension CampaignWritesFeature {

    /// 執行寫入請求並在成功回應更新共用開團
    ///
    /// - Parameters:
    ///   - state: 共用開團的寫入狀態
    ///   - action: 請求、回應或交回父層的結果
    /// - Returns: 後續寫入或交回父層的事件
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .deleteRequested(let id, let name):
            let campaignService = campaignService
            return .run { send in
                do throws(PersistenceError) {
                    let eventIdentifier = try await campaignService.removeCampaign(id, name)
                    let deletion = Deletion(id: id, name: name, eventIdentifier: eventIdentifier)
                    await send(.deleteResponse(.success(deletion)))
                } catch {
                    await send(.deleteResponse(.failure(error)))
                }
            }

        case .deleteResponse(.success(let deletion)):
            state.$campaigns.withLock {
                $0.removeAll {
                    $0.id == deletion.id
                }
            }
            return .send(.delegate(.deleted(deletion)))

        case .deleteResponse(.failure):
            return .send(.delegate(.failed(.delete)))

        case .saveRequested(let plan):
            return persistSave(plan)

        case .saveResponse(.success(let plan)):
            return applySaved(plan, state: &state)

        case .saveResponse(.failure):
            return .send(.delegate(.failed(.save)))

        case .settleRequested(let id):
            guard var campaign = state.campaigns.first(where: { $0.id == id }),
                  campaign.settledDate == nil else {
                return .none
            }
            campaign.settledDate = date.now
            return save(campaign, response: Action.settleResponse)

        case .settleResponse(.success(let campaign)):
            guard let index = state.campaigns.firstIndex(where: { $0.id == campaign.id }) else {
                return .none
            }
            state.$campaigns.withLock { $0[index].settledDate = campaign.settledDate }
            return .none

        case .settleResponse(.failure):
            return .send(.delegate(.failed(.settle)))

        case .statusChangeRequested(let id, let status):
            guard var campaign = state.campaigns.first(where: { $0.id == id }),
                  campaign.status != status else {
                return .none
            }
            campaign.status = status
            return save(campaign, response: Action.statusResponse)

        case .statusResponse(.success(let campaign)):
            guard let index = state.campaigns.firstIndex(where: { $0.id == campaign.id }) else {
                return .none
            }
            state.$campaigns.withLock { $0[index].status = campaign.status }
            return .none

        case .statusResponse(.failure):
            return .send(.delegate(.failed(.status)))
        }
    }

    /// 寫入開團儲存計畫，有改名時連同訂單內的開團名稱一併改寫，結果以 `saveResponse` 送回
    ///
    /// - Parameter plan: 已驗證並組裝完成的儲存計畫
    /// - Returns: 執行寫入並派送儲存回應的 Effect
    func persistSave(_ plan: CampaignSavePlan) -> Effect<Action> {
        let campaignService = campaignService
        return .run { send in
            do throws(PersistenceError) {
                if let rename = plan.rename {
                    try await campaignService.renameCampaign(plan.campaign, rename.from)
                } else {
                    try await campaignService.saveCampaign(plan.campaign)
                }
                await send(.saveResponse(.success(plan)))
            } catch {
                await send(.saveResponse(.failure(error)))
            }
        }
    }

    /// 把已儲存的開團依開團日期由新到舊寫入共用清單，有改名時先送出改名通知再送出儲存完成
    ///
    /// - Parameters:
    ///   - plan: 已儲存的計畫
    ///   - state: 共用開團的寫入狀態
    /// - Returns: 沒有改名時直接送出儲存完成；有改名時先送出改名通知再送出儲存完成的效果
    func applySaved(_ plan: CampaignSavePlan, state: inout State) -> Effect<Action> {
        let index = state.campaigns.firstIndex(where: { $0.id == plan.campaign.id })
        state.$campaigns.withLock {
            if let index {
                $0[index] = plan.campaign
            } else {
                $0.append(plan.campaign)
            }
            $0.sort { lhs, rhs in
                lhs.openDate > rhs.openDate
            }
        }
        guard let rename = plan.rename else {
            return .send(.delegate(.saved(plan.reminder)))
        }
        return .concatenate(
            .send(.delegate(.renamed(from: rename.from, to: rename.to))),
            .send(.delegate(.saved(plan.reminder)))
        )
    }

    /// 寫入開團快照，將成功與失敗合併成呼叫端指定的回應
    ///
    /// - Parameters:
    ///   - campaign: 待寫入的開團快照
    ///   - response: 將持久化結果包成此次請求的回應
    /// - Returns: 執行一次儲存並派送回應的操作
    func save(
        _ campaign: Campaign,
        response: @escaping @Sendable (Result<Campaign, PersistenceError>) -> Action
    ) -> Effect<Action> {
        let campaignService = campaignService
        return .run { send in
            do throws(PersistenceError) {
                try await campaignService.saveCampaign(campaign)
                await send(response(.success(campaign)))
            } catch {
                await send(response(.failure(error)))
            }
        }
    }
}
