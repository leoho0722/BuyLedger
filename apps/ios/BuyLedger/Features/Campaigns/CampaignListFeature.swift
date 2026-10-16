//
//  CampaignListFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture

/// 開團列表的載入請求、篩選與日期投影
@Reducer
struct CampaignListFeature {

    // MARK: - State

    /// 列表狀態，共用開團主檔並唯讀訂單投影
    @ObservableState
    struct State: Equatable {

        /// 目前的開團清單，唯讀容器與載入子層共用的資料
        @SharedReader var campaigns: [Campaign]

        /// 根功能提供的唯讀訂單投影
        @SharedReader var orders: [LedgerOrder]

        /// 所選狀態；`nil` 表示全部
        var statusFilter: CampaignStatus?

        /// 日期分組粒度
        var grouping: CampaignGrouping = .day

        /// 是否正在載入
        @SharedReader var isLoading: Bool

        /// 是否已完成載入，由載入子層維護
        @SharedReader var hasLoaded: Bool

        /// 列表內持續顯示的載入失敗訊息
        @SharedReader var errorMessage: String?

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
        var rowSummaries: RowSummaries {
            guard dateContext != nil else {
                return RowSummaries(byName: [:])
            }
            let names = campaigns
                .filter { statusFilter == nil || $0.status == statusFilter }
                .map(\.name)
            return RowSummaries(byName: CampaignSummary.batch(campaignNames: names, orders: orders))
        }

        /// 列表要呈現的日期區段與其日期脈絡；尚未記錄日期脈絡或篩選後沒有區段時為 `nil`
        var visibleSections: VisibleSections? {
            let sections = dateSections
            guard let dateContext, !sections.isEmpty else {
                return nil
            }
            return VisibleSections(sections: sections, dateContext: dateContext)
        }

        /// 建立列表所需的唯讀共享資料
        ///
        /// - Parameters:
        ///   - campaigns: 唯讀開團共用引用
        ///   - orders: 唯讀訂單投影
        ///   - isLoading: 載入中的共用旗標
        ///   - hasLoaded: 已完成載入的共用旗標
        ///   - errorMessage: 共用載入錯誤訊息
        init(
            campaigns: SharedReader<[Campaign]>,
            orders: SharedReader<[LedgerOrder]>,
            isLoading: SharedReader<Bool> = SharedReader(value: false),
            hasLoaded: SharedReader<Bool> = SharedReader(value: false),
            errorMessage: SharedReader<String?> = SharedReader(value: nil)
        ) {
            self._campaigns = campaigns
            self._orders = orders
            self._isLoading = isLoading
            self._hasLoaded = hasLoaded
            self._errorMessage = errorMessage
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

    /// 列表畫面操作與交給容器的請求
    enum Action {

        /// 使用者的列表操作
        ///
        /// - Parameter action: 實際操作
        case view(View)

        /// 交給容器的請求
        ///
        /// - Parameter action: 容器要處理的事件
        case delegate(Delegate)

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

            /// 列表出現或重試，請容器要求載入
            case loadRequested
        }
    }

    // MARK: - Dependencies

    /// 列表出現與重試的現在時間
    @Dependency(\.date) private var date

    /// 日期分組所用的行事曆
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// 組合列表的事件處理
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension CampaignListFeature {

    /// 列表各列的開團彙總，依開團名稱取用
    struct RowSummaries: Equatable, Sendable {

        /// 開團名稱到彙總的字典，只含投影過的名稱
        let byName: [String: CampaignSummary]

        /// 依開團名稱取得列彙總；未投影的名稱回傳沒有訂單的空彙總
        ///
        /// - Parameter name: 開團名稱
        /// - Returns: 該開團的彙總
        func summary(forCampaignNamed name: String) -> CampaignSummary {
            byName[name] ?? CampaignSummary(campaignName: name, orders: [])
        }
    }

    /// 列表要呈現的日期區段與區段標題所用的日期脈絡
    struct VisibleSections: Equatable, Sendable {

        /// 已依篩選與分組算好的頂層日期區段
        let sections: [CampaignDateSection]

        /// 列表出現時記錄的現在時間與行事曆，用來判斷「今天」「昨天」
        let dateContext: CampaignDateContext
    }
}

// MARK: - Private Method

private extension CampaignListFeature {

    /// 更新列表或將操作交給容器
    ///
    /// - Parameters:
    ///   - state: 列表狀態
    ///   - action: 操作或資料回應
    /// - Returns: 載入需求或使用者請求的委派事件
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task), .view(.retryTapped):
            state.dateContext = CampaignDateContext(now: date.now, calendar: calendar)
            return .send(.delegate(.loadRequested))

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
        }
    }
}
