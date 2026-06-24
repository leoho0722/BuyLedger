//
//  CampaignFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation

/// 開團列表的頂層日期區段 (依目前分組粒度：日／月／年)
///
/// 採兩層結構：頂層為 ``CampaignGrouping`` 對應的粒度 (例如「月」)，其下再以更細一級的粒度切成 ``CampaignSubgroup`` (例如「日」)。「按日分組」時頂層即最細，僅含一個 `title` 為 `nil` 的子群組
struct CampaignDateSection: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 區段識別值，使用該區段的起始時刻 (start of day／month／year)
    let id: Date

    // MARK: - Data Properties

    /// 頂層區段標題 (例如「今天」「2026年5月」「2026年」)
    let title: String

    /// 該區段下、依更細一級粒度切分的子群組
    let subgroups: [CampaignSubgroup]
}

/// 頂層日期區段下、以更細一級粒度切分的子群組 (例如「月」區段下的「日」群組)
struct CampaignSubgroup: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 子群組識別值，使用該子群組的起始時刻
    let id: Date

    // MARK: - Data Properties

    /// 子標題 (例如「5月27日 週三」「5月」)；`nil` 表示頂層已是最細粒度 (按日分組)，不顯示子標題
    let title: String?

    /// 該子群組內的開團，依開團日期由新到舊排序 (同日再依名稱)
    let campaigns: [Campaign]
}

/// 開團列表的日期分組粒度
enum CampaignGrouping: String, CaseIterable, Identifiable, Sendable {

    // MARK: - Cases

    /// 依「日」分組
    case day

    /// 依「月」分組
    case month

    /// 依「年」分組
    case year

    // MARK: - Identifiable Properties

    /// 分組粒度的穩定識別值
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在選單中的名稱
    var title: String {
        switch self {
        case .day:
            "按日分組"
        case .month:
            "按月分組"
        case .year:
            "按年分組"
        }
    }
}

/// 開團 (Campaign) 列表、狀態切換與 CRUD 流程
///
/// 本 feature 只負責開團主檔本身；分貨清單與結團結算由 ``CampaignSummary`` 自歸屬訂單投影，view 端從 ``RootFeature`` store 讀取 `orders` 後計算。開團改名時以 ``Action/campaignRenamed(from:to:)`` 通知 ``RootFeature`` 做訂單表 cascade 與 ``OrdersFeature`` 副本同步
@Reducer
struct CampaignFeature {

    // MARK: - State

    /// 開團功能狀態
    @ObservableState
    struct State: Equatable {

        /// 目前載入的開團，依開團日期由新到舊排序
        var campaigns: [Campaign] = []

        /// 目前選取的開團識別值 (供 iPad／macOS detail 選取)
        var selectedCampaignID: Campaign.ID?

        /// 目前套用的開團狀態篩選；`nil` 代表全部狀態
        var statusFilter: CampaignStatus?

        /// 目前列表的日期分組粒度
        var grouping: CampaignGrouping = .day

        /// 指示是否正在載入
        var isLoading = false

        /// 是否已完成首次載入；`true` 後再次觸發 ``Action/task`` 直接返回，避免重複載入與閃爍
        var hasLoaded = false

        /// 載入失敗時顯示的錯誤訊息
        var errorMessage: String?

        /// 目前呈現中的新增／編輯開團表單；`nil` 表示未呈現
        @Presents var editCampaign: CampaignEditFeature.State?

        /// 刪除開團前的確認 alert 狀態；`nil` 表示未呈現
        @Presents var deletionConfirmation: AlertState<Action.Alert>?

        // MARK: - Section Method

