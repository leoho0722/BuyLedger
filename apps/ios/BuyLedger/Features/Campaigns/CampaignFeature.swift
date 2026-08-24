//
//  CampaignFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// 開團列表的頂層日期區段 (依目前分組粒度：日／月／年)
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

/// 頂層日期區段下的次級分組
struct CampaignSubgroup: Equatable, Identifiable, Sendable {
    
    // MARK: - Identifiable Properties
    
    /// 子群組識別值，使用該子群組的起始時刻
    let id: Date
    
    // MARK: - Data Properties
    
    /// 依 locale 格式化的子標題；最細粒度時為 `nil`
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
@Reducer
struct CampaignFeature {
    
    // MARK: - State
    
    /// 開團功能狀態
    @ObservableState
    struct State: Equatable {
        
        /// 目前載入的開團，依開團日期由新到舊排序
        var campaigns: [Campaign] = []
        
        /// 訂單投影，供 ``CampaignSummary`` 計算分貨與結算使用；由 ``RootFeature`` 與
        var orders: [LedgerOrder] = []
        
        /// 目前選取的開團識別值 (供 iPad detail 選取)
        var selectedCampaignID: Campaign.ID?
        
        /// 目前套用的開團狀態篩選；`nil` 代表全部狀態
        var statusFilter: CampaignStatus?
        
        /// 目前列表的日期分組粒度
        var grouping: CampaignGrouping = .day
        
        /// 詳情頁「只看未收款」篩選，跨導覽保留
        var showsUnpaidOnly = false
        
        /// 指示是否正在載入
        var isLoading = false
        
        /// 是否已完成首次載入；完成後略過重複載入
        var hasLoaded = false
        
        /// 載入失敗訊息；只在載入失敗時設定
        var errorMessage: String?
        
        /// 各開團的提醒連結
        var reminderLinks: [Campaign.ID: CampaignReminderLink] = [:]
        
        /// 目前呈現中的新增／編輯開團表單；`nil` 表示未呈現
        @Presents var editCampaign: CampaignEditFeature.State?
        
        /// 刪除開團前的確認 alert
        @Presents var deletionConfirmation: AlertState<Action.Alert>?
        
        /// 詳情頁 toolbar 的刪除確認 alert
        @Presents var detailDeletionConfirmation: AlertState<Action.Alert>?
        
        /// 結團結算的二次確認；`nil` 代表未顯示
        @Presents var settleConfirmation: AlertState<Action.SettleAlert>?
        
        /// 列表頁的一次性通知
        @Presents var noticeAlert: AlertState<Action.NoticeAlert>?
        
        /// 詳情頁的一次性通知
        @Presents var detailNoticeAlert: AlertState<Action.NoticeAlert>?
        
        // MARK: - Computed Properties
        
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
        
        /// 使用者切換開團狀態；成功後更新畫面
        case statusChanged(Campaign.ID, CampaignStatus)
        
        /// 狀態變更寫入成功
        case campaignStatusSaved(Campaign.ID, CampaignStatus)
        
        /// 使用者點擊「結團」(設定結算封存日期)
        case settleTapped(Campaign.ID)
        
        /// 結團確認 alert 事件
        case settleConfirmation(PresentationAction<SettleAlert>)
        
        /// 確認後寫入結算日期；成功後更新畫面
        case settleConfirmed(Campaign.ID)
        
        /// 結團寫入成功，帶入送出時的結算時間
        case campaignSettled(Campaign.ID, Date)
        
        /// 列表列長按後要求刪除開團；先二次確認
        case deleteCampaignTapped(Campaign.ID)
        
        /// 詳情頁選單後要求刪除開團；先二次確認
        case detailDeleteCampaignTapped(Campaign.ID)
        
        /// 列表刪除確認 alert 事件
        case deletionConfirmation(PresentationAction<Alert>)
        
        /// 詳情刪除確認 alert 事件
        case detailDeletionConfirmation(PresentationAction<Alert>)
        
