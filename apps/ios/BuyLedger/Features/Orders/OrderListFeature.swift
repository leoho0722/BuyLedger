//
//  OrderListFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

/// 訂單清單的篩選、搜尋、多選與日期分組
@Reducer
struct OrderListFeature {

    // MARK: - State

    /// 清單的唯讀資料、篩選與選取
    @ObservableState
    struct State: Equatable {

        /// 容器、載入與寫入子層共用的唯讀訂單
        @SharedReader var orders: [LedgerOrder]

        /// 用於過濾訂單列表的搜尋文字
        var searchText = ""

        /// 目前套用的狀態篩選
        var selectedStatus: OrderStatusFilter = .all

        /// 目前套用的日期區間篩選
        var selectedDatePeriod: OrderDatePeriod = .all

        /// 目前套用的商品類別篩選；`nil` 代表全部類別
        var selectedCategory: String?

        /// 目前套用的付款方式篩選；`nil` 代表全部付款方式
        var selectedPaymentMethod: String?

        /// 詳情區目前選取訂單的識別值；`nil` 代表尚未選取
        var selectedOrderID: LedgerOrder.ID?

        /// 是否處於多選模式 (進入後列點擊改為勾選、顯示批次工具列)
        var isSelecting = false

        /// 多選模式下已勾選的訂單編號集合
        var selectedOrderIDs: Set<LedgerOrder.ID> = []

        /// 篩選使用的四種主檔目錄
        @Shared(.lookupCatalog) var lookupCatalog: LookupCatalog

        /// 目前是否正在載入，由載入子層維護
        @SharedReader var isLoading: Bool

        /// 是否已完成載入，由載入子層維護
        @SharedReader var hasLoaded: Bool

        /// 持續顯示的載入失敗訊息
        @SharedReader var errorMessage: String?

        /// 最近一次出現、重試或 Root 刷新時記錄的時間與行事曆
        var dateContext: OrderDateContext?

        /// iPhone (compact) 整合篩選 sheet 的暫存流程
        @Presents var filterSheet: OrderFilterFeature.State?

        /// iPad (regular) 商品類別篩選 picker sheet 是否呈現
        var isCategoryPickerPresented: Bool = false

        /// iPad (regular) 付款方式篩選 picker sheet 是否呈現
        var isPaymentMethodPickerPresented: Bool = false

        /// 依多選筆數顯示清單標題
        var navigationTitleKey: String.LocalizationValue {
            OrdersListQuery.navigationTitle(isSelecting: isSelecting, count: selectedOrderIDs.count)
        }

        /// 已套用的日期、類別與付款方式
        var committedFilterSelection: OrderFilterSelection {
            OrderFilterSelection(
                datePeriod: selectedDatePeriod,
                category: selectedCategory,
                paymentMethod: selectedPaymentMethod
            )
        }

        /// 是否已套用商品類別篩選
        var hasCategoryFilter: Bool {
            selectedCategory != nil
        }

        /// 是否已套用付款方式篩選
        var hasPaymentMethodFilter: Bool {
            selectedPaymentMethod != nil
        }

        /// 依記錄的日期與篩選條件取出的訂單
        var filteredOrders: [LedgerOrder] {
            OrdersListQuery.filteredOrders(state: self)
        }

        /// 篩選結果的訂單識別值，供窄版與寬版工具列共用
        var filteredIDs: [LedgerOrder.ID] {
            filteredOrders.map(\.id)
        }

        /// 非空的篩選結果是否全部已勾選，允許另有篩選外的勾選
        var isAllFilteredSelected: Bool {
            OrdersListQuery.isAllFilteredSelected(state: self)
        }

        /// 主檔與訂單已使用的類別
        var availableCategories: [String] {
            OrdersListQuery.availableCategories(orders: orders, catalog: lookupCatalog)
        }

        /// 主檔與訂單已使用的付款方式
        var availablePaymentMethods: [PaymentMethodInfo] {
            OrdersListQuery.availablePaymentMethods(orders: orders, catalog: lookupCatalog)
        }

        /// 付款方式篩選 picker 顯示的名稱，順序與 `availablePaymentMethods` 相同
        var availablePaymentMethodNames: [String] {
            availablePaymentMethods.map(\.name)
        }

