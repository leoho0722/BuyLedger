//
//  CampaignFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation

/// 開團分頁的容器：持有共用資料，轉送列表與詳情的請求，統一呈現編輯表單與通知
@Reducer
struct CampaignFeature {

    // MARK: - State

    /// 容器狀態：共用資料的來源、子 Feature 狀態、詳情導覽堆疊與唯一的呈現目的地
    @ObservableState
    struct State: Equatable {

        /// 目前載入的開團，依開團日期由新到舊排序
        @Shared var campaigns: [Campaign]

        /// 訂單投影，由 ``RootFeature`` 單向同步，列表與詳情只讀
        @Shared var orders: [LedgerOrder]

        /// 詳情頁「只看未收款」篩選，跨導覽保留
        @Shared var showsUnpaidOnly: Bool

        /// 各開團的提醒連結，只有提醒子 Feature 寫入
        @Shared var reminderLinks: [Campaign.ID: CampaignReminderLink]

        /// 列表子 Feature 的狀態
        var list: CampaignListFeature.State

        /// 提醒連結載入與行事曆提醒子 Feature 的狀態
        var reminder: CampaignReminderFeature.State

        /// 開團寫入子 Feature 的狀態
        var writes: CampaignWritesFeature.State

        /// 已推入的詳情堆疊，同一時間最多一個
        var path = StackState<Path.State>()

        /// 目前呈現中的編輯表單或 alert；`nil` 表示沒有呈現
        @Presents var destination: Destination.State?

        /// 表單開啟與關閉期間到達的通知暫存，表單關好後才呈現
        var presentationQueue = CampaignPresentationQueue()

        /// 建立容器與各子層，共享資料的引用同時指派給自己與子層
        init() {
            let sharedCampaigns = Shared<[Campaign]>(value: [])
            let sharedOrders = Shared<[LedgerOrder]>(value: [])
            let sharedReminderLinks = Shared<[Campaign.ID: CampaignReminderLink]>(value: [:])
            self._campaigns = sharedCampaigns
            self._orders = sharedOrders
            self._showsUnpaidOnly = Shared(value: false)
            self._reminderLinks = sharedReminderLinks
            self.list = CampaignListFeature.State(
                campaigns: sharedCampaigns,
                orders: SharedReader(sharedOrders)
            )
            self.reminder = CampaignReminderFeature.State(links: sharedReminderLinks)
            self.writes = CampaignWritesFeature.State(campaigns: sharedCampaigns)
        }

        /// 以指定開團取代堆疊成為唯一的詳情；找不到開團時不動
        ///
        /// - Parameter campaignID: 要顯示詳情的開團識別值
        mutating func showDetail(campaignID: Campaign.ID) {
            guard campaigns.contains(where: { $0.id == campaignID }) else {
                return
            }
            path.removeAll()
            path.append(
                .detail(
                    CampaignDetailFeature.State(
                        campaignID: campaignID,
                        campaigns: SharedReader($campaigns),
                        orders: SharedReader($orders),
                        reminderLinks: SharedReader($reminderLinks),
                        showsUnpaidOnly: $showsUnpaidOnly
                    )
                )
            )
        }

        /// 更新列表的日期脈絡，不重新載入或評估結單狀態
        ///
        /// - Parameter context: 殼層解析後的目前日期與行事曆
        mutating func refreshDateContext(_ context: CampaignDateContext) {
            list.dateContext = context
        }

        /// 呈現一則通知；表單開啟或關閉中先暫存，否則直接顯示
        ///
        /// - Parameter notice: 要呈現的通知
        mutating func present(_ notice: Destination.State) {
            var current = destination
            presentationQueue.present(notice, in: &current)
            destination = current
        }
    }

    // MARK: - Action

    /// 容器的使用者操作、對根功能的委派，以及各子 Feature 與導覽的事件
    enum Action {

        /// 使用者在容器畫面上的操作
        ///
        /// - Parameter action: 實際的操作
        case view(View)