        /// 兩條刪除路徑共用的刪除處理
        case campaignDeleteRequested(Campaign.ID)
        
        /// 刪除成功；name 供 RootFeature 同步訂單副本
        case campaignDeleted(Campaign.ID, name: String)
        
        /// 開團儲存成功
        case campaignSaved(Campaign)
        
        /// 開團改名通知；由 ``RootFeature`` 處理訂單 cascade
        case campaignRenamed(from: String, to: String)
        
        /// 開團寫入失敗時顯示的一次性通知
        case campaignWriteFailed(String)
        
        /// 提醒連結載入完成 (campaignID → 連結資料)
        case reminderLinksLoaded([Campaign.ID: CampaignReminderLink])
        
        /// 提醒建立或移除後更新記憶體連結；`link` 為 `nil` 表示已移除
        case reminderStored(Campaign.ID, CampaignReminderLink?)
        
        /// 行事曆存取被使用者拒絕，彈出可到設定開啟的提示 alert
        case reminderAccessDenied
        
        /// 裝置限制導致無法使用行事曆時顯示提示
        case reminderAccessRestricted
        
        /// 權限已授予但提醒建立失敗，彈出不提及權限的提示 alert
        case reminderCreationFailed
        
        /// 沒有可寫入行事曆時顯示專用提示
        case reminderCalendarUnavailable
        
        /// 列表頁一次性通知 alert 事件
        case noticeAlert(PresentationAction<NoticeAlert>)
        
        /// 詳情頁一次性通知 alert 事件
        case detailNoticeAlert(PresentationAction<NoticeAlert>)
        
        /// 詳情頁切換訂單收款狀態；不直接修改訂單投影
        case receiptStatusToggled(LedgerOrder.ID, PaymentReceiptStatus)
        
        /// 跨 feature 意圖，由 ``RootFeature`` 轉發
        case delegate(Delegate)
        
        /// 開團功能可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {
            
            /// 訂單收款狀態變更，轉發到 ``OrdersFeature/Action/receiptStatusChanged(_:_:)``
            case receiptStatusToggled(LedgerOrder.ID, PaymentReceiptStatus)
        }
        
        /// 刪除確認 alert 的選項
        @CasePathable
        enum Alert: Equatable {
            
            /// 使用者確認刪除指定開團
            case confirmDelete(Campaign.ID)
        }
        
        /// 結團確認 alert 的選項
        @CasePathable
        enum SettleAlert: Equatable {
            
            /// 使用者確認結團
            case confirmSettle(Campaign.ID)
        }
        
        /// 一次性通知 alert 的選項
        @CasePathable
        enum NoticeAlert: Equatable {
            
            /// 使用者選擇前往系統設定開啟權限
            case openSettings
        }
    }
    
    // MARK: - Dependency Properties
    
    /// 開團主檔資料來源
    @Dependency(CampaignRepository.self) private var campaignRepository
    
    /// 開團改名時更新訂單歸屬
    @Dependency(OrderRepository.self) private var orderRepository
    
    /// 開團訂購提醒與系統行事曆整合的介面
    @Dependency(CalendarReminderClient.self) private var calendarReminderClient
    
    /// 開團訂購提醒連結 (campaignID → eventIdentifier) 的資料來源
    @Dependency(CampaignReminderRepository.self) private var reminderRepository
    
    /// 用於新開團的日期來源，方便在測試中注入固定值
    @Dependency(\.date) private var date
    
    /// 計算提醒事件時間的行事曆，可由測試注入
    @Dependency(\.calendar) private var calendar
    
    /// 用於新開團的 UUID 產生器，方便在測試中注入固定值
    @Dependency(\.uuid) private var uuid
    
    /// 開啟本 App 系統設定頁的能力；權限被拒提示的「前往設定」使用
    @Dependency(OpenSettingsClient.self) private var openSettingsClient
    
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
                    
