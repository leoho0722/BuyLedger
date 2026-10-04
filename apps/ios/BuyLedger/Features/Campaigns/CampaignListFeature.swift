//
//  CampaignListFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

/// 開團列表的載入、重試、自動結束、篩選與日期投影
@Reducer
struct CampaignListFeature {

    // MARK: - State

    /// 列表狀態，共用開團主檔並唯讀訂單投影
    @ObservableState
    struct State: Equatable {

        /// 目前的開團清單，與容器及寫入子層共用
        @Shared var campaigns: [Campaign]

        /// 根功能提供的唯讀訂單投影
        @SharedReader var orders: [LedgerOrder]

        /// 所選狀態；`nil` 表示全部
        var statusFilter: CampaignStatus?

        /// 日期分組粒度
        var grouping: CampaignGrouping = .day

        /// 是否正在載入
        var isLoading = false

        /// 是否已完成載入，列表再次出現時會略過讀取
        var hasLoaded = false

        /// 列表內持續顯示的載入失敗訊息
        var errorMessage: String?

        /// 最近一次列表出現或重試時記錄的現在時間與行事曆
        var dateContext: CampaignDateContext?

        /// 依載入結果解析畫面狀態
        var loadState: LoadState {
            if hasLoaded {
                return .loaded
            }
            if let errorMessage {
                return .failed(errorMessage)
            }
            return .loading
        }

        /// 依記錄的行事曆產生日期區段，尚未記錄時為空
        var dateSections: [CampaignDateSection] {
            guard let dateContext else {
                return []
            }
            return CampaignDateSectionBuilder.sections(
                for: campaigns,
                statusFilter: statusFilter,
                grouping: grouping,
                calendar: dateContext.calendar
            )
        }

        /// 單次掃描訂單，批次建立可見開團的列彙總；日期脈絡尚未記錄時為空
        var rowSummaries: [String: CampaignSummary] {
            guard dateContext != nil else {
                return [:]
            }
            let names = campaigns
                .filter { statusFilter == nil || $0.status == statusFilter }
                .map(\.name)
            return CampaignSummary.batch(campaignNames: names, orders: orders)
        }

        /// 建立列表所需的共享資料
        ///
        /// - Parameters:
        ///   - campaigns: 可寫的開團共用引用
        ///   - orders: 唯讀訂單投影
        init(campaigns: Shared<[Campaign]>, orders: SharedReader<[LedgerOrder]>) {
            self._campaigns = campaigns
            self._orders = orders
        }

        /// 列表載入的呈現狀態
        enum LoadState: Equatable {

            /// 已完成載入
            case loaded

            /// 載入失敗
            ///
            /// - Parameter message: 持續顯示的訊息
            case failed(String)

            /// 正在載入或尚未開始載入
            case loading
        }
    }

    // MARK: - Action

    /// 列表畫面操作、交給容器的請求與載入回應
    enum Action {

        /// 使用者的列表操作
        ///
        /// - Parameter action: 實際操作
        case view(View)

        /// 交給容器的請求或失敗
        ///
        /// - Parameter action: 容器要處理的事件
        case delegate(Delegate)

        /// 自動結束開團的持久化結果
        ///
        /// - Parameter result: 全部寫入成功或首次寫入失敗
        case autoCloseResponse(Result<Void, PersistenceError>)

        /// 載入開團清單的結果
        ///
        /// - Parameter result: 開團清單或載入錯誤
        case campaignsResponse(Result<[Campaign], PersistenceError>)

        /// 列表畫面送出的操作
        @CasePathable
        enum View {

            /// 列表出現
            case task

            /// 點擊重試
            case retryTapped

            /// 點擊開團列
            ///
            /// - Parameter id: 開團識別值
            case campaignTapped(Campaign.ID)

            /// 選取狀態篩選
            ///
            /// - Parameter status: 所選狀態；`nil` 表示全部
            case statusFilterSelected(CampaignStatus?)

            /// 選取日期分組
            ///
            /// - Parameter grouping: 所選粒度
            case groupingSelected(CampaignGrouping)