        /// 跨 feature 意圖，由 ``RootFeature`` 轉發
        ///
        /// - Parameter action: 要交給根畫面的意圖
        case delegate(Delegate)

        /// 編輯表單或 alert 的事件
        ///
        /// - Parameter action: 目的地的呈現、關閉或內部事件
        case destination(PresentationAction<Destination.Action>)

        /// 詳情導覽堆疊的事件
        ///
        /// - Parameter action: 堆疊元素的操作與返回
        case path(StackActionOf<Path>)

        /// 列表子 Feature 的事件
        ///
        /// - Parameter action: 列表操作、載入結果與委派請求
        case list(CampaignListFeature.Action)

        /// 提醒子 Feature 的事件
        ///
        /// - Parameter action: 連結載入、提醒調解與其失敗結果
        case reminder(CampaignReminderFeature.Action)

        /// 寫入子 Feature 的事件
        ///
        /// - Parameter action: 開團寫入請求與結果
        case writes(CampaignWritesFeature.Action)

        /// 容器畫面送出的操作
        @CasePathable
        enum View {

            /// 容器出現，轉送提醒連結載入請求
            case task

            /// 編輯表單的 sheet 關閉動畫結束，讓暫存的通知接著呈現
            case formSheetDismissed
        }

        /// 開團功能可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 開團已刪除，由根功能同步訂單副本
            ///
            /// - Parameter name: 已刪除的開團名稱
            case campaignDeleted(name: String)

            /// 開團已改名，由根功能同步訂單副本
            ///
            /// - Parameters:
            ///   - from: 原開團名稱
            ///   - to: 儲存後的開團名稱
            case campaignRenamed(from: String, to: String)

            /// 訂單收款狀態變更，轉發到 ``OrdersFeature/Action/receiptStatusChanged(_:_:)``
            ///
            /// - Parameters:
            ///   - orderID: 收款狀態變更的訂單識別值
            ///   - status: 變更後的收款狀態
            case receiptStatusToggled(orderID: LedgerOrder.ID, status: PaymentReceiptStatus)
        }
    }

    // MARK: - Dependencies

    /// 日期來源，供新開團、編輯表單與提醒預設時間使用，方便在測試中注入固定值
    @Dependency(\.date) private var date

    /// 行事曆，供提醒時間換算使用，可由測試注入
    @Dependency(\.calendar) private var calendar

    /// `UUID` 產生器，供新開團與編輯表單的識別值使用，方便在測試中注入固定值
    @Dependency(\.uuid) private var uuid

    /// 開啟本 App 系統設定頁的能力；權限被拒提示的「前往設定」使用
    @Dependency(\.openSettingsService) private var openSettingsService

    // MARK: - Body

    /// 組合各子 Feature，容器自己的轉送與呈現邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
        Scope(state: \.list, action: \.list) { CampaignListFeature() }

        Scope(state: \.reminder, action: \.reminder) { CampaignReminderFeature() }

        Scope(state: \.writes, action: \.writes) { CampaignWritesFeature() }

        Reduce(core)
            .forEach(\.path, action: \.path)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Private Method

private extension CampaignFeature {

