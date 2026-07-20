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

    /// 依 App 選定 locale 格式化的子標題；`nil` 表示頂層已是最細粒度 (按日分組)，不顯示子標題
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

        /// 目前選取的開團識別值 (供 iPad detail 選取)
        var selectedCampaignID: Campaign.ID?

        /// 目前套用的開團狀態篩選；`nil` 代表全部狀態
        var statusFilter: CampaignStatus?

        /// 目前列表的日期分組粒度
        var grouping: CampaignGrouping = .day

        /// 開團詳情頁「只看未收款」的分貨篩選；跨導覽存活於 feature state，不隨 view 重建重置
        var showsUnpaidOnly = false

        /// 指示是否正在載入
        var isLoading = false

        /// 是否已完成首次載入；`true` 後再次觸發 ``Action/task`` 直接返回，避免重複載入與閃爍
        var hasLoaded = false

        /// 載入失敗時顯示的錯誤訊息
        var errorMessage: String?

        /// 每個開團目前的提醒連結 (事件識別碼 + 提示時間)；有值代表該開團已建立訂購提醒
        var reminderLinks: [Campaign.ID: CampaignReminderLink] = [:]

        /// 目前呈現中的新增／編輯開團表單；`nil` 表示未呈現
        @Presents var editCampaign: CampaignEditFeature.State?

        /// 刪除開團前的確認 alert 狀態；`nil` 表示未呈現
        @Presents var deletionConfirmation: AlertState<Action.Alert>?

        /// 行事曆權限被拒時的提示 alert；`nil` 表示未呈現
        @Presents var reminderAccessAlert: AlertState<Action.ReminderAlert>?
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

        /// 使用者切換開團詳情「只看未收款」篩選
        case unpaidOnlyToggled(Bool)

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

        /// 提醒連結載入完成 (campaignID → 連結資料)
        case reminderLinksLoaded([Campaign.ID: CampaignReminderLink])

        /// 提醒建立或移除後更新記憶體連結；`link` 為 `nil` 表示已移除
        case reminderStored(Campaign.ID, CampaignReminderLink?)

        /// 行事曆權限被拒，彈出提示 alert
        case reminderAccessDenied

        /// 權限已授予但提醒建立失敗，彈出不提及權限的提示 alert
        case reminderCreationFailed

        /// 權限提示 alert 事件
        case reminderAccessAlert(PresentationAction<ReminderAlert>)

        /// 刪除確認 alert 的選項
        @CasePathable
        enum Alert: Equatable {

            /// 使用者確認刪除指定開團
            case confirmDelete(Campaign.ID)
        }

        /// 權限提示 alert 的選項；僅「知道了」關閉，無自訂動作
        @CasePathable
        enum ReminderAlert: Equatable {}
    }

    // MARK: - Dependency Properties

    /// 開團主檔資料來源
    @Dependency(CampaignRepository.self) private var campaignRepository

    /// 訂單資料來源；開團改名時用於 cascade 更新所有歸屬訂單的 ``LedgerOrder/campaignNames`` (DB 端)
    @Dependency(OrderRepository.self) private var orderRepository

    /// 開團訂購提醒與系統行事曆整合的介面
    @Dependency(CalendarReminderClient.self) private var calendarReminderClient

    /// 開團訂購提醒連結 (campaignID → eventIdentifier) 的資料來源
    @Dependency(CampaignReminderRepository.self) private var reminderRepository

    /// 用於新開團的日期來源，方便在測試中注入固定值
    @Dependency(\.date) private var date

    /// 用於計算提醒事件「當天 09:00」的行事曆 (含時區)，方便在測試中注入固定值
    @Dependency(\.calendar) private var calendar

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
                let reminderRepository = reminderRepository
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let campaigns = try await campaignRepository.fetchCampaigns()
                        await send(.campaignsLoaded(campaigns))
                    } catch {
                        await send(.campaignsFailed("開團載入失敗，請稍後再試。"))
                    }

                    if let links = try? await reminderRepository.fetchLinks() {
                        await send(.reminderLinksLoaded(links))
                    }
                }

            case let .campaignsLoaded(loaded):
                state.isLoading = false
                state.hasLoaded = true

                // 結單日自動轉狀態：結單日已過期的進行中開團，自動轉為已收單
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

                guard !transitioned.isEmpty else {
                    return .none
                }
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

            case let .unpaidOnlyToggled(showsUnpaidOnly):
                state.showsUnpaidOnly = showsUnpaidOnly
                return .none

            case .newCampaignTapped:
                state.editCampaign = CampaignEditFeature.State(
                    id: uuid(),
                    currentDate: date.now,
                    reminderTimestamp: defaultReminderTimestamp(closeDate: nil)
                )
                return .none

            case let .editCampaignTapped(id):
                guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                    return .none
                }
                let link = state.reminderLinks[id]
                state.editCampaign = CampaignEditFeature.State(
                    original: campaign,
                    id: uuid(),
                    currentDate: date.now,
                    wantsReminder: link != nil,
                    reminderTimestamp: link?.reminderTimestamp ?? defaultReminderTimestamp(closeDate: campaign.closeDate)
                )
                return .none

            case .editCampaign(.presented(.saveTapped)):
                guard let editState = state.editCampaign else {
                    return .none
                }
                let trimmedName = editState.draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    return .none
                }

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

                // 依「是否要提醒」意圖與現有事件差異，決定儲存時對行事曆的調解
                let reminderTitle = campaign.reminderTitle
                let chosenTimestamp = editState.reminderTimestamp
                let reminderEventDate = calendar.startOfDay(for: chosenTimestamp)
                let reminderAlarmOffset = TimeInterval(minuteOfDay(from: chosenTimestamp) * 60)
                let existingLink = state.reminderLinks[id]
                let nameChanged = existingLink != nil && (editState.original.map { $0.reminderTitle != reminderTitle } ?? false)
                let timestampChanged = existingLink.map { $0.reminderTimestamp != chosenTimestamp } ?? false
                let reminderContentChanged = nameChanged || timestampChanged

                let reconcile: CampaignReminderReconcile
                if editState.wantsReminder {
                    if let existingLink {
                        reconcile = reminderContentChanged ? .rebuild(existingLink.eventIdentifier) : .none
                    } else {
                        reconcile = .create
                    }
                } else if let existingLink {
                    reconcile = .remove(existingLink.eventIdentifier)
                } else {
                    reconcile = .none
                }

                let campaignRepository = campaignRepository
                let orderRepository = orderRepository
                let calendarReminderClient = calendarReminderClient
                let reminderRepository = reminderRepository
                let didRename = oldName != nil && oldName != trimmedName
                return .run { send in
                    try await campaignRepository.saveCampaign(campaign)
                    if didRename, let oldName {
                        // DB 端 cascade：更新所有歸屬此開團的訂單；in-memory 副本由 RootFeature 攔截 campaignRenamed 處理
                        try await orderRepository.renameOrderCampaign(oldName, trimmedName)
                        await send(.campaignRenamed(from: oldName, to: trimmedName))
                    }

                    switch reconcile {
                    case .none:
                        break
                    case .create:
                        await Self.addReminder(
                            campaignID: id,
                            title: reminderTitle,
                            date: reminderEventDate,
                            alarmOffset: reminderAlarmOffset,
                            reminderTimestamp: chosenTimestamp,
                            client: calendarReminderClient,
                            repository: reminderRepository,
                            send: send
                        )
                    case let .remove(identifier):
                        await Self.removeReminder(
                            campaignID: id,
                            eventIdentifier: identifier,
                            client: calendarReminderClient,
                            repository: reminderRepository,
                            send: send
                        )
                    case let .rebuild(identifier):
                        try? await calendarReminderClient.removeReminder(identifier)
                        await Self.addReminder(
                            campaignID: id,
                            title: reminderTitle,
                            date: reminderEventDate,
                            alarmOffset: reminderAlarmOffset,
                            reminderTimestamp: chosenTimestamp,
                            client: calendarReminderClient,
                            repository: reminderRepository,
                            send: send
                        )
                    }
                } catch: { _, send in
                    await send(.campaignsFailed("開團儲存失敗，請稍後再試。"))
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
                    try await campaignRepository.saveCampaign(updated)
                } catch: { _, send in
                    await send(.campaignsFailed("開團狀態更新失敗，請稍後再試。"))
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
                    try await campaignRepository.saveCampaign(updated)
                } catch: { _, send in
                    await send(.campaignsFailed("結團失敗，請稍後再試。"))
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
                    try await campaignRepository.removeCampaign(id)
                } catch: { _, send in
                    await send(.campaignsFailed("開團刪除失敗，請稍後再試。"))
                }

            case .deletionConfirmation:
                return .none

            case .campaignRenamed:
                // 訂單表 cascade 與 OrdersFeature 副本同步由 RootFeature 攔截處理
                return .none

            case let .reminderLinksLoaded(links):
                state.reminderLinks = links
                return .none

            case let .reminderStored(id, link):
                state.reminderLinks[id] = link
                return .none

            case .reminderAccessDenied:
                state.reminderAccessAlert = AlertState {
                    TextState("需要行事曆權限")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("知道了")
                    }
                } message: {
                    TextState("請到「設定」開啟行事曆存取權限，才能新增或移除訂購提醒。")
                }
                return .none

            case .reminderCreationFailed:
                // 權限已授予，訊息不得指向權限設定——照做也無法解決真正發生的失敗
                state.reminderAccessAlert = AlertState {
                    TextState("無法建立訂購提醒")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("知道了")
                    }
                } message: {
                    TextState("訂購提醒建立失敗，請稍後再試。")
                }
                return .none

            case .reminderAccessAlert:
                return .none
            }
        }
        .ifLet(\.$editCampaign, action: \.editCampaign) {
            CampaignEditFeature()
        }
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
        .ifLet(\.$reminderAccessAlert, action: \.reminderAccessAlert)
    }
}