        /// 將開團依目前 ``grouping`` 粒度分成頂層區段 (比照訂單列表頁)，其下再以更細一級粒度切成子群組：
        /// 按日 → 頂層即「日」、無子標題；按月 → 頂層「月」、子標題「日」；按年 → 頂層「年」、子標題「月」
        ///
        /// 分組與相對標題 (今天／昨天) 皆以 `referenceDate` 與 `calendar` 為基準；同一基準下結果一致
        /// - Parameters:
        ///   - referenceDate: 計算「今天／昨天」等相對標題的「現在」時間
        ///   - calendar: 分組與相對標題所用的行事曆 (含時區)；測試應注入固定 gregorian／UTC
        /// - Returns: 依頂層粒度由新到舊排序的區段；每個子群組內開團依開團日期由新到舊排序 (同日再依名稱)
        func dateSections(referenceDate: Date, calendar: Calendar) -> [CampaignDateSection] {
            let filtered = statusFilter.map { status in
                campaigns.filter { $0.status == status }
            } ?? campaigns
            let topGrouped = Dictionary(grouping: filtered) { campaign in
                topBucketStart(for: campaign.openDate, calendar: calendar)
            }
            return topGrouped.keys
                .sorted(by: >)
                .map { topBucket in
                    CampaignDateSection(
                        id: topBucket,
                        title: topTitle(for: topBucket, referenceDate: referenceDate, calendar: calendar),
                        subgroups: subgroups(
                            of: topGrouped[topBucket] ?? [],
                            referenceDate: referenceDate,
                            calendar: calendar
                        )
                    )
                }
        }

        /// 把頂層區段內的開團，依更細一級粒度切成子群組；按日分組時回傳單一 `title` 為 `nil` 的子群組
        private func subgroups(
            of topCampaigns: [Campaign],
            referenceDate: Date,
            calendar: Calendar
        ) -> [CampaignSubgroup] {
            guard grouping != .day else {
                return [
                    CampaignSubgroup(
                        id: topCampaigns.first.map { calendar.startOfDay(for: $0.openDate) } ?? .distantPast,
                        title: nil,
                        campaigns: sortedByDate(topCampaigns)
                    )
                ]
            }
            let subGrouped = Dictionary(grouping: topCampaigns) { campaign in
                subBucketStart(for: campaign.openDate, calendar: calendar)
            }
            return subGrouped.keys
                .sorted(by: >)
                .map { subBucket in
                    CampaignSubgroup(
                        id: subBucket,
                        title: subTitle(for: subBucket, referenceDate: referenceDate, calendar: calendar),
                        campaigns: sortedByDate(subGrouped[subBucket] ?? [])
                    )
                }
        }

