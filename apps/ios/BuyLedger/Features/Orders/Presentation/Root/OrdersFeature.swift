//
//  OrdersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 訂單容器，持有共用訂單與各子 Feature，依事件轉送請求並套用寫入結果
@Reducer
struct OrdersFeature {

    // MARK: - State

    /// 管理訂單清單載入、篩選、批次勾選與呈現所需的狀態
    @ObservableState
    struct State: Equatable {

        /// 目前載入的訂單
        @Shared var orders: [LedgerOrder]

        /// 訂單清單的篩選、搜尋與批次勾選
        var list: OrderListFeature.State

        /// 主檔端維護的四種主檔目錄，訂單容器只讀取
        @SharedReader(.lookupCatalog) var lookupCatalog: LookupCatalog

        /// 啟動時載入的共用幣別清單，表單建立時只讀取現有值
        @SharedReader(.currencyCodes) var currencyCodes: [CurrencyCode]

        /// 新訂單的預設幣別投影，只由 Root 在初始化與偏好變更時寫入
        var defaultCurrency: CurrencyCode = .twd

        /// Root 同步的 AI 摘要開關與模型，容器只讀取
        var aiSummarySettings: OrderAISummarySettings = OrderAISummarySettings(
            isEnabled: SettingsSnapshot.default.isAISummaryEnabled,
            model: SettingsSnapshot.default.aiSummaryModel
        )

        /// 由 Root 同步的開團投影，清單共用唯讀引用，表單選項只讀取
        @Shared(value: []) var campaigns: [Campaign]

        /// 訂單與主檔的載入子 Feature
        var load: OrdersLoadFeature.State

        /// 訂單持久化與成功後共用資料更新的子 Feature
        var writes: OrderWritesFeature.State

        /// 表單、alert 與一次性通知的呈現子 Feature
        var presentation = OrdersPresentationFeature.State()

        /// iPhone 與 iPad 共用詳情路徑的導覽子 Feature
        var detail: OrdersDetailNavigationFeature.State

        /// 由詳情 `path` 投影出的目前訂單識別值
        var selectedOrderID: LedgerOrder.ID? {
            detail.path.last?.detail?.orderID
        }

        /// 目前詳情是否已被清單篩選排除
        var isDetailExcludedByFilter: Bool {
            guard let selectedOrderID else {
                return false
            }
            return !list.filteredOrders.contains { $0.id == selectedOrderID }
        }

        /// 供 Root 與容器畫面讀取的載入投影
        var loadState: OrdersLoadState {
            list.loadState
        }

        /// 以訂單初值建立容器持有的無鍵共享引用
        ///
        /// - Parameter orders: 初始訂單，預設為空清單
        init(orders: [LedgerOrder] = []) {
            let sharedOrders = Shared<[LedgerOrder]>(value: orders)
            self._orders = sharedOrders
            self.writes = OrderWritesFeature.State(orders: sharedOrders)
            let load = OrdersLoadFeature.State(orders: sharedOrders)
            self.load = load
            self.list = OrderListFeature.State(
                orders: SharedReader(sharedOrders),
                campaigns: SharedReader(_campaigns),
                isLoading: SharedReader(load.$isLoading),
                hasLoaded: SharedReader(load.$hasLoaded),
                errorMessage: SharedReader(load.$errorMessage)
            )
            self.detail = OrdersDetailNavigationFeature.State(orders: SharedReader(sharedOrders))
        }

        /// 套用跨功能篩選後保留命中詳情或清空失配路徑
        ///
        /// - Parameters:
        ///   - searchText: 客戶名稱搜尋；類別導覽時為空
        ///   - category: 精準類別；客戶導覽時為 `nil`
        ///   - now: 導覽時的現在時間
        ///   - calendar: 篩選使用的行事曆
        mutating func applyFilterNavigation(
            searchText: String,
            category: String?,
            now: Date,
            calendar: Calendar
        ) {
            // 日期脈絡與新篩選都套用後才檢查，避免以舊篩選清掉新篩選仍命中的詳情
            list.refreshDateContext(OrderDateContext(now: now, calendar: calendar))
            list.applyFilterNavigation(searchText: searchText, category: category)
            reconcileDetailPathWithFilteredOrders()
        }