// MARK: - Internal Method

extension CampaignFeature.State {

    /// 將開團依目前 ``grouping`` 粒度分成頂層區段 (比照訂單列表頁)，其下再以更細一級粒度切成子群組：
    /// 按日 → 頂層即「日」、無子標題；按月 → 頂層「月」、子標題「日」；按年 → 頂層「年」、子標題「月」
    ///
    /// 分組與相對標題 (今天／昨天) 皆以 `referenceDate` 與 `calendar` 為基準；同一基準下結果一致
    /// - Parameters:
    ///   - referenceDate: 計算「今天／昨天」等相對標題的「現在」時間
    ///   - calendar: 分組與相對標題所用的行事曆 (含時區)；測試應注入固定 gregorian／UTC
    ///   - locale: App 選定、用於日期區段標題的 locale
    /// - Returns: 依頂層粒度由新到舊排序的區段；每個子群組內開團依開團日期由新到舊排序 (同日再依名稱)
    func dateSections(referenceDate: Date, calendar: Calendar, locale: Locale) -> [CampaignDateSection] {
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
                    title: topTitle(
                        for: topBucket,
                        referenceDate: referenceDate,
                        calendar: calendar,
                        locale: locale
                    ),
                    subgroups: subgroups(
                        of: topGrouped[topBucket] ?? [],
                        referenceDate: referenceDate,
                        calendar: calendar,
                        locale: locale
                    )
                )
            }
    }
}

