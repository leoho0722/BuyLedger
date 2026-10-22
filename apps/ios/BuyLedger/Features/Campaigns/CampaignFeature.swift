//
//  CampaignFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation

/// 開團分頁的容器：持有共用資料，轉送列表與詳情的請求，並把寫入與呈現結果交給對應的子 Feature
@Reducer
struct CampaignFeature {

    // MARK: - State

    /// 容器狀態：共用資料的來源、子 Feature 狀態與詳情導覽堆疊
    @ObservableState
    struct State: Equatable {

        /// 目前載入的開團，依開團日期由新到舊排序
        @Shared var campaigns: [Campaign]

        /// 訂單投影，由 ``RootFeature`` 單向同步，列表與詳情只讀
        @Shared var orders: [LedgerOrder]

        /// 詳情頁「只看未收款」篩選，跨導覽保留
        @Shared(value: false) var isShowingUnpaidOnly: Bool

        /// 各開團的提醒連結，只有提醒子 Feature 寫入
        @Shared var reminderLinks: [Campaign.ID: CampaignReminderLink]

        /// 開團載入與自動結單子 Feature 的狀態
        var load: CampaignLoadFeature.State

        /// 列表子 Feature 的狀態
        var list: CampaignListFeature.State

        /// 提醒連結載入與行事曆提醒子 Feature 的狀態
        var reminder: CampaignReminderFeature.State

        /// 開團寫入子 Feature 的狀態
        var writes: CampaignWritesFeature.State

        /// 呈現子 Feature 的狀態：編輯表單、alert 與一次性通知的佇列
        var presentation = CampaignPresentationFeature.State()

        /// 已推入的詳情堆疊，同一時間最多一個
        var path = StackState<Path.State>()

        /// 建立容器與各子層，共享資料的引用同時指派給自己與子層
        init() {
            let sharedCampaigns = Shared<[Campaign]>(value: [])
            let sharedOrders = Shared<[LedgerOrder]>(value: [])
            let sharedReminderLinks = Shared<[Campaign.ID: CampaignReminderLink]>(value: [:])
            self._campaigns = sharedCampaigns
            self._orders = sharedOrders
            self._reminderLinks = sharedReminderLinks
            let load = CampaignLoadFeature.State(campaigns: sharedCampaigns)
            self.load = load
            self.list = CampaignListFeature.State(
                campaigns: SharedReader(sharedCampaigns),
                orders: SharedReader(sharedOrders),
                isLoading: SharedReader(load.$isLoading),
                hasLoaded: SharedReader(load.$hasLoaded),
                errorMessage: SharedReader(load.$errorMessage)
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
                        isShowingUnpaidOnly: $isShowingUnpaidOnly
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

        /// 詳情導覽堆疊的事件
        ///
        /// - Parameter action: 堆疊元素的操作與返回
        case path(StackActionOf<Path>)

        /// 呈現子 Feature 的事件
        ///
        /// - Parameter action: 編輯表單與 alert 的事件、一次性通知與子層委派
        case presentation(CampaignPresentationFeature.Action)

        /// 列表子 Feature 的事件
        ///
        /// - Parameter action: 列表操作與委派請求
        case list(CampaignListFeature.Action)

        /// 開團載入子 Feature 的事件
        ///
        /// - Parameter action: 讀取結果、自動結單結果或失敗委派
        case load(CampaignLoadFeature.Action)

        /// 父層要求載入開團，由載入子層處理去重
        case loadRequested

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

            /// 訂單收款狀態變更，轉發到 ``OrdersFeature/Action/receiptStatusChangeRequested(id:status:)``
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

    // MARK: - Body

    /// 組合各子 Feature，容器自己的轉送與分派邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
        Scope(state: \.load, action: \.load) {
            CampaignLoadFeature()
        }

        Scope(state: \.list, action: \.list) {
            CampaignListFeature()
        }

        Scope(state: \.reminder, action: \.reminder) {
            CampaignReminderFeature()
        }

        Scope(state: \.writes, action: \.writes) {
            CampaignWritesFeature()
        }

        Scope(state: \.presentation, action: \.presentation) {
            CampaignPresentationFeature()
        }

        Reduce(core)
            .forEach(\.path, action: \.path)
    }
}

// MARK: - Private Method

private extension CampaignFeature {