        /// 刷新清單的日期脈絡，並清除因這次刷新才被日期篩選排除的詳情，供 Root 的前景與重大時間變更共用
        ///
        /// - Parameters:
        ///   - now: 新的現在時間
        ///   - calendar: 新的行事曆與時區
        /// - Note: 刷新前已被排除的詳情 (如狀態改成篩選外) 維持原樣，回到前景不清空
        mutating func refreshDateContext(now: Date, calendar: Calendar) {
            let isDetailAlreadyExcluded = isDetailExcludedByFilter
            list.refreshDateContext(OrderDateContext(now: now, calendar: calendar))
            guard !isDetailAlreadyExcluded else {
                return
            }
            reconcileDetailPathWithFilteredOrders()
        }

        /// 清除目前清單篩選排除的詳情，保留仍符合條件的路徑元素
        mutating func reconcileDetailPathWithFilteredOrders() {
            guard isDetailExcludedByFilter else {
                return
            }
            detail.clearDetail()
        }

        /// 建立並呈現新訂單表單，供訂單分頁與首頁共用
        ///
        /// - Parameters:
        ///   - id: 表單識別值
        ///   - now: 新訂單日期與評估開團結單日的現在時間
        ///   - calendar: 建立表單時的注入行事曆
        mutating func presentNewOrder(id: UUID, now: Date, calendar: Calendar) {
            let destination = OrdersContainerPlan.newOrder(
                id: id,
                state: self,
                now: now,
                calendar: calendar
            )
            presentation.present(destination)
        }

        /// 以唯讀快照建立所有表單入口共用的選項
        ///
        /// - Parameters:
        ///   - now: 評估開團結單日的現在時間
        ///   - calendar: 結單日與完整時間使用的行事曆
        /// - Returns: 可選主檔、進行中開團、幣別與行事曆
        func makeEditOptions(now: Date, calendar: Calendar) -> OrderEditOptions {
            OrdersEditorOptions.make(state: self, now: now, calendar: calendar)
        }
    }

    // MARK: - Action

    /// 訂單功能可處理的事件
    enum Action: BindableAction {

        /// SwiftUI 雙向繫結事件
        ///
        /// - Parameter action: 由 `State` 的雙向繫結產生的事件
        case binding(BindingAction<State>)

        /// 轉發容器畫面發生的使用者事件
        ///
        /// - Parameter action: 分欄選取或 sheet 關閉完成事件
        case view(View)

        /// 交由父層處理的跨功能意圖
        ///
        /// - Parameter action: 訂單功能送出的委派
        case delegate(Delegate)

        /// 詳情導覽子 Feature 的路徑事件
        ///
        /// - Parameter action: 共用詳情 `path` 的導覽事件
        case detail(OrdersDetailNavigationFeature.Action)

        /// 清單篩選條件變更後延後檢查目前詳情
        case filterConditionsChanged

        /// 清單子 Feature 的互動與委派
        ///
        /// - Parameter action: 清單事件
        case list(OrderListFeature.Action)

        /// 訂單載入子 Feature 的請求、回應與失敗委派
        ///
        /// - Parameter action: 載入子層的事件
        case load(OrdersLoadFeature.Action)

        /// 呈現子 Feature 的表單、alert 與通知事件
        ///
        /// - Parameter action: 目的地內部事件、委派或一次性通知
        case presentation(OrdersPresentationFeature.Action)

        /// 父層要求載入訂單或套用跨功能資料變更，由對應子 Feature 處理
        ///
        /// - Parameter request: 根功能送進訂單容器的請求
        case rootRequest(OrdersRootRequest)

        /// 訂單寫入子 Feature 的請求、回應與委派
        ///
        /// - Parameter action: 寫入子層事件
        case writes(OrderWritesFeature.Action)

