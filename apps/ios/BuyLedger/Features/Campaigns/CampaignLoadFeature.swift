//
//  CampaignLoadFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture

/// 載入開團並評估自動結單，將資料與載入狀態提供給容器及列表
@Reducer
struct CampaignLoadFeature {

    // MARK: - State

    /// 開團與載入狀態的共用來源
    @ObservableState
    struct State: Equatable {

        /// 與容器共用的開團資料
        @Shared var campaigns: [Campaign]

        /// 是否正在讀取開團
        @Shared var isLoading: Bool

        /// 是否已成功讀取開團
        @Shared var hasLoaded: Bool

        /// 列表持續顯示的讀取失敗訊息
        @Shared var errorMessage: String?

        /// 建立開團引用與獨立的載入狀態
        ///
        /// - Parameter campaigns: 容器持有的開團引用
        init(campaigns: Shared<[Campaign]>) {
            self._campaigns = campaigns
            self._isLoading = Shared(value: false)
            self._hasLoaded = Shared(value: false)
            self._errorMessage = Shared(value: nil)
        }
    }

    // MARK: - Action

    /// 父層請求、向父層回報的失敗與讀寫回應
    enum Action {

        /// 交給容器處理的失敗結果
        ///
        /// - Parameter action: 載入或自動結單失敗
        case delegate(Delegate)

        /// 自動結單的持久化結果
        ///
        /// - Parameter result: 全部成功或首次失敗
        case autoCloseResponse(Result<Void, PersistenceError>)

        /// 開團讀取結果
        ///
        /// - Parameter result: 開團清單或讀取失敗
        case campaignsResponse(Result<[Campaign], PersistenceError>)

        /// 父層要求載入，載入中或已成功載入時略過
        case loadRequested

        /// 載入流程需要容器處理的結果
        @CasePathable
        enum Delegate: Equatable {

            /// 載入失敗，列表已取得持續顯示的訊息
            case loadFailed

            /// 自動結單寫入失敗，請容器呈現既有通知
            case autoCloseFailed
        }
    }

    // MARK: - Dependencies

    /// 開團讀取與自動結單的持久化能力
    @Dependency(\.campaignService) private var campaignService

    /// 收到讀取結果時評估結單的現在時間
    @Dependency(\.date) private var date

    /// 結單日期所屬的行事曆與時區
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// 組合開團載入的事件處理
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension CampaignLoadFeature {

    /// 處理載入請求及讀寫回應，共用資料一律在 reducer 內更新
    ///
    /// - Parameters:
    ///   - state: 開團與載入狀態
    ///   - action: 父層請求或讀寫結果
    /// - Returns: 讀取、寫回或失敗委派事件
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate, .autoCloseResponse(.success):
            return .none

        case .autoCloseResponse(.failure):
            return .send(.delegate(.autoCloseFailed))

        case .campaignsResponse(.success(let loaded)):
            return applyLoadedCampaigns(loaded, state: &state)

        case .campaignsResponse(.failure):
            state.$isLoading.withLock {
                $0 = false
            }
            state.$hasLoaded.withLock {
                $0 = false
            }
            state.$errorMessage.withLock {
                $0 = "開團載入失敗，請稍後再試。"
            }
            return .send(.delegate(.loadFailed))

        case .loadRequested:
            return loadCampaigns(state: &state)
        }
    }

    /// 先更新共用開團，再依序持久化已過結單日的狀態
    ///
    /// - Parameters:
    ///   - loaded: 讀取的開團
    ///   - state: 要更新的載入狀態
    /// - Returns: 狀態有改變時依序寫回，首筆失敗即停止
    func applyLoadedCampaigns(_ loaded: [Campaign], state: inout State) -> Effect<Action> {
        state.$isLoading.withLock {
            $0 = false
        }
        state.$hasLoaded.withLock {
            $0 = true
        }
        let now = date.now
        var transitioned: [Campaign] = []
        let updated = loaded.map { campaign in
            let evaluated = campaign.evaluatingAutoClose(asOf: now, calendar: calendar)
            if evaluated.status != campaign.status {
                transitioned.append(evaluated)
            }
            return evaluated
        }
        state.$campaigns.withLock {
            $0 = updated
        }
        guard !transitioned.isEmpty else {
            return .none
        }
        let campaignService = campaignService
        return .run { [transitioned] send in
            do throws(PersistenceError) {
                for campaign in transitioned {
                    try await campaignService.saveCampaign(campaign)
                }
                await send(.autoCloseResponse(.success(())))
            } catch {
                await send(.autoCloseResponse(.failure(error)))
            }
        }
    }

    /// 讀取開團；載入中或已成功讀取時略過，結果以 `campaignsResponse` 送回
    ///
    /// - Parameter state: 要更新的載入狀態，開始讀取時改為載入中並清除舊的失敗訊息
    /// - Returns: 讀取開團的 Effect；已載入或載入中時為 `.none`
    func loadCampaigns(state: inout State) -> Effect<Action> {
        guard !state.isLoading, !state.hasLoaded else {
            return .none
        }
        state.$isLoading.withLock {
            $0 = true
        }
        state.$errorMessage.withLock {
            $0 = nil
        }
        let campaignService = campaignService
        return .run { send in
            do throws(PersistenceError) {
                let campaigns = try await campaignService.fetchCampaigns()
                await send(.campaignsResponse(.success(campaigns)))
            } catch {
                await send(.campaignsResponse(.failure(error)))
            }
        }
    }
}