                    do {
                        let links = try await reminderRepository.fetchLinks()
                        await send(.reminderLinksLoaded(links))
                    } catch {
                        return
                    }
                }
                
            case let .campaignsLoaded(loaded):
                state.isLoading = false
                state.hasLoaded = true
                
                // 與其他功能共用結單日狀態判定
                let now = date.now
                var transitioned: [Campaign] = []
                let updated = loaded.map { campaign -> Campaign in
                    let evaluated = campaign.evaluatingAutoClose(asOf: now, calendar: calendar)
                    if evaluated.status != campaign.status {
                        transitioned.append(evaluated)
                    }
                    return evaluated
                }
                state.campaigns = updated
                
                guard !transitioned.isEmpty else {
                    return .none
                }
                let campaignRepository = campaignRepository
                let transitionedToSave = transitioned
                return .run { send in
                    for campaign in transitionedToSave {
                        do {
                            try await campaignRepository.saveCampaign(campaign)
                        } catch {
                            await send(.campaignWriteFailed("開團狀態自動更新失敗，請稍後再試。"))
                            break
                        }
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
                let trimmedName = editState.draft.name.trimmingCharacters(
                    in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    return .none
                }
                
                // 名稱變更時才檢查唯一性，原名儲存直接放行。
                let editingID = editState.original?.id
                let originalName = editState.original?.name
                if trimmedName != originalName {
                    let isDuplicateName = state.campaigns.contains { existing in
                        existing.id != editingID &&
                        existing.name.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedName
                    }
                    guard !isDuplicateName else {
                        state.editCampaign?.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
                        return .none
                    }
                }
                
                // 驗證通過後才關閉表單，且寫入前沒有副作用。
                // 表單可先關閉，清單只在儲存成功後更新
                state.editCampaign = nil
                
                let id = editingID ?? uuid().uuidString
                let oldName = originalName
                let campaign = Campaign(
                    id: id,
                    name: trimmedName,
                    openDate: editState.draft.openDate,
                    closeDate: editState.draft.closeDate,
                    status: editState.draft.status,
                    settledDate: editState.original?.settledDate,
                    notes: editState.draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                // 依「是否要提醒」意圖與現有事件差異，決定儲存時對行事曆的調解
                let reminderTitle = campaign.reminderTitle
                let chosenTimestamp = editState.draft.reminderTimestamp
                let reminderEventDate = calendar.startOfDay(for: chosenTimestamp)
                let reminderAlarmOffset = TimeInterval(minuteOfDay(from: chosenTimestamp) * 60)
                let existingLink = state.reminderLinks[id]
                let nameChanged = existingLink != nil && (editState.original.map { $0.reminderTitle != reminderTitle } ?? false)
                let timestampChanged = existingLink.map { $0.reminderTimestamp != chosenTimestamp } ?? false
                let reminderContentChanged = nameChanged || timestampChanged
                
                let reconcile: CampaignReminderReconcile
                if editState.draft.wantsReminder {
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
                
                let didRename = oldName != nil && oldName != trimmedName
                return saveEffect(
                    campaign: campaign,
                    oldName: oldName,
                    trimmedName: trimmedName,
                    didRename: didRename,
                    reconcile: reconcile,
                    reminderTitle: reminderTitle,
                    reminderEventDate: reminderEventDate,
                    reminderAlarmOffset: reminderAlarmOffset,
                    chosenTimestamp: chosenTimestamp
                )
                
            case .editCampaign:
                return .none
                
            case let .campaignSaved(campaign):
                upsert(campaign, into: &state)
                return .none
                
            case let .statusChanged(id, newStatus):
                guard let campaign = state.campaigns.first(where: { $0.id == id }),
                      campaign.status != newStatus else {
                    return .none
                }
                var updatedValue = campaign
                updatedValue.status = newStatus
                let updated = updatedValue
                let campaignRepository = campaignRepository
                return .run { send in
                    try await campaignRepository.saveCampaign(updated)
                    await send(.campaignStatusSaved(id, newStatus))
                } catch: { _, send in
                    await send(.campaignWriteFailed("開團狀態更新失敗，請稍後再試。"))
                }
                
            case let .campaignStatusSaved(id, newStatus):
                guard let index = state.campaigns.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                state.campaigns[index].status = newStatus
                return .none
                
            case let .receiptStatusToggled(id, newStatus):
                // 訂單投影由 RootFeature 轉發給 OrdersFeature
                // 該投影會在訂單變更後由 RootFeature 的變更監看單向同步回來
                return .send(.delegate(.receiptStatusToggled(id, newStatus)))
                
            case .delegate:
                return .none
                
            // 拆分 Reduce 以避免型別檢查逾時
            default:
                return .none
            }
        }
        .ifLet(\.$editCampaign, action: \.editCampaign) {
            CampaignEditFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .settleTapped(id):
                // 結團是不可逆的狀態轉換，比照刪除先確認再寫入
                guard let campaign = state.campaigns.first(where: { $0.id == id }),
                      campaign.settledDate == nil
                else {
                    return .none
                }
                state.settleConfirmation = AlertState {
                    TextState("結團結算")
                } actions: {
                    ButtonState(action: .confirmSettle(id)) {
                        TextState("結團")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState("結算「\(campaign.name)」後就無法再改回進行中。確定要結團嗎？")
                }
                return .none
                
            case let .settleConfirmation(.presented(.confirmSettle(id))):
                return .send(.settleConfirmed(id))
                
            case .settleConfirmation:
                return .none
                
            case let .settleConfirmed(id):
                guard let campaign = state.campaigns.first(where: { $0.id == id }),
                      campaign.settledDate == nil
                else {
                    return .none
                }
                var updatedValue = campaign
                let settledDate = date.now
                updatedValue.settledDate = settledDate
                let updated = updatedValue
                let campaignRepository = campaignRepository
                return .run { send in
                    try await campaignRepository.saveCampaign(updated)
                    await send(.campaignSettled(id, settledDate))
                } catch: { _, send in
                    await send(.campaignWriteFailed("結團失敗，請稍後再試。"))
                }
                
            case let .campaignSettled(id, settledDate):
                guard let index = state.campaigns.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                state.campaigns[index].settledDate = settledDate
                return .none
                
            case let .deleteCampaignTapped(id):
                guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                    return .none
                }
                state.deletionConfirmation = deletionAlert(for: campaign)
                return .none
                
            case let .deletionConfirmation(.presented(.confirmDelete(id))):
                return .send(.campaignDeleteRequested(id))
                
            case .deletionConfirmation:
                return .none
                
            case let .detailDeleteCampaignTapped(id):
                guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                    return .none
                }
                state.detailDeletionConfirmation = deletionAlert(for: campaign)
                return .none
                
            case let .detailDeletionConfirmation(.presented(.confirmDelete(id))):
                return .send(.campaignDeleteRequested(id))
                
            case .detailDeletionConfirmation:
                return .none
                
            case let .campaignDeleteRequested(id):
                // 找不到目標 id 時直接 no-op
                guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                    return .none
                }
                return deleteEffect(id: id, name: campaign.name)
                
            case let .campaignDeleted(id, name: _):
                state.campaigns.removeAll { $0.id == id }
                state.reminderLinks[id] = nil
                if state.selectedCampaignID == id {
                    // 不 fallback 到 first?.id：那等於刪完把使用者帶進另一個不相干的開團
                    state.selectedCampaignID = nil
                }
                return .none
                
            case .campaignRenamed:
                // 訂單表 cascade 與 OrdersFeature 副本同步由 RootFeature 攔截處理
                return .none
                
            case let .campaignWriteFailed(message):
                presentNotice(failureNotice(LocalizedStringKey(message)), in: &state)
                return .none
                
            case let .reminderLinksLoaded(links):
                state.reminderLinks = links
                return .none
                
            case let .reminderStored(id, link):
                state.reminderLinks[id] = link
                return .none
                
            case .reminderAccessDenied:
                // 要求使用者前往系統設定卻不提供跳轉，等於把導航成本轉嫁給使用者
                presentNotice(
                    AlertState {
                        TextState("需要行事曆權限")
                    } actions: {
                        ButtonState(action: .openSettings) {
                            TextState("前往設定")
                        }
                        ButtonState(role: .cancel) {
                            TextState("知道了")
                        }
                    } message: {
                        TextState("請到「設定」開啟行事曆存取權限，才能新增或移除訂購提醒。")
                    },
                    in: &state
                )
                return .none
                
            case .reminderAccessRestricted:
                // 裝置政策限制下無法前往設定。
                presentNotice(
                    notice(
                        title: "無法使用行事曆",
                        message: "這台裝置的行事曆存取受政策限制，暫時無法新增或移除訂購提醒。"
                    ),
                    in: &state
                )
                return .none
                
            case .reminderCreationFailed:
                // 權限已授予，訊息不得指向權限設定——照做也無法解決真正發生的失敗
                presentNotice(
                    notice(title: "無法建立訂購提醒", message: "訂購提醒建立失敗，請稍後再試。"),
                    in: &state
                )
                return .none
                
            case .reminderCalendarUnavailable:
                // 找不到可寫入的行事曆不是權限問題，訊息不得指向設定
                presentNotice(
                    notice(
                        title: "找不到可寫入的行事曆",
                        message: "找不到可寫入的行事曆，請新增或啟用一個可寫入的行事曆後再試。"
                    ),
                    in: &state
                )
                return .none
                
            case .noticeAlert(.presented(.openSettings)), .detailNoticeAlert(.presented(.openSettings)):
                let openSettingsClient = openSettingsClient
                // 無法開啟時靜默結束即可；提示本身已由系統關閉，不阻塞使用者
                return .run { _ in
                    await openSettingsClient.open()
                }
                
            case .noticeAlert, .detailNoticeAlert:
                return .none

            // 已由前一個 Reduce 或後續 scoped reducer 處理的 action 不在此處改變 state。
            default:
                return .none
            }
        }
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
        .ifLet(\.$detailDeletionConfirmation, action: \.detailDeletionConfirmation)
        .ifLet(\.$settleConfirmation, action: \.settleConfirmation)
        .ifLet(\.$noticeAlert, action: \.noticeAlert)
        .ifLet(\.$detailNoticeAlert, action: \.detailNoticeAlert)
    }
}