        /// 容器畫面的使用者事件
        @CasePathable
        enum View {

            /// 原生分欄清單的選取變更；選取值只投影到詳情 `path`
            ///
            /// - Parameter orderID: 目前選取訂單；`nil` 表示原生返回根清單
            case detailSelectionChanged(LedgerOrder.ID?)

            /// 任一表單 sheet 的關閉動畫已完成
            case formSheetDismissed
        }

        /// 訂單功能交給父層的導覽意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 要求開啟設定頁以啟用 AI 商品明細總結
            case aiSettingsRequested

            /// 請根功能將新增選項交給主檔端寫入
            ///
            /// - Parameter request: 保留表單識別值的新增請求
            case optionAddRequested(LookupAdditionRequest)

            /// 訂單分頁要求載入，由根功能先確認主檔目錄
            case loadRequested
        }
    }

    // MARK: - Dependencies

    /// 用於新訂單編號，以及新增、有效編輯與合併確認表單的識別值，方便在測試中注入固定值
    @Dependency(\.uuid) private var uuid

    /// 用於篩選、開團結單判斷、合併、AI 摘要提示詞與建立訂單的日期來源
    @Dependency(\.date) private var date

    /// 用於訂單日期篩選與開團結單判斷的行事曆
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// reducer 的骨架，只負責組合子層，容器自己的邏輯在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.list, action: \.list) {
            OrderListFeature()
        }
        .onChange(of: \.list.filterConditions) { _, state in
            // 搜尋欄可能在畫面更新中送出變更，延後清空 `path` 避免畫面讀到舊訂單
            guard state.isDetailExcludedByFilter else {
                return .none
            }
            return .run {
                await $0(.filterConditionsChanged)
            }
        }

        Scope(state: \.load, action: \.load) {
            OrdersLoadFeature()
        }
        .onChange(of: \.load.hasLoaded) { _, state in
            applyLoadedOrders(state: &state)
        }

        Scope(state: \.writes, action: \.writes) {
            OrderWritesFeature()
        }

        Scope(state: \.presentation, action: \.presentation) {
            OrdersPresentationFeature()
        }

        Scope(state: \.detail, action: \.detail) {
            OrdersDetailNavigationFeature()
        }

        Reduce(core)
    }
}

// MARK: - Private Method

private extension OrdersFeature {

    /// 依收到的 Action 轉送子層請求、套用呈現與寫入結果，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 容器目前的狀態，直接就地修改
    ///   - action: 使用者、子 Feature 或父層事件
    /// - Returns: 子層請求或父層委派，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.detailSelectionChanged(let orderID)):
            if let orderID {
                state.detail.showDetail(orderID: orderID)
            } else {
                state.detail.clearDetail()
            }
            return .none

        case .view(.formSheetDismissed):
            state.presentation.finishFormClosing()
            return .none

        case .delegate:
            return .none

        case .detail(.path(.element(_, .detail(.delegate(.requested(let request)))))):
            return fulfill(request, state: &state)

        case .detail:
            return .none

        case .filterConditionsChanged:
            state.reconcileDetailPathWithFilteredOrders()
            return .none

        case .list(.delegate(.loadRequested)):
            return .send(.delegate(.loadRequested))

        case .list(.delegate(.requested(let request))):
            return fulfill(request, state: &state)

        case .list:
            return .none

        case .load:
            return .none

        case .presentation(let action):
            return forwardPresentation(action, state: &state)

        case .rootRequest(.load):
            return .send(.load(.loadRequested))

        case .rootRequest(.cascade(let request)):
            return .send(.writes(.cascadeRequested(request)))

        case .rootRequest(.receiptStatusChange(let id, let status)):
            return .send(.writes(.receiptToggleRequested(id: id, status: status)))

        case .rootRequest(.paymentMethodFlagsApply(let orders)):
            return .send(.writes(.paymentMethodFlagsApplyRequested(orders)))