            /// 點擊新增開團
            case newCampaignTapped

            /// 點擊編輯開團
            ///
            /// - Parameter id: 開團識別值
            case editCampaignTapped(Campaign.ID)

            /// 點擊刪除開團
            ///
            /// - Parameter id: 開團識別值
            case deleteCampaignTapped(Campaign.ID)
        }

        /// 交給容器處理的事件
        @CasePathable
        enum Delegate: Equatable {

            /// 要求容器執行操作
            ///
            /// - Parameter request: 開團操作
            case requested(CampaignRequest)

            /// 自動結束寫入失敗，請容器呈現通知
            case autoCloseFailed
        }
    }

    // MARK: - Dependencies

    /// 開團資料來源與自動結束的持久化能力
    @Dependency(\.campaignService) private var campaignService

    /// 列表出現與結單判定的現在時間
    @Dependency(\.date) private var date

    /// 日期分組與結單判定所用的行事曆
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// 組合列表的事件處理
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Nested Types

private extension CampaignListFeature {

    /// 開團列表讀取的取消識別值
    enum CancelID: Hashable, Sendable {

        /// 開團清單讀取
        case load
    }
}

// MARK: - Private Method

private extension CampaignListFeature {

    /// 更新列表或將操作交給容器
    ///
    /// - Parameters:
    ///   - state: 列表狀態
    ///   - action: 操作或資料回應
    /// - Returns: 載入、持久化或委派事件
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task), .view(.retryTapped):
            state.dateContext = CampaignDateContext(now: date.now, calendar: calendar)
            if case .view(.task) = action, state.hasLoaded {
                return .none
            }
            return loadCampaigns(state: &state)

        case .view(.campaignTapped(let id)):
            return .send(.delegate(.requested(.showDetail(id))))

        case .view(.statusFilterSelected(let status)):
            state.statusFilter = status
            return .none

        case .view(.groupingSelected(let grouping)):
            state.grouping = grouping
            return .none

        case .view(.newCampaignTapped):
            return .send(.delegate(.requested(.create)))

        case .view(.editCampaignTapped(let id)):
            return .send(.delegate(.requested(.edit(id))))

        case .view(.deleteCampaignTapped(let id)):
            return .send(.delegate(.requested(.delete(id))))

        case .delegate:
            return .none

        case .autoCloseResponse(.success):
            return .none

        case .autoCloseResponse(.failure):
            return .send(.delegate(.autoCloseFailed))

        case .campaignsResponse(.success(let loaded)):
            return applyLoadedCampaigns(loaded, state: &state)

        case .campaignsResponse(.failure):
            state.isLoading = false
            state.errorMessage = "開團載入失敗，請稍後再試。"
            return .none
        }
    }

    /// 開始讀取並取消前一次尚未完成的請求，回送單一結果
    ///
    /// - Parameter state: 要標記載入中的列表狀態
    /// - Returns: 可取消的載入 effect，新請求會取代前一次讀取
    func loadCampaigns(state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let campaignService = campaignService
        return .run { send in
            do throws(PersistenceError) {
                let campaigns = try await campaignService.fetchCampaigns()
                await send(.campaignsResponse(.success(campaigns)))
            } catch {
                await send(.campaignsResponse(.failure(error)))
            }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

    /// 先更新共用開團，再持久化已過結單日的狀態
    ///
    /// - Parameters:
    ///   - loaded: 載入的開團
    ///   - state: 要更新的列表狀態
    /// - Returns: 有自動結束的開團時，依序寫回的 effect
    func applyLoadedCampaigns(_ loaded: [Campaign], state: inout State) -> Effect<Action> {
        state.isLoading = false
        state.hasLoaded = true
        let now = date.now
        var transitioned: [Campaign] = []
        let updated = loaded.map { campaign in
            let evaluated = campaign.evaluatingAutoClose(asOf: now, calendar: calendar)
            if evaluated.status != campaign.status {
                transitioned.append(evaluated)
            }
            return evaluated
        }
        state.$campaigns.withLock { $0 = updated }
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
}