// MARK: - Nested Types

extension CampaignFeature.State {
    
    /// 開團載入的三種解析結果
    enum LoadState: Equatable {
        
        // MARK: - Cases
        
        /// 已完成載入，顯示正常內容
        case loaded
        
        /// 載入失敗，附帶失敗原因
        case failed(String)
        
        /// 載入中
        case loading
    }
}

// MARK: - Internal Method

extension CampaignFeature.State {
    
    /// 依分組粒度建立開團區段與次級群組
    /// - Parameters:
    ///   - referenceDate: 計算「今天／昨天」等相對標題的「現在」時間
    ///   - calendar: 分組與標題用的行事曆
    ///   - locale: App 選定、用於日期區段標題的 locale
    /// - Returns: 依日期排序的區段與子群組
    func dateSections(
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> [CampaignDateSection] {
        let filtered =
        statusFilter.map { status in
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
    
    /// 將頂層區段切成次級群組；按日分組時只回傳一組
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
    
    /// 取得次級群組的日期鍵
    /// - Parameters:
    ///   - date: 要轉換的開團日期
    ///   - calendar: 分組使用的行事曆
    /// - Returns: 對應次級群組的起始日期
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
    func topTitle(
        for bucket: Date,
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
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
    func subTitle(
        for bucket: Date,
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
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

private extension CampaignFeature {
    
    /// 儲存開團時對訂購提醒行事曆事件的調解結果
    enum CampaignReminderReconcile: Equatable {
        
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
    
    /// 更新或新增開團，並依日期排序
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
    
    // MARK: 開團儲存副作用
    
    /// 建立「儲存開團」的先寫後改 effect
    /// - Parameters:
    ///   - campaign: 要寫入的開團
    ///   - oldName: 編輯前的名稱；新開團為 `nil`
    ///   - trimmedName: 已 trim 的新名稱
    ///   - didRename: 是否實際發生改名 (需 cascade 到訂單表)
    ///   - reconcile: 儲存時對行事曆的調解方式
    ///   - reminderTitle: 提醒事件標題
    ///   - reminderEventDate: 全天事件的日期
    ///   - reminderAlarmOffset: 提示自當天 00:00 起算的秒數
    ///   - chosenTimestamp: 使用者選定的提醒時間戳
    /// - Returns: 對應的 effect
    func saveEffect(
        campaign: Campaign,
        oldName: String?,
        trimmedName: String,
        didRename: Bool,
        reconcile: CampaignReminderReconcile,
        reminderTitle: String,
        reminderEventDate: Date,
        reminderAlarmOffset: TimeInterval,
        chosenTimestamp: Date
    ) -> Effect<Action> {
        let campaignRepository = campaignRepository
        let orderRepository = orderRepository
        let calendarReminderClient = calendarReminderClient
        let reminderRepository = reminderRepository
        let id = campaign.id
        return .run { send in
            try await campaignRepository.saveCampaign(campaign)
            await send(.campaignSaved(campaign))
            
            if didRename, let oldName {
                // DB cascade 更新所屬訂單；RootFeature 同步記憶體副本
                do {
                    try await orderRepository.renameOrderCampaign(oldName, trimmedName)
                    await send(.campaignRenamed(from: oldName, to: trimmedName))
                } catch {
                    await send(.campaignWriteFailed("開團已儲存，但歸屬訂單的開團名稱更新失敗，請稍後再試。"))
                }
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
                // 先建新事件，再刪舊事件，避免留下失效連結。
                let newIdentifier = await Self.addReminder(
                    campaignID: id,
                    title: reminderTitle,
                    date: reminderEventDate,
                    alarmOffset: reminderAlarmOffset,
                    reminderTimestamp: chosenTimestamp,
                    client: calendarReminderClient,
                    repository: reminderRepository,
                    send: send
                )
                if newIdentifier != nil {
                    do {
                        try await calendarReminderClient.removeReminder(identifier)
                    } catch {
                        // 新連結不回滾，但要告知舊事件移除失敗。
                        await send(.campaignWriteFailed("提醒已更新，但舊的行事曆事件移除失敗，請自行到行事曆刪除。"))
                    }
                }
            }
        } catch: { _, send in
            await send(.campaignWriteFailed("開團儲存失敗，請稍後再試。"))
        }
    }
    
    // MARK: 開團刪除副作用
    
    /// 刪除開團並同步訂單與提醒
    /// - Parameters:
    ///   - id: 要刪除的開團識別值
    ///   - name: 該開團的名稱
    /// - Returns: 對應的 effect
    func deleteEffect(id: Campaign.ID, name: String) -> Effect<Action> {
        let campaignRepository = campaignRepository
        let calendarReminderClient = calendarReminderClient
        return .run { send in
            let eventIdentifier = try await campaignRepository.removeCampaign(id, name)
            await send(.campaignDeleted(id, name: name))
            
            guard let eventIdentifier else {
                return
            }
            do {
                try await calendarReminderClient.removeReminder(eventIdentifier)
            } catch {
                // 本機刪除已生效不回滾，但此失敗仍須告知，不可靜默吞掉
                await send(.campaignWriteFailed("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。"))
            }
        } catch: { _, send in
            await send(.campaignWriteFailed("開團刪除失敗，請稍後再試。"))
        }
    }
    
    // MARK: 訂購提醒副作用
    
    /// 請求行事曆權限後建立全天提醒事件、寫入連結並回報
    /// - Parameters:
    ///   - campaignID: 建立提醒的開團識別值
    ///   - title: 提醒事件標題
    ///   - date: 全天事件的日期 (提醒時間戳當天起始)
    ///   - alarmOffset: 提示自當天 00:00 起算的秒數
    ///   - reminderTimestamp: 要保存的提醒時間戳 (日期＋提示時間)
    ///   - client: 行事曆整合介面
    ///   - repository: 提醒連結資料來源
    ///   - send: 送出後續 action 的通道
    /// - Returns: 建立成功的事件識別碼；任一失敗分支皆回傳 `nil`
    @discardableResult
    static func addReminder(
        campaignID: Campaign.ID,
        title: String,
        date: Date,
        alarmOffset: TimeInterval,
        reminderTimestamp: Date,
        client: CalendarReminderClient,
        repository: CampaignReminderRepository,
        send: Send<Action>
    ) async -> String? {
        switch await client.requestAccess() {
        case .granted:
            break
        case .denied:
            await send(.reminderAccessDenied)
            return nil
        case .restricted:
            await send(.reminderAccessRestricted)
            return nil
        }
        
        // 權限已取得；後續失敗不應被當成權限錯誤。
        do {
            let identifier = try await client.addReminder(title, date, alarmOffset)
            let link = CampaignReminderLink(
                eventIdentifier: identifier,
                reminderTimestamp: reminderTimestamp
            )
            try await repository.saveLink(campaignID, link)
            await send(
                .reminderStored(
                    campaignID,
                    link
                )
            )
            return identifier
        } catch CalendarReminderError.noWritableCalendar {
            await send(.reminderCalendarUnavailable)
            return nil
        } catch {
            await send(.reminderCreationFailed)
            return nil
        }
    }
    
    /// 移除提醒事件並清除連結；移除失敗也清除連結
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
        do {
            try await client.removeReminder(eventIdentifier)
        } catch {
            // 行事曆事件可能已不存在，仍依使用者意圖清除本機連結
        }
        
        do {
            try await repository.removeLink(campaignID)
            await send(.reminderStored(campaignID, nil))
        } catch {
            await send(.campaignWriteFailed("提醒連結移除失敗，請稍後再試。"))
        }
    }
    
    // MARK: 刪除確認
    
    /// 建立刪除開團前的確認 alert；供列表與詳情兩個呈現入口共用同一份內容
    /// - Parameter campaign: 要刪除的開團
    /// - Returns: 確認對話框
    func deletionAlert(for campaign: Campaign) -> AlertState<Action.Alert> {
        AlertState {
            TextState("刪除開團")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(campaign.id)) {
                TextState("刪除")
            }
            ButtonState(role: .cancel) {
                TextState("取消")
            }
        } message: {
            TextState("刪除「\(campaign.name)」後無法復原。歸屬此開團的訂單會保留，但會變回未歸團。")
        }
    }
    
    // MARK: 一次性通知
    
    /// 將一次性通知掛到列表或詳情層級
    /// - Parameters:
    ///   - alert: 要呈現的通知內容
    ///   - state: 將被修改的 ``State``
    func presentNotice(
        _ alert: AlertState<Action.NoticeAlert>,
        in state: inout State
    ) {
        if state.selectedCampaignID == nil {
            state.noticeAlert = alert
        } else {
            state.detailNoticeAlert = alert
        }
    }
    
    /// 建立只有「知道了」按鈕的一次性通知對話框
    /// - Parameters:
    ///   - title: 對話框標題
    ///   - message: 對話框訊息，型別為 `LocalizedStringKey` 而非 `String`。
    /// - Returns: 對話框
    func notice(
        title: LocalizedStringKey,
        message: LocalizedStringKey
    ) -> AlertState<Action.NoticeAlert> {
        AlertState {
            TextState(title)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }
    
    /// 建立僅含「知道了」關閉鈕的一次性寫入失敗說明對話框
    /// - Parameter message: 呈現給使用者的失敗原因
    /// - Returns: 對話框
    func failureNotice(_ message: LocalizedStringKey) -> AlertState<Action.NoticeAlert> {
        notice(title: "操作失敗", message: message)
    }
}