    /// 處理列表與詳情的請求、子 Feature 的委派與寫入結果，呈現相關的事件交給呈現子 Feature
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
            state.presentation.finishFormClosing()
            return .none

        case .delegate:
            return .none

        case .path(.element(id: _, action: .detail(.delegate(.requested(let request))))):
            return fulfill(request, state: &state)

        case .path:
            return .none

        case .presentation(.delegate(.saveRequested(let request))):
            return save(request, state: &state)

        case .presentation(.delegate(.deleteConfirmed(let id))):
            guard let campaign = state.campaigns.first(where: { $0.id == id }) else {
                return .none
            }
            return .send(.writes(.deleteRequested(id: id, name: campaign.name)))

        case .presentation(.delegate(.settleConfirmed(let id))):
            return .send(.writes(.settleRequested(id)))

        case .presentation:
            return .none

        case .list(.delegate(.requested(let request))):
            return fulfill(request, state: &state)

        case .list(.delegate(.loadRequested)):
            return .send(.load(.loadRequested))

        case .list:
            return .none

        case .load(.delegate(.autoCloseFailed)):
            return .send(.presentation(.noticeRequested(.autoCloseFailure)))

        case .load:
            return .none

        case .loadRequested:
            return .send(.load(.loadRequested))

        case .reminder(.delegate(.failed(let failure))):
            return .send(.presentation(.noticeRequested(.reminderFailure(failure))))

        case .reminder:
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
            return .send(.presentation(.noticeRequested(.writeFailure(failure))))

        case .writes:
            return .none
        }
    }

    /// 依列表或詳情送出的請求解析操作，並交由容器或呈現子 Feature 套用
    ///
    /// - Parameters:
    ///   - request: 列表或詳情送出的請求
    ///   - state: 開團容器狀態，直接就地修改
    /// - Returns: 容器接續執行的 Effect，沒有就回 `.none`
    func fulfill(_ request: CampaignRequest, state: inout State) -> Effect<Action> {
        switch CampaignRequestPlan.fulfill(
            request,
            campaigns: state.campaigns,
            reminderLinks: state.reminderLinks
        ) {
        case .none:
            return .none

        case .showDetail(let id):
            state.showDetail(campaignID: id)
            return .none

        case .edit(let original, let link):
            let form = CampaignEditFeature.State(
                original: original,
                link: link,
                id: uuid(),
                now: date.now,
                calendar: calendar
            )
            state.presentation.present(.edit(form))
            return .none

        case .present(let destination):
            state.presentation.present(destination)
            return .none

        case .send(let action):
            return .send(action)
        }
    }

    /// 以最新開團清單驗證重名，通過才關閉表單並轉送儲存計畫
    ///
    /// - Parameters:
    ///   - request: 表單送出的儲存意圖
    ///   - state: 容器狀態
    /// - Returns: 重名時只把原因寫回表單；通過時轉送給寫入子 Feature
    func save(_ request: CampaignEditFeature.SaveRequest, state: inout State) -> Effect<Action> {
        if CampaignSavePlan.conflicts(
            name: request.name,
            originalName: request.original?.name,
            editingID: request.original?.id,
            campaigns: state.campaigns
        ) {
            state.presentation.showNameConflict()
            return .none
        }
        state.presentation.closeFormForSave()
        let id = request.original?.id ?? uuid().uuidString
        let plan = CampaignSavePlan.make(
            request: request,
            existingLink: state.reminderLinks[id],
            newID: id,
            calendar: calendar
        )
        return .send(.writes(.saveRequested(plan)))
    }
}
