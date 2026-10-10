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

    /// 管理訂單列表載入、篩選、選取與呈現所需的狀態
    @ObservableState
    struct State: Equatable {

        /// 目前載入的訂單
        @Shared var orders: [LedgerOrder]

        /// 訂單清單的篩選、搜尋、多選與選取
        var list: OrderListFeature.State

        /// 四種主檔共用的目錄
        @Shared(.lookupCatalog) var lookupCatalog: LookupCatalog

        /// 啟動時載入的共用幣別清單，表單建立時只讀取現有值
        @SharedReader(.currencyCodes) var currencyCodes: [CurrencyCode]

        /// 新訂單的預設幣別投影，只由 Root 在初始化與偏好變更時寫入
        var defaultCurrency: CurrencyCode = .twd

        /// Root 同步的 AI 摘要開關與模型，容器只讀取
        var aiSummarySettings: OrderAISummarySettings = OrderAISummarySettings(
            isEnabled: SettingsSnapshot.default.isAISummaryEnabled,
            model: SettingsSnapshot.default.aiSummaryModel
        )

        /// 開團主檔投影，由 Root 同步，供建立訂單編輯選項
        var campaigns: [Campaign] = []

        /// 訂單與主檔的載入子 Feature
        var load: OrdersLoadFeature.State

        /// 訂單持久化與成功後共用資料更新的子 Feature
        var writes: OrderWritesFeature.State

        /// 表單、alert 與一次性通知的呈現子 Feature
        var presentation = OrdersPresentationFeature.State()

        /// iPhone 詳情堆疊與 iPad 右欄詳情的導覽子 Feature
        var detail: OrdersDetailNavigationFeature.State

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
                isLoading: SharedReader(load.$isLoading),
                hasLoaded: SharedReader(load.$hasLoaded),
                errorMessage: SharedReader(load.$errorMessage)
            )
            self.detail = OrdersDetailNavigationFeature.State(orders: SharedReader(sharedOrders))
        }

        /// 經清單套用跨功能篩選並重選第一筆，右欄詳情同步到新選取
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
            refreshDateContext(now: now, calendar: calendar)
            list.applyFilterNavigation(searchText: searchText, category: category)
            detail.syncRegularDetail(selectedOrderID: list.selectedOrderID)
        }

        /// 刷新清單的日期脈絡，供 Root 的前景與重大時間變更共用
        ///
        /// - Parameters:
        ///   - now: 新的現在時間
        ///   - calendar: 新的行事曆與時區
        mutating func refreshDateContext(now: Date, calendar: Calendar) {
            list.dateContext = OrderDateContext(now: now, calendar: calendar)
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
    @CasePathable
    enum Action: BindableAction {

        /// `SwiftUI` 雙向繫結事件
        ///
        /// - Parameter action: 由 `State` 的雙向繫結產生的事件
        case binding(BindingAction<State>)

        /// 容器畫面的使用者事件
        ///
        /// - Parameter action: sheet 關閉動畫完成的事件
        case view(View)

        /// 交由父層處理的跨功能意圖
        ///
        /// - Parameter action: 訂單功能送出的委派
        case delegate(Delegate)

        /// 詳情導覽子 Feature 的堆疊與右欄事件
        ///
        /// - Parameter action: iPhone 堆疊與 iPad 右欄的事件
        case detail(OrdersDetailNavigationFeature.Action)

        /// 呈現子 Feature 的表單、alert 與通知事件
        ///
        /// - Parameter action: 目的地內部事件、委派或一次性通知
        case presentation(OrdersPresentationFeature.Action)

        /// 父層要求套用開團刪除、開團改名或主檔改名後的訂單調整
        ///
        /// - Parameter request: 開團刪除、開團改名或主檔改名
        case cascadeRequested(OrdersCascadeOperations.Request)

        /// 清單子 Feature 的互動與委派
        ///
        /// - Parameter action: 清單事件
        case list(OrderListFeature.Action)

        /// 訂單載入子 Feature 的請求、回應與失敗委派
        ///
        /// - Parameter action: 載入子層的事件
        case load(OrdersLoadFeature.Action)

        /// 父層要求載入共用訂單與主檔，由載入子 Feature 去重
        case loadRequested

        /// 父層要求套用主檔更新成功後的訂單，不重複落盤
        ///
        /// - Parameter orders: 套用付款方式旗標後的訂單
        case paymentMethodFlagsApplyRequested([LedgerOrder])

        /// 父層要求切換訂單收款狀態，供開團詳情頁逐筆勾稽收款使用
        ///
        /// - Parameters:
        ///   - id: 要更新收款狀態的訂單編號
        ///   - status: 要套用的收款狀態
        case receiptStatusChangeRequested(id: LedgerOrder.ID, status: PaymentReceiptStatus)

        /// 訂單寫入子 Feature 的請求、回應與委派
        ///
        /// - Parameter action: 寫入子層事件
        case writes(OrderWritesFeature.Action)

        /// 容器畫面的使用者事件
        @CasePathable
        enum View {

            /// 任一表單 sheet 的關閉動畫已完成
            case formSheetDismissed
        }

        /// 訂單功能交給父層的導覽意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 要求開啟設定頁以啟用 AI 商品明細總結
            case aiSettingsRequested
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

    /// 組合雙向繫結、清單與載入子層、寫入與呈現子層，最後由 `core(state:action:)` 分派請求
    var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.list, action: \.list) {
            OrderListFeature()
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

        case .view(.formSheetDismissed):
            state.presentation.finishFormClosing()
            return .none

        case .delegate:
            return .none

        case .detail(.path(.element(_, .detail(.delegate(.requested(let request)))))),
                .detail(.regularDetail(.delegate(.requested(let request)))):
            return fulfill(request, state: &state)

        case .detail:
            return .none

        case .presentation(let action):
            return forwardPresentation(action, state: &state)

        case .cascadeRequested(let request):
            return .send(.writes(.cascadeRequested(request)))

        case .list(.delegate(.loadRequested)):
            return .send(.load(.loadRequested))

        case .list(.delegate(.requested(let request))):
            return fulfill(request, state: &state)

        case .list(.delegate(.selectionChanged)):
            state.detail.syncRegularDetail(selectedOrderID: state.list.selectedOrderID)
            return .none

        case .list:
            return .none

        case .load:
            return .none

        case .loadRequested:
            return .send(.load(.loadRequested))

        case .paymentMethodFlagsApplyRequested(let orders):
            return .send(.writes(.paymentMethodFlagsApplyRequested(orders)))

        case .receiptStatusChangeRequested(let id, let status):
            return .send(.writes(.receiptToggleRequested(id: id, status: status)))

        case .writes(let action):
            return applyWriteResult(action, state: &state)
        }
    }

    /// 首次載入完成後預設選取第一筆，並移除已不存在訂單的詳情、同步右欄詳情
    ///
    /// - Parameter state: 容器目前的狀態，直接就地修改
    /// - Returns: 沒有後續效果，回傳 `.none`
    func applyLoadedOrders(state: inout State) -> Effect<Action> {
        guard state.load.hasLoaded else {
            return .none
        }
        state.list.selectedOrderID = state.list.selectedOrderID ?? state.orders.first?.id
        state.detail.applyLoadedOrders(selectedOrderID: state.list.selectedOrderID)
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

        case .showDetail(let id):
            state.detail.showDetail(orderID: id)
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

        case .delegate(.optionAddRequested(let plan)):
            return .send(.writes(.optionAddRequested(plan)))

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

    /// 寫入子層完成後套用結果到各子層，並回傳清單選取或一次性通知的 Effect
    ///
    /// - Parameters:
    ///   - action: 寫入子層的事件，只有委派會被套用
    ///   - state: 容器目前的狀態，直接就地修改
    /// - Returns: 選取變更或通知的 Effect，沒有就回傳 `.none`
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
        if let selection = outcome.selection {
            state.list.selectedOrderID = selection.orderID
            if selection.shouldNotify {
                return .send(.list(.delegate(.selectionChanged(selection.orderID))))
            }
        }
        if let notice = outcome.notice {
            return .send(.presentation(.noticeRequested(notice)))
        }
        return .none
    }
}