        case .rootRequest(.optionAdditionCompleted(let request, let isStored)):
            return state.presentation.applyOptionAddition(request, isStored: isStored)
                .map(Action.presentation)

        case .writes(let action):
            return applyWriteResult(action, state: &state)
        }
    }

    /// 載入完成後移除已不存在訂單的詳情
    ///
    /// - Parameter state: 容器目前的狀態，直接就地修改
    /// - Returns: 沒有後續效果，回傳 `.none`
    func applyLoadedOrders(state: inout State) -> Effect<Action> {
        guard state.load.hasLoaded else {
            return .none
        }
        state.detail.applyLoadedOrders()
        return .none
    }

    /// 依共用請求解析表單識別值與時間，再套用呈現、詳情推入或寫入轉送
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - state: 容器目前的狀態，直接就地修改
    /// - Returns: 轉給寫入子層的請求，其餘套用在狀態內時回傳 `.none`
    func fulfill(_ request: OrderRequest, state: inout State) -> Effect<Action> {
        let formID = OrdersContainerPlan.requiresFormID(request, state: state) ? uuid() : nil
        let context = OrdersContainerPlan.requiresDateContext(request, state: state)
            ? OrderDateContext(now: date.now, calendar: calendar) : nil
        let outcome = OrdersContainerPlan.fulfill(
            request,
            state: state,
            context: context,
            formID: formID
        )
        switch outcome {
        case .none:
            return .none

        case .present(let destination):
            state.presentation.present(destination)
            return .none

        case .write(let action):
            return .send(.writes(action))
        }
    }

    /// 轉送呈現子層的委派，合併候選與確認表單的草稿在容器計算
    ///
    /// - Parameters:
    ///   - action: 呈現子層送出的事件
    ///   - state: 容器目前的狀態，直接就地修改
    /// - Returns: 寫入子層或父層的請求，沒有就回傳 `.none`
    func forwardPresentation(
        _ action: OrdersPresentationFeature.Action,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .delegate(.saveRequested(let edit)):
            return .send(.writes(.saveRequested(edit)))

        case .delegate(.optionAddRequested(let request)):
            return .send(.delegate(.optionAddRequested(request)))

        case .delegate(.deleteConfirmed(let id)):
            return .send(.writes(.deleteRequested(id)))

        case .delegate(.aiSettingsRequested):
            return .send(.delegate(.aiSettingsRequested))

        case .delegate(.mergeCandidatesCompleted(let primary, let secondary, let photos)):
            let draft = OrdersContainerPlan.mergeCandidateDraft(
                primary: primary,
                secondary: secondary,
                state: state,
                now: date.now
            )
            return .send(.presentation(.mergeCandidateCompleted(draft: draft, keptPhotos: photos)))

        case .delegate(.mergeConfirmationDue(let draft, let keptPhotos)):
            let confirmation = OrdersContainerPlan.mergeConfirmation(
                draft: draft,
                keptPhotos: keptPhotos,
                state: state,
                formID: uuid(),
                context: OrderDateContext(now: date.now, calendar: calendar)
            )
            state.presentation.presentMergeConfirmation(confirmation)
            return .none

        case .destination, .mergeCandidateCompleted, .noticeRequested:
            return .none
        }
    }

    /// 寫入子層完成後套用結果到各子層，並回傳一次性通知的 Effect
    ///
    /// - Parameters:
    ///   - action: 寫入子層的事件，只有委派會被套用
    ///   - state: 容器目前的狀態，直接就地修改
    /// - Returns: 通知的 Effect，沒有就回傳 `.none`
    func applyWriteResult(
        _ action: OrderWritesFeature.Action,
        state: inout State
    ) -> Effect<Action> {
        guard case .delegate(let result) = action else {
            return .none
        }
        let outcome = OrdersContainerPlan.writeResult(result, state: state)
        state.detail.apply(outcome)
        state.presentation.apply(outcome)
        if let notice = outcome.notice {
            return .send(.presentation(.noticeRequested(notice)))
        }
        return .none
    }
}