        /// 依載入結果解析清單顯示狀態
        var loadState: OrdersLoadState {
            OrdersListQuery.loadState(hasLoaded: hasLoaded, errorMessage: errorMessage)
        }

        /// 建立清單的唯讀訂單與載入狀態
        ///
        /// - Parameters:
        ///   - orders: 共用訂單的唯讀引用
        ///   - isLoading: 載入中的旗標
        ///   - hasLoaded: 已載入的旗標
        ///   - errorMessage: 載入錯誤訊息
        init(
            orders: SharedReader<[LedgerOrder]>,
            isLoading: SharedReader<Bool> = SharedReader(value: false),
            hasLoaded: SharedReader<Bool> = SharedReader(value: false),
            errorMessage: SharedReader<String?> = SharedReader(value: nil)
        ) {
            self._orders = orders
            self._isLoading = isLoading
            self._hasLoaded = hasLoaded
            self._errorMessage = errorMessage
        }

        /// 提供已套用篩選的本地化摘要，窄版與寬版共用相同的文字規則
        ///
        /// - Parameter language: 畫面使用的語言
        /// - Returns: 本地化日期與全部提示，主檔名稱保留原文
        func filterSummary(language: AppLanguage) -> String {
            OrdersListQuery.filterSummary(selection: committedFilterSelection, language: language)
        }

        /// 依記錄的時間與呼叫端語系產生日期區段
        ///
        /// - Parameter locale: 畫面選用的語系
        /// - Returns: 由新到舊排列的區段
        func dateSections(locale: Locale) -> [OrderDateSection] {
            OrdersListQuery.dateSections(state: self, locale: locale)
        }

        /// 將右欄選取重設為篩選結果的第一筆
        mutating func selectFirstFilteredOrder() {
            selectedOrderID = filteredOrders.first?.id
        }

        /// 套用跨功能篩選並重選第一筆，保留付款方式篩選
        ///
        /// - Parameters:
        ///   - searchText: 客戶名稱搜尋；類別導覽時為空
        ///   - category: 精準類別；客戶導覽時為 `nil`
        mutating func applyFilterNavigation(searchText: String, category: String?) {
            OrdersFilterOperations.applyNavigation(searchText, category: category, state: &self)
        }
    }

    // MARK: - Action

    /// 清單畫面的互動與交給容器的請求
    enum Action: BindableAction {

        /// 清單與 picker 的雙向繫結
        ///
        /// - Parameter action: 欄位變更
        case binding(BindingAction<State>)

        /// 使用者的清單操作
        ///
        /// - Parameter action: 實際互動
        case view(View)

        /// 容器需要處理的事件
        ///
        /// - Parameter action: 操作請求或選取變更
        case delegate(Delegate)

        /// 篩選 sheet 的呈現與子層事件
        ///
        /// - Parameter action: 暫存選擇、套用或關閉
        case filterSheet(PresentationAction<OrderFilterFeature.Action>)

        /// 清單畫面送出的互動
        @CasePathable
        enum View {

            /// 清單出現
            case task

            /// 重試載入
            case retryTapped

            /// 使用者切換狀態篩選
            ///
            /// - Parameter filter: 要套用的訂單狀態篩選
            case statusFilterSelected(OrderStatusFilter)

            /// 使用者切換日期區間篩選
            ///
            /// - Parameter period: 要套用的日期區間
            case datePeriodSelected(OrderDatePeriod)

            /// 使用者切換商品類別篩選
            ///
            /// - Parameter category: 商品類別；`nil` 表示全部類別
            case categoryFilterSelected(String?)

            /// 使用者切換付款方式篩選
            ///
            /// - Parameter paymentMethod: 付款方式；`nil` 表示全部付款方式
            case paymentMethodFilterSelected(String?)

            /// 使用者點擊 iPad (regular) 商品類別篩選 trigger，開啟類別 picker sheet
            case categoryPickerTapped

            /// 使用者點擊 iPad (regular) 付款方式篩選 trigger，開啟付款方式 picker sheet
            case paymentMethodPickerTapped