        /// 將開團依開團日期由新到舊排序 (同日再依名稱)
        private func sortedByDate(_ list: [Campaign]) -> [Campaign] {
            list.sorted { lhs, rhs in
                if lhs.openDate != rhs.openDate {
                    return lhs.openDate > rhs.openDate
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }

        /// 頂層分組鍵：按日取當日起始、按月取當月起始、按年取當年起始
        private func topBucketStart(for date: Date, calendar: Calendar) -> Date {
            switch grouping {
            case .day:
                calendar.startOfDay(for: date)
            case .month:
                calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
            case .year:
                calendar.dateInterval(of: .year, for: date)?.start ?? calendar.startOfDay(for: date)
            }
        }

        /// 子群組分組鍵：按月時以「日」切、按年時以「月」切 (按日無子群組，不使用)
        private func subBucketStart(for date: Date, calendar: Calendar) -> Date {
            switch grouping {
            case .day, .month:
                calendar.startOfDay(for: date)
            case .year:
                calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
            }
        }

        /// 頂層標題：日 → 今天／昨天／日期；月 → yyyy年M月；年 → yyyy年
        private func topTitle(for bucket: Date, referenceDate: Date, calendar: Calendar) -> String {
            switch grouping {
            case .day:
                OrderFormatters.daySectionTitle(for: bucket, referenceDate: referenceDate, calendar: calendar)
            case .month:
                bucket.formatted(.dateTime.year().month().locale(Locale(identifier: "zh_TW")))
            case .year:
                bucket.formatted(.dateTime.year().locale(Locale(identifier: "zh_TW")))
            }
        }

        /// 子標題：按月 → 日 (今天／昨天／5月27日 週三)；按年 → 月 (例如「5月」)
        private func subTitle(for bucket: Date, referenceDate: Date, calendar: Calendar) -> String {
            switch grouping {
            case .day, .month:
                OrderFormatters.daySectionTitle(for: bucket, referenceDate: referenceDate, calendar: calendar)
            case .year:
                "\(calendar.component(.month, from: bucket))月"
            }
        }
    }

    // MARK: - Action

    /// 開團功能可處理的事件
    @CasePathable
    enum Action: Equatable {

        /// 畫面出現時觸發載入
        case task

        /// 開團載入成功 (載入後會套用結單日自動轉狀態)
        case campaignsLoaded([Campaign])

        /// 開團載入失敗
        case campaignsFailed(String)

        /// 使用者選取開團
        case campaignSelected(Campaign.ID?)

        /// 使用者切換開團狀態篩選 (`nil` = 全部)
        case statusFilterSelected(CampaignStatus?)

        /// 使用者切換列表日期分組粒度 (日／月／年)
        case groupingSelected(CampaignGrouping)

        /// 使用者點擊「新增開團」
        case newCampaignTapped

        /// 使用者點擊「編輯」指定開團
        case editCampaignTapped(Campaign.ID)

        /// 新增／編輯開團表單事件
        case editCampaign(PresentationAction<CampaignEditFeature.Action>)

        /// 使用者切換開團狀態
        case statusChanged(Campaign.ID, CampaignStatus)

        /// 使用者點擊「結團」(設定結算封存日期)
        case settleTapped(Campaign.ID)

        /// 使用者點擊「刪除」開團；先以 ``deletionConfirmation`` 二次確認
        case deleteCampaignTapped(Campaign.ID)

        /// 刪除確認 alert 事件
        case deletionConfirmation(PresentationAction<Alert>)

        /// 開團改名通知；由 ``RootFeature`` 攔截做訂單表 cascade 與 ``OrdersFeature`` 副本同步
        case campaignRenamed(from: String, to: String)

        /// 刪除確認 alert 的選項
        @CasePathable
        enum Alert: Equatable {

            /// 使用者確認刪除指定開團
            case confirmDelete(Campaign.ID)
        }
    }

    // MARK: - Dependency Properties

    /// 開團主檔資料來源
    @Dependency(CampaignRepository.self) private var campaignRepository

    /// 訂單資料來源；開團改名時用於 cascade 更新所有歸屬訂單的 ``LedgerOrder/campaignNames`` (DB 端)
    @Dependency(OrderRepository.self) private var orderRepository

    /// 用於新開團的日期來源，方便在測試中注入固定值
    @Dependency(\.date) private var date

    /// 用於新開團的 UUID 產生器，方便在測試中注入固定值
    @Dependency(\.uuid) private var uuid

    // MARK: - Reducer Body

    /// 開團功能 reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                guard !state.hasLoaded, !state.isLoading else {
                    return .none
                }
                let campaignRepository = campaignRepository
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let campaigns = try await campaignRepository.fetchCampaigns()
                        await send(.campaignsLoaded(campaigns))
                    } catch {
                        await send(.campaignsFailed("開團載入失敗，請稍後再試。"))
                    }
                }

            case let .campaignsLoaded(loaded):
                state.isLoading = false
                state.hasLoaded = true

                // 結單日自動轉狀態：結單日已過期的開團中團，自動轉為已收單
                let now = date.now
                var transitioned: [Campaign] = []
                let updated = loaded.map { campaign -> Campaign in
                    guard campaign.status == .ongoing,
                          let closeDate = campaign.closeDate,
                          closeDate < now else {
                        return campaign
                    }
                    var copy = campaign
                    copy.status = .closed
                    transitioned.append(copy)
                    return copy
                }
                state.campaigns = updated

                guard !transitioned.isEmpty else { return .none }
                let campaignRepository = campaignRepository
                let transitionedToSave = transitioned
                return .run { _ in
                    for campaign in transitionedToSave {
                        try? await campaignRepository.saveCampaign(campaign)
                    }
                }

            case let .campaignsFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .campaignSelected(id):
                state.selectedCampaignID = id
                return .none

            case let .statusFilterSelected(status):
                state.statusFilter = status
                return .none

            case let .groupingSelected(grouping):
                state.grouping = grouping
                return .none

            case .newCampaignTapped:
                state.editCampaign = CampaignEditFeature.State(currentDate: date.now)
                return .none

            case let .editCampaignTapped(id):
                guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                    return .none
                }
                state.editCampaign = CampaignEditFeature.State(original: campaign, currentDate: date.now)
                return .none

            case .editCampaign(.presented(.saveTapped)):
                guard let editState = state.editCampaign else { return .none }
                let trimmedName = editState.draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return .none }

                let id = editState.original?.id ?? uuid().uuidString
                let oldName = editState.original?.name
                let campaign = Campaign(
                    id: id,
                    name: trimmedName,
                    openDate: editState.draftOpenDate,
                    closeDate: editState.draftCloseDate,
                    status: editState.draftStatus,
                    settledDate: editState.original?.settledDate,
                    notes: editState.draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                upsert(campaign, into: &state)

                let campaignRepository = campaignRepository
                let orderRepository = orderRepository
                let didRename = oldName != nil && oldName != trimmedName
                return .run { send in
                    try? await campaignRepository.saveCampaign(campaign)
                    if didRename, let oldName {
                        // DB 端 cascade：更新所有歸屬此開團的訂單；in-memory 副本由 RootFeature 攔截 campaignRenamed 處理
                        try? await orderRepository.renameOrderCampaign(oldName, trimmedName)
                        await send(.campaignRenamed(from: oldName, to: trimmedName))
                    }
                }

            case .editCampaign:
                return .none

            case let .statusChanged(id, newStatus):
                guard let index = state.campaigns.firstIndex(where: { $0.id == id }),
                      state.campaigns[index].status != newStatus else {
                    return .none
                }
                state.campaigns[index].status = newStatus
                let updated = state.campaigns[index]
                let campaignRepository = campaignRepository
                return .run { _ in
                    try? await campaignRepository.saveCampaign(updated)
                }

            case let .settleTapped(id):
                guard let index = state.campaigns.firstIndex(where: { $0.id == id }),
                      state.campaigns[index].settledDate == nil else {
                    return .none
                }
                state.campaigns[index].settledDate = date.now
                let updated = state.campaigns[index]
                let campaignRepository = campaignRepository
                return .run { _ in
                    try? await campaignRepository.saveCampaign(updated)
                }

            case let .deleteCampaignTapped(id):
                guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                    return .none
                }
                state.deletionConfirmation = AlertState {
                    TextState("刪除開團")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(id)) {
                        TextState("刪除")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState("「\(campaign.name)」將被刪除，此操作無法復原。歸屬此開團的訂單不會被刪除，但會變回未歸團。")
                }
                return .none

            case let .deletionConfirmation(.presented(.confirmDelete(id))):
                state.campaigns.removeAll { $0.id == id }
                if state.selectedCampaignID == id {
                    state.selectedCampaignID = state.campaigns.first?.id
                }
                let campaignRepository = campaignRepository
                return .run { _ in
                    try? await campaignRepository.removeCampaign(id)
                }

            case .deletionConfirmation:
                return .none

            case .campaignRenamed:
                // 訂單表 cascade 與 OrdersFeature 副本同步由 RootFeature 攔截處理
                return .none
            }
        }
        .ifLet(\.$editCampaign, action: \.editCampaign) {
            CampaignEditFeature()
        }
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
    }

    // MARK: - Private Method

    /// 把開團 upsert 進 ``State/campaigns`` (依 id 取代或新增)，並維持依開團日期由新到舊排序
    /// - Parameters:
    ///   - campaign: 要寫入的開團
    ///   - state: 將被修改的 ``State``
    private func upsert(_ campaign: Campaign, into state: inout State) {
        if let index = state.campaigns.firstIndex(where: { $0.id == campaign.id }) {
            state.campaigns[index] = campaign
        } else {
            state.campaigns.append(campaign)
        }
        state.campaigns.sort { $0.openDate > $1.openDate }
    }
}