// MARK: - Private Method

private extension CampaignFeature.State {

    /// 把頂層區段內的開團，依更細一級粒度切成子群組；按日分組時回傳單一 `title` 為 `nil` 的子群組
    /// - Parameters:
    ///   - topCampaigns: 頂層區段內的開團
    ///   - referenceDate: 計算相對日期標題的「現在」時間
    ///   - calendar: 分組與標題所用的行事曆
    ///   - locale: App 選定、用於子區段標題的 locale
    func subgroups(
        of topCampaigns: [Campaign],
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
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
                    title: subTitle(
                        for: subBucket,
                        referenceDate: referenceDate,
                        calendar: calendar,
                        locale: locale
                    ),
                    campaigns: sortedByDate(subGrouped[subBucket] ?? [])
                )
            }
    }

    /// 將開團依開團日期由新到舊排序 (同日再依名稱)
    func sortedByDate(_ list: [Campaign]) -> [Campaign] {
        list.sorted { lhs, rhs in
            if lhs.openDate != rhs.openDate {
                return lhs.openDate > rhs.openDate
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    /// 頂層分組鍵：按日取當日起始、按月取當月起始、按年取當年起始
    func topBucketStart(for date: Date, calendar: Calendar) -> Date {
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
    func subBucketStart(for date: Date, calendar: Calendar) -> Date {
        switch grouping {
        case .day, .month:
            calendar.startOfDay(for: date)
        case .year:
            calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    /// 頂層標題：日 → 今天／昨天／日期；月 → yyyy年M月；年 → yyyy年
    /// - Parameters:
    ///   - bucket: 頂層區段的起始日期
    ///   - referenceDate: 計算相對日期標題的「現在」時間
    ///   - calendar: 用於日區段標題的行事曆
    ///   - locale: App 選定、用於日期標題的 locale
    func topTitle(for bucket: Date, referenceDate: Date, calendar: Calendar, locale: Locale) -> String {
        switch grouping {
        case .day:
            OrderFormatters.daySectionTitle(
                for: bucket,
                referenceDate: referenceDate,
                calendar: calendar,
                locale: locale
            )
        case .month:
            bucket.formatted(.dateTime.year().month().locale(locale))
        case .year:
            bucket.formatted(.dateTime.year().locale(locale))
        }
    }

    /// 子標題：按月 → 日 (相對日期或格式化日期)；按年 → 月
    /// - Parameters:
    ///   - bucket: 子區段的起始日期
    ///   - referenceDate: 計算相對日期標題的「現在」時間
    ///   - calendar: 用於日區段標題的行事曆
    ///   - locale: App 選定、用於日期標題的 locale
    func subTitle(for bucket: Date, referenceDate: Date, calendar: Calendar, locale: Locale) -> String {
        switch grouping {
        case .day, .month:
            OrderFormatters.daySectionTitle(
                for: bucket,
                referenceDate: referenceDate,
                calendar: calendar,
                locale: locale
            )
        case .year:
            bucket.formatted(.dateTime.month(.wide).locale(locale))
        }
    }
}

// MARK: - Nested Types

extension CampaignFeature {

    /// 儲存開團時對訂購提醒行事曆事件的調解結果
    private enum CampaignReminderReconcile: Equatable {

        // MARK: - Cases

        /// 不需變更行事曆
        case none

        /// 建立新的提醒事件
        case create

        /// 移除既有事件 (帶其識別碼)
        case remove(String)

        /// 先移除舊事件再以新內容重建 (帶舊識別碼)
        case rebuild(String)
    }
}

// MARK: - Internal Method

extension CampaignFeature {

    /// 每團訂購提醒的預設時間戳：結單日 (無則今天) 當天 09:00
    /// - Parameter closeDate: 該開團的結單日；`nil` 表示無結單日或新開團
    /// - Returns: 預設提醒時間戳
    func defaultReminderTimestamp(closeDate: Date?) -> Date {
        let baseDay = calendar.startOfDay(for: closeDate ?? date.now)
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDay) ?? baseDay
    }

    /// 從提醒時間戳取出「當天第幾分鐘」，供換算全天事件的提示位移
    /// - Parameter time: 提醒時間戳
    /// - Returns: 當天第幾分鐘
    func minuteOfDay(from time: Date) -> Int {
        calendar.component(.hour, from: time) * 60 + calendar.component(.minute, from: time)
    }
}

// MARK: - Private Method

private extension CampaignFeature {

    /// 把開團 upsert 進 ``State/campaigns`` (依 id 取代或新增)，並維持依開團日期由新到舊排序
    /// - Parameters:
    ///   - campaign: 要寫入的開團
    ///   - state: 將被修改的 ``State``
    func upsert(_ campaign: Campaign, into state: inout State) {
        if let index = state.campaigns.firstIndex(where: { $0.id == campaign.id }) {
            state.campaigns[index] = campaign
        } else {
            state.campaigns.append(campaign)
        }
        state.campaigns.sort { $0.openDate > $1.openDate }
    }

    // MARK: 訂購提醒副作用

    /// 請求行事曆權限後建立全天提醒事件、寫入連結並回報
    ///
    /// 權限被拒送 ``Action/reminderAccessDenied``；權限已授予後的失敗送 ``Action/reminderCreationFailed``
    /// - Parameters:
    ///   - campaignID: 建立提醒的開團識別值
    ///   - title: 提醒事件標題
    ///   - date: 全天事件的日期 (提醒時間戳當天起始)
    ///   - alarmOffset: 提示自當天 00:00 起算的秒數
    ///   - reminderTimestamp: 要保存的提醒時間戳 (日期＋提示時間)
    ///   - client: 行事曆整合介面
    ///   - repository: 提醒連結資料來源
    ///   - send: 送出後續 action 的通道
    static func addReminder(
        campaignID: Campaign.ID,
        title: String,
        date: Date,
        alarmOffset: TimeInterval,
        reminderTimestamp: Date,
        client: CalendarReminderClient,
        repository: CampaignReminderRepository,
        send: Send<Action>
    ) async {
        guard await client.requestAccess() else {
            await send(.reminderAccessDenied)
            return
        }

        // 權限已取得，此後的失敗 (事件儲存、識別碼缺失、連結寫入) 都與權限無關，
        // 一律走建立失敗路徑；失敗時不寫入連結，不留下部分寫入的狀態
        do {
            let identifier = try await client.addReminder(title, date, alarmOffset)
            try await repository.saveLink(campaignID, identifier, reminderTimestamp)
            await send(.reminderStored(campaignID, CampaignReminderLink(eventIdentifier: identifier, reminderTimestamp: reminderTimestamp)))
        } catch {
            await send(.reminderCreationFailed)
        }
    }

    /// 移除提醒事件並清除連結後回報；事件不存在或移除失敗一律仍清除連結 (使用者意圖即移除)
    /// - Parameters:
    ///   - campaignID: 移除提醒的開團識別值
    ///   - eventIdentifier: 要移除的行事曆事件識別碼
    ///   - client: 行事曆整合介面
    ///   - repository: 提醒連結資料來源
    ///   - send: 送出後續 action 的通道
    static func removeReminder(
        campaignID: Campaign.ID,
        eventIdentifier: String,
        client: CalendarReminderClient,
        repository: CampaignReminderRepository,
        send: Send<Action>
    ) async {
        try? await client.removeReminder(eventIdentifier)
        try? await repository.removeLink(campaignID)
        await send(.reminderStored(campaignID, nil))
    }
}