    /// 處理列表與詳情的請求、確認結果與子 Feature 的委派，統一呈現通知
    ///
    /// - Parameters:
    ///   - state: 開團容器狀態
    ///   - action: 使用者操作、子 Feature 委派或導覽事件
    /// - Returns: 子 Feature 的請求或根功能同步意圖
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task):
            return .send(.reminder(.linksRequested))

        case .view(.formSheetDismissed):
            var current = state.destination
            state.presentationQueue.finishFormClosing(into: &current)
            state.destination = current
            return .none

        case .destination(.presented(.edit(.delegate(.saveRequested(let request))))):
            return save(request, state: &state)

        case .destination(.presented(.alert(.confirmDelete(let id)))):
            guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                return .none
            }
            return .send(.writes(.deleteRequested(id: id, name: campaign.name)))

        case .destination(.presented(.alert(.confirmSettle(let id)))):
            return .send(.writes(.settleRequested(id)))

        case .destination(.presented(.alert(.openSettings))):
            let openSettingsService = openSettingsService
            return .run { _ in await openSettingsService.open() }

        case .destination(.dismiss):
            state.presentationQueue.markFormClosing(dismissing: state.destination)
            return .none

        case .path(.element(id: _, action: .detail(.delegate(.requested(let request))))):
            return fulfill(request, state: &state)

        case .list(.delegate(.requested(let request))):
            return fulfill(request, state: &state)

        case .list(.delegate(.autoCloseFailed)):
            state.present(.autoCloseFailure)
            return .none

        case .reminder(.delegate(.failed(let failure))):
            state.present(.reminderFailure(failure))
            return .none

        case .writes(.delegate(.saved(let request?))):
            return .send(.reminder(.reconcileRequested(request)))

        case .writes(.delegate(.renamed(let from, let to))):
            return .send(.delegate(.campaignRenamed(from: from, to: to)))

        case .writes(.delegate(.deleted(let deletion))):
            let id = deletion.id
            let eventIdentifier = deletion.eventIdentifier
            state.path.popDetail(campaignID: id)
            return .concatenate(
                .send(.delegate(.campaignDeleted(name: deletion.name))),
                .send(.reminder(.campaignRemoved(campaignID: id, eventIdentifier: eventIdentifier)))
            )

        case .writes(.delegate(.failed(let failure))):
            state.present(.writeFailure(failure))
            return .none

        case .delegate, .destination, .path, .list, .reminder, .writes:
            return .none
        }
    }

    /// 以最新開團清單驗證重名，通過才關閉表單並轉送儲存計畫
    ///
    /// - Parameters:
    ///   - request: 表單送出的儲存意圖
    ///   - state: 容器狀態
    /// - Returns: 重名時只寫回原因；通過時轉送給寫入子 Feature
    func save(_ request: CampaignEditFeature.SaveRequest, state: inout State) -> Effect<Action> {
        if CampaignSavePlan.conflicts(
            name: request.name,
            originalName: request.original?.name,
            editingID: request.original?.id,
            campaigns: state.campaigns
        ) {
            state.destination?.modify(\.edit) {
                $0.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
            }
            return .none
        }
        state.destination = nil
        state.presentationQueue.beginFormClosing()
        let id = request.original?.id ?? uuid().uuidString
        let plan = CampaignSavePlan.make(
            request: request,
            existingLink: state.reminderLinks[id],
            newID: id,
            calendar: calendar
        )
        return .send(.writes(.saveRequested(plan)))
    }

    /// 處理列表與詳情共用的開團操作請求
    ///
    /// - Parameters:
    ///   - request: 要執行的開團操作
    ///   - state: 容器狀態
    /// - Returns: 後續寫入或根功能同步事件
    func fulfill(_ request: CampaignRequest, state: inout State) -> Effect<Action> {
        switch request {
        case .showDetail(let id):
            state.showDetail(campaignID: id)
            return .none

        case .create:
            state.destination = .edit(
                CampaignEditFeature.State(id: uuid(), now: date.now, calendar: calendar)
            )
            return .none

        case .edit(let id):
            guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                return .none
            }
            state.destination = .edit(
                CampaignEditFeature.State(
                    original: campaign,
                    link: state.reminderLinks[id],
                    id: uuid(),
                    now: date.now,
                    calendar: calendar
                )
            )
            return .none

        case .delete(let id):
            guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                return .none
            }
            state.destination = .deleteConfirmation(for: campaign)
            return .none

        case .settle(let id):
            guard let campaign = state.campaigns.first(where: { $0.id == id }),
                  campaign.settledDate == nil else {
                return .none
            }
            state.destination = .settlementConfirmation(for: campaign)
            return .none

        case .changeStatus(let id, let status):
            return .send(.writes(.statusChangeRequested(id: id, status: status)))

        case .toggleReceipt(let orderID, let status):
            return .send(.delegate(.receiptStatusToggled(orderID: orderID, status: status)))
        }
    }
}