            /// 使用者點擊 iPhone (compact) 整合篩選 trigger，開啟篩選 sheet
            case filterSheetTapped

            /// 使用者輸入搜尋文字
            ///
            /// - Parameter text: 搜尋文字
            case searchTextChanged(String)

            /// 使用者選取訂單
            ///
            /// - Parameter id: 訂單編號；`nil` 表示取消選取
            case orderSelected(LedgerOrder.ID?)

            /// 使用者點擊「編輯」按鈕，要求編輯指定訂單
            ///
            /// - Parameter id: 要編輯的訂單編號
            case editOrderTapped(LedgerOrder.ID)

            /// 使用者點擊「新訂單」按鈕，要求建立空白訂單
            case newOrderTapped

            /// 從訂單列或詳情頁開始合併
            ///
            /// - Parameter id: 要合併的訂單編號
            case mergeOrderTapped(LedgerOrder.ID)

            /// 進入／退出多選模式；退出時清空已選集合
            case selectionModeToggled

            /// 多選模式下切換單筆訂單的勾選狀態
            ///
            /// - Parameter id: 要切換勾選狀態的訂單編號
            case orderSelectionToggled(LedgerOrder.ID)

            /// 全選目前篩選後清單
            case selectAllTapped

            /// 清除目前已選集合
            case clearSelectionTapped

            /// 對已選訂單批次套用同一目標狀態 (目標清單已排除 `merged`)
            ///
            /// - Parameter status: 要套用的訂單狀態
            case batchStatusChanged(OrderStatus)

            /// 要求刪除指定訂單；先二次確認
            ///
            /// - Parameter id: 要刪除的訂單編號
            case deleteOrderTapped(LedgerOrder.ID)

            /// 使用者點擊「AI 總結」工具列按鈕
            case aiSummaryTapped

            /// 點擊訂單列，請容器推入詳情
            ///
            /// - Parameter id: 訂單識別值
            case orderTapped(LedgerOrder.ID)
        }

        /// 交給容器的載入、操作與選取需求
        @CasePathable
        enum Delegate: Equatable {

            /// 請容器決定呈現或寫入
            ///
            /// - Parameter request: 訂單操作
            case requested(OrderRequest)

            /// 畫面出現或重試，請容器載入共用資料
            case loadRequested

            /// 右欄選取已變更
            ///
            /// - Parameter id: 新選取的訂單；`nil` 表示清空
            case selectionChanged(LedgerOrder.ID?)
        }
    }

    // MARK: - Dependencies

    /// 清單出現或重試時使用的現在時間
    @Dependency(\.date) private var date

    /// 日期篩選與分組的行事曆
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// 組合清單繫結、互動與篩選子層
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce(core)
            .ifLet(\.$filterSheet, action: \.filterSheet) {
                OrderFilterFeature()
            }
    }
}

// MARK: - Private Method

private extension OrderListFeature {

    /// 依事件宣告順序處理清單互動與篩選子層委派
    ///
    /// - Parameters:
    ///   - state: 清單狀態
    ///   - action: 使用者操作或委派
    /// - Returns: 容器需要處理的請求
    func core(state: inout State, action: Action) -> Effect<Action> {
        defer {
            let committed = state.committedFilterSelection
            state.filterSheet?.committedFilterSelection = committed
        }
        switch action {
        case .binding:
            return .none

        case .view(.task), .view(.retryTapped):
            state.dateContext = OrderDateContext(now: date.now, calendar: calendar)
            return .send(.delegate(.loadRequested))

        case .view(let view):
            guard let delegate = OrderListInteraction.apply(view, state: &state) else {
                return .none
            }
            return .send(.delegate(delegate))

        case .delegate:
            return .none

        case .filterSheet(.presented(.delegate(.applied(let selection)))):
            let previousID = state.selectedOrderID
            OrdersFilterOperations.filterApplied(selection, state: &state)
            guard previousID != state.selectedOrderID else {
                return .none
            }
            return .send(.delegate(.selectionChanged(state.selectedOrderID)))

        case .filterSheet(.presented(.delegate(.cancelled))):
            state.filterSheet = nil
            return .none

        case .filterSheet:
            return .none
        }
    }
}
