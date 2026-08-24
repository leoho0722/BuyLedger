//
//  OrdersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// 訂單列表以「日」為單位分組後的單一日期區段
struct OrderDateSection: Equatable, Identifiable, Sendable {
    
    // MARK: - Identifiable Properties
    
    /// 區段識別值，使用該日的起始時刻 (start of day)
    let id: Date
    
    // MARK: - Data Properties
    
    /// 區段標題 (例如「今天」「昨天」「5月26日 週一」)
    let title: String
    
    /// 該日的訂單，依時間由新到舊排序
    let orders: [LedgerOrder]
}

// MARK: - Internal Method

extension OrderDateSection {
    
    /// 把訂單依「日」分組為日期區段，供訂單列表與合併候選清單共用
    /// - Parameters:
    ///   - orders: 要分組的訂單
    ///   - referenceDate: 判斷「今天／昨天」的基準時間
    ///   - calendar: 分組與標題使用的曆法
    ///   - locale: App 選定、用於日期區段標題的 locale
    /// - Returns: 依日期由新到舊排序的區段
    static func group(
        _ orders: [LedgerOrder],
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> [OrderDateSection] {
        let grouped = Dictionary(grouping: orders) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped.keys
            .sorted(by: >)
            .map { day in
                OrderDateSection(
                    id: day,
                    title: OrderFormatters.daySectionTitle(
                        for: day,
                        referenceDate: referenceDate,
                        calendar: calendar,
                        locale: locale
                    ),
                    orders: (grouped[day] ?? []).sorted { $0.date > $1.date }
                )
            }
    }
}

/// 訂單列表與詳情選取流程
@Reducer
struct OrdersFeature {
    
    // MARK: - State
    
    /// 訂單功能狀態
    @ObservableState
    struct State: Equatable {
        
        /// 目前載入的訂單
        var orders: [LedgerOrder] = []
        
        /// 搜尋文字
        var searchText = ""
        
        /// 目前套用的狀態篩選
        var selectedStatus: OrderStatusFilter = .all
        
        /// 目前套用的日期區間篩選
        var selectedDatePeriod: OrderDatePeriod = .all
        
        /// 目前套用的商品類別篩選；`nil` 代表全部類別
        var selectedCategory: String?
        
        /// 目前套用的付款方式篩選；`nil` 代表全部付款方式
        var selectedPaymentMethod: String?
        
        /// 目前選取的訂單編號
        var selectedOrderID: LedgerOrder.ID?
        
        /// 是否處於多選模式 (進入後列點擊改為勾選、顯示批次工具列)
        var isSelecting = false
        
        /// 多選模式下已勾選的訂單編號集合
        var selectedOrderIDs: Set<LedgerOrder.ID> = []
        
        /// 四種主檔共用的目錄
        @Shared(.lookupCatalog) var lookupCatalog: LookupCatalog
        
        /// 訂單來源主檔 (從 ``OrderSourceRepository`` 載入)，衍生自 ``lookupCatalog``
        var orderSourceMaster: [String] { lookupCatalog.orderSources }
        
        /// 商品類別主檔 (從 ``CategoryRepository`` 載入)，衍生自 ``lookupCatalog``
        var categoryMaster: [String] { lookupCatalog.categories }
        
        /// 付款方式主檔與無卡旗標
        var paymentMethodMaster: [PaymentMethodInfo] { lookupCatalog.paymentMethods }
        
        /// 對帳狀態主檔
        var reconciliationStatusMaster: [String] { lookupCatalog.reconciliationStatuses }
        
        /// 開團主檔，供狀態篩選
        var campaigns: [Campaign] = []
        
        /// 目前套用的指定開團篩選；`nil` 代表全部開團
        var selectedCampaign: String?
        
        /// 目前套用的開團狀態篩選；`nil` 代表全部狀態
        var selectedCampaignStatus: CampaignStatus?
        
        /// 指示訂單是否正在載入
        var isLoading = false
        
        /// 是否已完成首次載入；完成後重複觸發 task 不會再次載入
        var hasLoaded = false
        
        /// 載入失敗時顯示的錯誤訊息
        var errorMessage: String?
        
        /// 目前呈現中的編輯／新增表單；`nil` 表示未呈現
        @Presents var editOrder: OrderEditFeature.State?
        
        /// 刪除訂單前的確認 alert 狀態；`nil` 表示未呈現
        @Presents var deletionConfirmation: AlertState<Action.Alert>?
        
        /// 單次寫入操作失敗時顯示的說明對話框；`nil` 表示未呈現
        @Presents var writeFailureAlert: AlertState<Action.Alert>?
        
        /// AI 商品明細總結 sheet 狀態；`nil` 表示未呈現
        @Presents var aiSummary: AISummaryFeature.State?
        
        /// AI 功能未開啟時的提示 alert；`nil` 表示未呈現
        @Presents var aiDisabledAlert: AlertState<Action.Alert>?
        
        /// 合併訂單流程的 sheet 狀態
        @Presents var orderMerge: OrderMergeFeature.State?
        
        /// iPhone 詳情的導覽路徑
        var detailPath = StackState<OrderDetailPath.State>()
        
        /// iPhone (compact) 整合篩選 sheet (日期 + 類別 + 付款方式) 是否呈現
        var showsFilterSheet: Bool = false
        
        /// 篩選 sheet 尚未套用的選擇
        var pendingFilterSelection = PendingFilterSelection()
        
        /// 篩選 sheet 的搜尋文字；開啟時清空
        var filterSheetSearchText: String = ""
        
        /// 篩選 sheet 捨棄變更的確認彈窗
        @Presents var filterDiscardConfirmation: AlertState<Action.FilterDiscardAlert>?
        
        /// iPad (regular) 商品類別篩選 picker sheet 是否呈現
        var showsCategoryPicker: Bool = false
        
        /// iPad (regular) 付款方式篩選 picker sheet 是否呈現
        var showsPaymentMethodPicker: Bool = false
        
        // MARK: - Computed Properties
        
        /// 依「已載入 → 有錯誤 → 其餘」的順序解析目前的載入狀態
        var loadState: LoadState {
            if hasLoaded {
                return .loaded
            }
            if let errorMessage {
                return .failed(errorMessage)
            }
            return .loading
        }
        
        /// 可用訂單來源清單，去重後依語言排序
        var availableOrderSources: [String] {
            let fromOrders =
            orders
                .map { $0.orderSource.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(orderSourceMaster)
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        
        /// 提供給編輯表單的可用類別，去重後排序
        var availableCategories: [String] {
            let fromOrders =
            orders
                .flatMap(\.categories)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(categoryMaster)
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        
        /// 可用付款方式清單；保留付款方式分類旗標
        var availablePaymentMethods: [PaymentMethodInfo] {
            var byName: [String: PaymentMethodInfo] = [:]
            for info in paymentMethodMaster {
                byName[info.name] = info
            }
            for order in orders {
                let trimmed = order.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, byName[trimmed] == nil else {
                    continue
                }
                byName[trimmed] = PaymentMethodInfo(
                    name: trimmed,
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                )
            }
            return byName.values
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        
        /// 可用對帳狀態清單，去重後依語言排序
        var availableReconciliationStatuses: [String] {
            let fromOrders =
            orders
                .map { $0.reconciliationStatus.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(reconciliationStatusMaster)
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        
        /// 可用開團清單，去重後依語言排序
        var availableCampaigns: [String] {
            let fromOrders =
            orders
                .flatMap(\.campaignNames)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(campaigns.map(\.name))
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        
        /// 可歸屬開團清單；只包含仍在收單的開團
        var ongoingCampaigns: [String] {
            let names =
            campaigns
                .filter { $0.status == .ongoing }
                .map(\.name)
            return Set(names).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }
    
    // MARK: - Action
    
    /// 訂單功能可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結事件
        case binding(BindingAction<State>)
        
        /// 畫面出現時觸發載入
        case task
        
        /// 訂單載入成功
        case ordersLoaded([LedgerOrder])
        
        /// 訂單載入失敗
        case ordersFailed(String)
        
        /// 訂單來源主檔載入完成
        case orderSourceMasterLoaded([String])
        
        /// 商品類別主檔載入完成
        case categoryMasterLoaded([String])
        
        /// 付款方式主檔載入完成
        case paymentMethodMasterLoaded([PaymentMethodInfo])
        
        /// 主檔更新成功後更新畫面副本
        case paymentMethodFlagsApplied([LedgerOrder])
        
        /// 對帳狀態主檔載入完成
        case reconciliationStatusMasterLoaded([String])
        
        /// 開團主檔載入完成
        case campaignsLoaded([Campaign])
        
        /// 使用者切換狀態篩選
        case statusFilterSelected(OrderStatusFilter)
        
        /// 使用者切換日期區間篩選
        case datePeriodSelected(OrderDatePeriod)
        
        /// 使用者切換商品類別篩選 (`nil` = 全部)
        case categoryFilterSelected(String?)
        
        /// 使用者切換付款方式篩選 (`nil` = 全部)
        case paymentMethodFilterSelected(String?)
        
        /// 使用者切換指定開團篩選 (`nil` = 全部開團)
        case campaignFilterSelected(String?)
        
        /// 使用者切換開團狀態篩選 (`nil` = 全部狀態)
        case campaignStatusFilterSelected(CampaignStatus?)
        
        /// 使用者點擊 iPad (regular) 商品類別篩選 trigger，開啟類別 picker sheet
        case categoryPickerTapped
        
        /// 使用者點擊 iPad (regular) 付款方式篩選 trigger，開啟付款方式 picker sheet
        case paymentMethodPickerTapped
        
        /// 使用者點擊 iPhone (compact) 整合篩選 trigger，開啟篩選 sheet
        case filterSheetTapped
        
        // MARK: 篩選 sheet 未套用流程
        
        /// 使用者在整合篩選 sheet 選擇日期區間；僅更新未套用選擇，不 commit
        case filterPendingDatePeriodSelected(OrderDatePeriod)
        
        /// 選擇商品類別；只更新未套用的選擇
        case filterPendingCategorySelected(String?)
        
        /// 選擇付款方式；只更新未套用的選擇
        case filterPendingPaymentMethodSelected(String?)
        
        /// 套用篩選並關閉 sheet
        case filterApplyTapped
        
        /// 取消篩選；有變更時先確認捨棄
        case filterCancelTapped
        
        /// 整合篩選 sheet 捨棄確認彈窗事件
        case filterDiscardConfirmation(PresentationAction<FilterDiscardAlert>)
        
        /// 使用者輸入搜尋文字
        case searchTextChanged(String)
        
        /// 使用者選取訂單
        case orderSelected(LedgerOrder.ID?)
        
        /// 使用者點擊「編輯」按鈕，要求編輯指定訂單
        case editOrderTapped(LedgerOrder.ID)
        
        /// 使用者點擊「新訂單」按鈕，要求建立空白訂單
        case newOrderTapped
        
        /// 編輯／新增表單事件
        case editOrder(PresentationAction<OrderEditFeature.Action>)
        
        /// 從訂單列或詳情頁開始合併
        case mergeOrderTapped(LedgerOrder.ID)
        
        /// 合併流程 sheet 事件；完成 delegate 由父層在此回收
        case orderMerge(PresentationAction<OrderMergeFeature.Action>)
        
        /// 完成合併選取後開啟確認表單
        case mergeConfirmationReady(OrderMerge.Draft, keptPhotos: [Data])
        
        /// 合併持久化失敗時，以快照回復訂單
        case mergePersistenceFailed([LedgerOrder])
        
        /// 編輯儲存成功後更新畫面狀態
        case orderSavePersisted(LedgerOrder, isNewOrder: Bool)
        
        /// 透過詳情頁的「更新狀態」menu 直接切換訂單狀態
        case statusChanged(LedgerOrder.ID, OrderStatus)
        
        /// 單筆狀態變更落盤成功，套用到畫面狀態
        case statusChangePersisted(LedgerOrder)
        
        /// 進入／退出多選模式；退出時清空已選集合
        case selectionModeToggled
        
        /// 多選模式下切換單筆訂單的勾選狀態
        case orderSelectionToggled(LedgerOrder.ID)
        
        /// 全選目前篩選後清單
        case selectAllTapped
        
        /// 清除目前已選集合
        case clearSelectionTapped
        
        /// 對已選訂單批次套用同一目標狀態 (目標清單已排除 merged)
        case batchStatusChanged(OrderStatus)
        
        /// 批次狀態變更落盤成功，套用到畫面狀態
        case batchStatusChangePersisted([LedgerOrder])
        
        /// 切換訂單收款狀態 (待收款／已收款)；供開團詳情頁逐筆勾稽收款使用
        case receiptStatusChanged(LedgerOrder.ID, PaymentReceiptStatus)
        
        /// 收款狀態變更落盤成功，套用到畫面狀態
        case receiptStatusChangePersisted(LedgerOrder)
        
        /// 要求刪除指定訂單；先二次確認
        case deleteOrderTapped(LedgerOrder.ID)
        
        /// 刪除確認 dialog 事件
        case deletionConfirmation(PresentationAction<Alert>)
        
        /// 刪除落盤成功，將指定訂單自畫面狀態移除
        case orderDeleted(LedgerOrder.ID)
        
        /// 單次寫入失敗；以對話框顯示原因
        case orderWriteFailed(String)
        
        /// 單次寫入失敗對話框事件
        case writeFailureAlert(PresentationAction<Alert>)
        
        /// 使用者點擊「AI 總結」工具列按鈕
        case aiSummaryTapped
        
        /// AI 總結 sheet 事件
        case aiSummary(PresentationAction<AISummaryFeature.Action>)
        
        /// AI 未開啟提示 alert 事件
        case aiDisabledAlert(PresentationAction<Alert>)
        
        /// iPhone 詳情導覽堆疊事件
        case detailPath(StackActionOf<OrderDetailPath>)
        
        /// 刪除確認 dialog 與 AI 提示 alert 共用的選項
        @CasePathable
        enum Alert: Equatable {
            
            /// 使用者確認刪除指定訂單
            case confirmDelete(LedgerOrder.ID)
            
            /// 使用者選擇前往設定開啟 AI 總結 (導覽由 ``RootFeature`` 攔截處理)
            case goToAISettings
        }
        
        /// 整合篩選 sheet 捨棄確認彈窗的選項
        @CasePathable
        enum FilterDiscardAlert: Equatable {
            
            /// 使用者確認捨棄未套用的篩選變更
            case discard
        }
    }
    
    // MARK: - Dependency Properties
    
    /// 訂單資料來源
    @Dependency(OrderRepository.self) private var orderRepository
    
    /// 訂單來源主檔資料來源
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository
    
    /// 商品類別主檔資料來源
    @Dependency(CategoryRepository.self) private var categoryRepository
    
    /// 付款方式主檔資料來源
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository
    
    /// 對帳狀態主檔資料來源
    @Dependency(ReconciliationStatusRepository.self) private var reconciliationStatusRepository
    
    /// 開團主檔資料來源
    @Dependency(CampaignRepository.self) private var campaignRepository
    
    /// 用於新訂單的 UUID 產生器，方便在測試中注入固定值
    @Dependency(\.uuid) private var uuid
    
    /// 用於新訂單的日期來源，方便在測試中注入固定值
    @Dependency(\.date) private var date
    
    /// 訂單篩選與日期分組使用的行事曆
    @Dependency(\.calendar) private var calendar
    
    /// 合併流程兩段 sheet 序列化呈現的延遲時脈；測試可注入 immediate clock
    @Dependency(\.continuousClock) private var clock
    
    /// 設定持久化來源；用於讀取 `useAiSummary` 與 `aiSummaryModel`
    @Dependency(SettingsStorage.self) private var settingsStorage
    
    // MARK: - Reducer Body
    
    /// 訂單功能 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .task:
                // 首次載入完成後不再重複觸發，避免切換分頁時反覆載入。
                // 讓依賴 `!isLoading` 判斷空狀態的 view 瞬間落入「有資料」分支
                guard !state.hasLoaded, !state.isLoading else {
                    return .none
                }
                
                let orderRepository = orderRepository
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let reconciliationStatusRepository = reconciliationStatusRepository
                let campaignRepository = campaignRepository
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    async let orderSourcesTask: Void = {
                        do {
                            let items = try await orderSourceRepository.fetchOrderSources()
                            await send(.orderSourceMasterLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let campaignsTask: Void = {
                        do {
                            let items = try await campaignRepository.fetchCampaigns()
                            await send(.campaignsLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let categoriesTask: Void = {
                        do {
                            let items = try await categoryRepository.fetchCategories()
                            await send(.categoryMasterLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let paymentMethodsTask: Void = {
                        do {
                            let infos = try await paymentMethodRepository.fetchPaymentMethodInfos()
                            await send(.paymentMethodMasterLoaded(infos))
                        } catch {
                            return
                        }
                    }()
                    async let reconciliationStatusesTask: Void = {
                        do {
                            let items =
                            try await reconciliationStatusRepository
                                .fetchReconciliationStatuses()
                            await send(.reconciliationStatusMasterLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    
                    do {
                        let orders = try await orderRepository.fetchOrders()
                        await send(.ordersLoaded(orders))
                    } catch {
                        await send(.ordersFailed("訂單載入失敗，請稍後再試。"))
                    }
                    
                    _ = await (
                        orderSourcesTask, campaignsTask, categoriesTask, paymentMethodsTask,
                        reconciliationStatusesTask
                    )
                }
                
            case let .orderSourceMasterLoaded(items):
                state.$lookupCatalog.withLock { $0.orderSources = items }
                return .none
                
            case let .categoryMasterLoaded(items):
                state.$lookupCatalog.withLock { $0.categories = items }
                return .none
                
            case let .paymentMethodMasterLoaded(infos):
                state.$lookupCatalog.withLock { $0.paymentMethods = infos }
                return .none
                
            case let .paymentMethodFlagsApplied(updatedOrders):
                let updatedByID = Dictionary(
                    uniqueKeysWithValues: updatedOrders.map { ($0.id, $0) }
                )
                state.orders = state.orders.map { updatedByID[$0.id] ?? $0 }
                return .none
                
            case let .reconciliationStatusMasterLoaded(items):
                state.$lookupCatalog.withLock { $0.reconciliationStatuses = items }
                return .none
                
            case let .campaignsLoaded(campaigns):
                // 訂單頁與開團頁各自評估結單日狀態
                guard !campaigns.isEmpty else {
                    state.campaigns = campaigns
                    return .none
                }
                let now = date.now
                var transitioned: [Campaign] = []
                let updated = campaigns.map { campaign -> Campaign in
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
                            await send(.orderWriteFailed("開團狀態自動更新失敗，請稍後再試。"))
                            break
                        }
                    }
                }
                
            case let .ordersLoaded(orders):
                state.isLoading = false
                state.hasLoaded = true
                state.orders = orders
                state.selectedOrderID = state.selectedOrderID ?? orders.first?.id
                state.pruneDetailPath()
                return .none
                
            case let .ordersFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case let .statusFilterSelected(filter):
                OrdersFilterOperations.statusFilterSelected(
                    filter, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case let .datePeriodSelected(period):
                OrdersFilterOperations.datePeriodSelected(
                    period, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case let .categoryFilterSelected(category):
                OrdersFilterOperations.categoryFilterSelected(
                    category, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case let .paymentMethodFilterSelected(paymentMethod):
                OrdersFilterOperations.paymentMethodFilterSelected(
                    paymentMethod, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case let .campaignFilterSelected(campaign):
                OrdersFilterOperations.campaignFilterSelected(
                    campaign, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case let .campaignStatusFilterSelected(campaignStatus):
                OrdersFilterOperations.campaignStatusFilterSelected(
                    campaignStatus, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case .categoryPickerTapped:
                OrdersFilterOperations.categoryPickerTapped(state: &state)
                return .none
                
            case .paymentMethodPickerTapped:
                OrdersFilterOperations.paymentMethodPickerTapped(state: &state)
                return .none
                
            case .filterSheetTapped:
                OrdersFilterOperations.filterSheetTapped(state: &state)
                return .none
                
                // MARK: 篩選 sheet 未套用流程
                
            case let .filterPendingDatePeriodSelected(period):
                OrdersFilterOperations.filterPendingDatePeriodSelected(period, state: &state)
                return .none
                
            case let .filterPendingCategorySelected(category):
                OrdersFilterOperations.filterPendingCategorySelected(category, state: &state)
                return .none
                
            case let .filterPendingPaymentMethodSelected(paymentMethod):
                OrdersFilterOperations.filterPendingPaymentMethodSelected(
                    paymentMethod, state: &state)
                return .none
                
            case .filterApplyTapped:
                OrdersFilterOperations.filterApplyTapped(
                    state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case .filterCancelTapped:
                OrdersFilterOperations.filterCancelTapped(state: &state)
                return .none
                
            case .filterDiscardConfirmation(.presented(.discard)):
                OrdersFilterOperations.filterDiscardConfirmed(state: &state)
                return .none
                
            case .filterDiscardConfirmation:
                return .none
                
            case let .searchTextChanged(searchText):
                OrdersFilterOperations.searchTextChanged(
                    searchText, state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case let .orderSelected(id):
                OrdersFilterOperations.orderSelected(id, state: &state)
                return .none
                
            case let .editOrderTapped(id):
                guard let order = state.orders.first(where: { $0.id == id }) else {
                    return .none
                }
                
                state.editOrder = OrderEditFeature.State(
                    original: order,
                    id: uuid(),
                    availableOrderSources: state.availableOrderSources,
                    availableCategories: state.availableCategories,
                    availablePaymentMethods: state.availablePaymentMethods,
                    availableReconciliationStatuses: state.availableReconciliationStatuses,
                    availableCampaigns: state.ongoingCampaigns,
                    currentDate: date.now
                )
                return .none
                
            case .newOrderTapped:
                state.editOrder = OrderEditFeature.State(
                    id: uuid(),
                    availableOrderSources: state.availableOrderSources,
                    availableCategories: state.availableCategories,
                    availablePaymentMethods: state.availablePaymentMethods,
                    availableReconciliationStatuses: state.availableReconciliationStatuses,
                    availableCampaigns: state.ongoingCampaigns,
                    currentDate: date.now
                )
                return .none
                
                // 拆分 Reduce 以避免型別檢查逾時
            case .editOrder, .mergeOrderTapped, .orderMerge, .mergeConfirmationReady,
                    .mergePersistenceFailed,
                    .orderSavePersisted, .statusChanged, .statusChangePersisted, .selectionModeToggled,
                    .orderSelectionToggled, .selectAllTapped, .clearSelectionTapped,
                    .batchStatusChanged,
                    .batchStatusChangePersisted, .receiptStatusChanged, .receiptStatusChangePersisted,
                    .deleteOrderTapped,
                    .deletionConfirmation, .orderDeleted, .orderWriteFailed, .writeFailureAlert,
                    .aiSummaryTapped,
                    .aiSummary, .aiDisabledAlert, .detailPath:
                return .none
            }
        }
        .ifLet(\.$filterDiscardConfirmation, action: \.filterDiscardConfirmation)
        
        Reduce { state, action in
            switch action {
            case .editOrder(.presented(.saveTapped)):
                guard let editState = state.editOrder else {
                    return .none
                }
                
                // 合併同時寫入新訂單並更新來源訂單狀態。
                if !editState.mergeSourceIDs.isEmpty {
                    guard let merge = OrdersMergeFlowOperations.mergeSaveTapped(
                        editState,
                        state: &state,
                        newOrderID: { uuid().uuidString }
                    ) else {
                        return .none
                    }
                    
                    let orderRepository = orderRepository
                    return .run { send in
                        do {
                            try await orderRepository.mergeOrders(merge.savedOrder, merge.sourceIDs)
                        } catch {
                            await send(.mergePersistenceFailed(merge.previousOrders))
                        }
                    }
                }
                
                // 一般編輯儲存 (含新增) 先寫後改，成功後才套用畫面狀態。
                // 依 resolveWriteResult 的分支決定建立或更新
                // 若原訂單已不在 state.orders，兩者可能不同。
                guard let result = OrderDraft.resolveWriteResult(
                    editState,
                    existingOrders: state.orders,
                    newOrderID: { uuid().uuidString }
                ) else {
                    return .none
                }
                
                return saveEffect(result)
                
            case let .orderSavePersisted(order, isNewOrder):
                OrderDraft.applyWriteResult((order: order, isNewOrder: isNewOrder), to: &state)
                return .none
                
            case let .editOrder(.presented(.addOrderSourceTapped(name))):
                // 子 reducer 已加入新來源與目前選擇
                // 同步主檔，讓其他畫面立即看到新項目
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                state.$lookupCatalog.withLock { $0.add(name: trimmed, kind: .orderSource) }
                let orderSourceRepository = orderSourceRepository
                return .run { _ in
                    try await orderSourceRepository.addOrderSource(trimmed)
                } catch: { _, send in
                    await send(.orderWriteFailed("訂單來源新增失敗，請稍後再試。"))
                }
                
            case let .editOrder(.presented(.addCategoryTapped(name))):
                // 子 reducer 已加入新類別與目前選擇
                // 同步主檔，讓其他畫面立即看到新項目
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                state.$lookupCatalog.withLock { $0.add(name: trimmed, kind: .category) }
                let categoryRepository = categoryRepository
                return .run { _ in
                    try await categoryRepository.addCategory(trimmed)
                } catch: { _, send in
                    await send(.orderWriteFailed("商品類別新增失敗，請稍後再試。"))
                }
                
            case let .editOrder(.presented(.addPaymentMethodTapped(name, flags))):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                // 同名付款方式以最新旗標覆寫
                state.$lookupCatalog.withLock {
                    $0.add(
                        name: trimmed,
                        kind: .paymentMethod,
                        flags: flags
                    )
                }
                
                let paymentMethodRepository = paymentMethodRepository
                return .run { _ in
                    try await paymentMethodRepository.addPaymentMethod(trimmed, flags)
                } catch: { _, send in
                    await send(.orderWriteFailed("付款方式新增失敗，請稍後再試。"))
                }
                
            case let .editOrder(.presented(.addReconciliationStatusTapped(name))):
                // 子 reducer 已加入新對帳狀態與目前選擇
                // 同步主檔，讓其他畫面立即看到新項目
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                state.$lookupCatalog.withLock { $0.add(name: trimmed, kind: .reconciliationStatus) }
                let reconciliationStatusRepository = reconciliationStatusRepository
                return .run { _ in
                    try await reconciliationStatusRepository.addReconciliationStatus(trimmed)
                } catch: { _, send in
                    await send(.orderWriteFailed("對帳狀態新增失敗，請稍後再試。"))
                }
                
            case .editOrder:
                return .none
                
            case let .mergeOrderTapped(orderID):
                OrdersMergeFlowOperations.mergeOrderTapped(orderID, state: &state)
                return .none
                
            case let .orderMerge(.presented(.delegate(.completed(primary, secondary, keptPhotos)))):
                let completed = OrdersMergeFlowOperations.mergeCandidateCompleted(
                    primary: primary,
                    secondary: secondary,
                    keptPhotos: keptPhotos,
                    state: &state,
                    now: date.now
                )
                let clock = clock
                return .run { send in
                    do {
                        try await clock.sleep(for: .milliseconds(500))
                    } catch {
                        return
                    }
                    await send(
                        .mergeConfirmationReady(completed.draft, keptPhotos: completed.keptPhotos))
                }
                
            case .orderMerge:
                return .none
                
            case let .mergeConfirmationReady(draft, keptPhotos):
                OrdersMergeFlowOperations.mergeConfirmationReady(
                    draft: draft,
                    keptPhotos: keptPhotos,
                    state: &state,
                    newFormID: uuid(),
                    currentDate: date.now
                )
                return .none
                
            case let .mergePersistenceFailed(previousOrders):
                OrdersMergeFlowOperations.mergePersistenceFailed(previousOrders, state: &state)
                return .none
                
                // 其餘 action 由下一段 Reduce 處理
                // 逐一列舉以保留編譯期窮舉檢查
            case .binding, .task, .orderSourceMasterLoaded, .categoryMasterLoaded,
                    .paymentMethodMasterLoaded, .paymentMethodFlagsApplied,
                    .reconciliationStatusMasterLoaded, .campaignsLoaded, .ordersLoaded, .ordersFailed,
                    .statusFilterSelected, .datePeriodSelected, .categoryFilterSelected,
                    .paymentMethodFilterSelected,
                    .campaignFilterSelected, .campaignStatusFilterSelected, .categoryPickerTapped,
                    .paymentMethodPickerTapped, .filterSheetTapped, .filterPendingDatePeriodSelected,
                    .filterPendingCategorySelected, .filterPendingPaymentMethodSelected,
                    .filterApplyTapped,
                    .filterCancelTapped, .filterDiscardConfirmation, .searchTextChanged, .orderSelected,
                    .editOrderTapped, .newOrderTapped, .statusChanged, .statusChangePersisted,
                    .selectionModeToggled,
                    .orderSelectionToggled, .selectAllTapped, .clearSelectionTapped,
                    .batchStatusChanged,
                    .batchStatusChangePersisted, .receiptStatusChanged, .receiptStatusChangePersisted,
                    .deleteOrderTapped,
                    .deletionConfirmation, .orderDeleted, .orderWriteFailed, .writeFailureAlert,
                    .aiSummaryTapped,
                    .aiSummary, .aiDisabledAlert, .detailPath:
                return .none
            }
        }
        .ifLet(\.$editOrder, action: \.editOrder) {
            OrderEditFeature()
        }
        .ifLet(\.$orderMerge, action: \.orderMerge) {
            OrderMergeFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .statusChanged(orderID, newStatus):
                guard let existing = state.orders.first(where: { $0.id == orderID }),
                      existing.status != newStatus
                else {
                    return .none
                }
                
                // 寫入成功後才更新畫面，失敗時保留原訂單。
                return statusChangeEffect(existing.withStatus(newStatus))
                
            case let .statusChangePersisted(updated):
                guard let index = state.orders.firstIndex(where: { $0.id == updated.id }) else {
                    return .none
                }
                state.orders[index] = updated
                return .none
                
            case .selectionModeToggled:
                OrdersBatchOperations.selectionModeToggled(state: &state)
                return .none
                
            case let .orderSelectionToggled(id):
                OrdersBatchOperations.orderSelectionToggled(id, state: &state)
                return .none
                
            case .selectAllTapped:
                OrdersBatchOperations.selectAllTapped(
                    state: &state, referenceDate: date.now, calendar: calendar)
                return .none
                
            case .clearSelectionTapped:
                OrdersBatchOperations.clearSelectionTapped(state: &state)
                return .none
                
            case let .batchStatusChanged(newStatus):
                guard
                    let changed = OrdersBatchOperations.batchStatusChanged(newStatus, state: &state)
                else {
                    return .none
                }
                return batchStatusChangeEffect(changed)
                
            case let .batchStatusChangePersisted(changedOrders):
                OrdersBatchOperations.batchStatusChangePersisted(changedOrders, state: &state)
                return .none
                
            case let .receiptStatusChanged(orderID, newReceiptStatus):
                guard let existing = state.orders.first(where: { $0.id == orderID }),
                      existing.paymentReceiptStatus != newReceiptStatus
                else {
                    return .none
                }
                
                // 先寫後改：畫面狀態於落盤成功後才套用
                return receiptStatusChangeEffect(
                    existing.withPaymentReceiptStatus(newReceiptStatus))
                
            case let .receiptStatusChangePersisted(updated):
                guard let index = state.orders.firstIndex(where: { $0.id == updated.id }) else {
                    return .none
                }
                state.orders[index] = updated
                return .none
                
            case let .deleteOrderTapped(id):
                guard let order = state.orders.first(where: { $0.id == id }) else {
                    return .none
                }
                
                state.deletionConfirmation = AlertState {
                    TextState("刪除訂單")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(id)) {
                        TextState("刪除")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState("刪除「\(order.customer.name)」的這筆訂單後無法復原。")
                }
                return .none
                
            case let .deletionConfirmation(.presented(.confirmDelete(id))):
                // 寫入成功後才移除，失敗時保留項目。
                guard state.orders.contains(where: { $0.id == id }) else {
                    return .none
                }
                
                return deletionEffect(id)
                
            case .deletionConfirmation:
                return .none
                
            case let .orderDeleted(id):
                guard let index = state.orders.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                
                state.orders.remove(at: index)
                state.pruneDetailPath()
                
                if state.selectedOrderID == id {
                    state.selectFirstFilteredOrder(referenceDate: date.now, calendar: calendar)
                }
                
                if state.editOrder?.original?.id == id {
                    state.editOrder = nil
                }
                return .none
                
            case let .orderWriteFailed(message):
                // String 需明確轉成 LocalizedStringKey
                state.writeFailureAlert = Self.makeWriteFailureAlert(LocalizedStringKey(message))
                return .none
                
            case .writeFailureAlert:
                return .none
                
            case .detailPath:
                return .none
                
            case .aiSummaryTapped:
                let snapshot = settingsStorage.load()
                guard snapshot.useAiSummary else {
                    state.aiDisabledAlert = AlertState {
                        TextState("AI 商品明細總結")
                    } actions: {
                        ButtonState(role: .cancel) {
                            TextState("關閉")
                        }
                        ButtonState(action: .goToAISettings) {
                            TextState("前往開啟")
                        }
                    } message: {
                        TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
                    }
                    return .none
                }
                state.aiSummary = AISummaryFeature.State(
                    prompt: state.aiSummaryPrompt(referenceDate: date.now, calendar: calendar),
                    model: snapshot.aiSummaryModel
                )
                return .none
                
                // RootFeature 負責導覽，這裡只呈現 alert
            case .aiDisabledAlert:
                return .none
                
            case .aiSummary:
                return .none
                
                // 這段 Reduce 處理前兩段未涵蓋的 action
                // 逐一列舉以保留編譯期窮舉檢查
            case .binding, .task, .orderSourceMasterLoaded, .categoryMasterLoaded,
                    .paymentMethodMasterLoaded, .paymentMethodFlagsApplied,
                    .reconciliationStatusMasterLoaded, .campaignsLoaded, .ordersLoaded, .ordersFailed,
                    .statusFilterSelected, .datePeriodSelected, .categoryFilterSelected,
                    .paymentMethodFilterSelected,
                    .campaignFilterSelected, .campaignStatusFilterSelected, .categoryPickerTapped,
                    .paymentMethodPickerTapped, .filterSheetTapped, .filterPendingDatePeriodSelected,
                    .filterPendingCategorySelected, .filterPendingPaymentMethodSelected,
                    .filterApplyTapped,
                    .filterCancelTapped, .filterDiscardConfirmation, .searchTextChanged, .orderSelected,
                    .editOrderTapped, .newOrderTapped, .editOrder, .mergeOrderTapped, .orderMerge,
                    .mergeConfirmationReady, .mergePersistenceFailed, .orderSavePersisted:
                return .none
            }
        }
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
        .ifLet(\.$writeFailureAlert, action: \.writeFailureAlert)
        .ifLet(\.$aiSummary, action: \.aiSummary) {
            AISummaryFeature()
        }
        .ifLet(\.$aiDisabledAlert, action: \.aiDisabledAlert)
        .forEach(\.detailPath, action: \.detailPath) {
            OrderDetailPath()
        }
    }
}

// MARK: - Nested Types

extension OrdersFeature.State {
    
    /// 訂單載入的三種解析結果
    enum LoadState: Equatable {
        
        // MARK: - Cases
        
        /// 已完成載入，顯示正常內容
        case loaded
        
        /// 載入失敗，附帶失敗原因
        case failed(String)
        
        /// 載入中
        case loading
    }
    
    /// 整合篩選 sheet 尚未套用的三欄選擇
    struct PendingFilterSelection: Equatable {
        
        // MARK: - Data Properties
        
        /// 尚未套用的日期區間選擇
        var datePeriod: OrderDatePeriod = .all
        
        /// 尚未套用的商品類別選擇；`nil` 代表全部類別
        var category: String?
        
        /// 尚未套用的付款方式選擇；`nil` 代表全部付款方式
        var paymentMethod: String?

        /// 是否至少有一項非預設的整合篩選條件
        var isActive: Bool {
            datePeriod != .all || category != nil || paymentMethod != nil
        }
    }
}

// MARK: - Internal Method

extension OrdersFeature.State {
    
    /// 將選取重設為篩選結果的第一筆
    /// - Parameters:
    ///   - referenceDate: 篩選使用的基準時間
    ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆
    mutating func selectFirstFilteredOrder(referenceDate: Date, calendar: Calendar) {
        selectedOrderID = filteredOrders(referenceDate: referenceDate, calendar: calendar).first?.id
    }
    
    /// 修剪 iPhone 詳情導覽中已不存在的訂單
    mutating func pruneDetailPath() {
        let availableIDs = Set(orders.map(\.id))
        detailPath.removeAll { !availableIDs.contains($0.orderID) }
    }
}

// MARK: - Internal Method

extension OrdersFeature {
    
    /// 建立單次寫入失敗的說明對話框
    /// - Parameter message: 顯示給使用者的失敗原因
    /// - Returns: 僅含「知道了」關閉鈕的說明對話框
    static func makeWriteFailureAlert(_ message: LocalizedStringKey) -> AlertState<Action.Alert> {
        AlertState {
            TextState("操作失敗")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }
}

// MARK: - Private Method

private extension OrdersFeature {
    
    /// 建立先寫後改的狀態變更 effect
    /// - Parameter updated: 已重建狀態的訂單
    /// - Returns: 對應的 effect
    func statusChangeEffect(_ updated: LedgerOrder) -> Effect<Action> {
        let orderRepository = orderRepository
        return .run { send in
            do {
                try await orderRepository.saveOrder(updated)
                await send(.statusChangePersisted(updated))
            } catch {
                await send(.orderWriteFailed("訂單狀態更新失敗，請稍後再試。"))
            }
        }
    }
    
    /// 建立收款狀態變更的先寫後改 effect
    /// - Parameter updated: 已重建收款狀態的訂單
    /// - Returns: 對應的 effect
    func receiptStatusChangeEffect(_ updated: LedgerOrder) -> Effect<Action> {
        let orderRepository = orderRepository
        return .run { send in
            do {
                try await orderRepository.saveOrder(updated)
                await send(.receiptStatusChangePersisted(updated))
            } catch {
                await send(.orderWriteFailed("收款狀態更新失敗，請稍後再試。"))
            }
        }
    }
    
    /// 建立批次狀態變更的先寫後改 effect
    /// - Parameter changed: 已重建狀態的訂單清單 (非空)
    /// - Returns: 對應的 effect
    func batchStatusChangeEffect(_ changed: [LedgerOrder]) -> Effect<Action> {
        let orderRepository = orderRepository
        return .run { send in
            do {
                try await orderRepository.saveOrders(changed)
                await send(.batchStatusChangePersisted(changed))
            } catch {
                await send(.orderWriteFailed("批次更新狀態失敗，請稍後再試。"))
            }
        }
    }
    
    /// 建立刪除的先寫後改 effect
    /// - Parameter id: 要刪除的訂單編號
    /// - Returns: 對應的 effect
    func deletionEffect(_ id: LedgerOrder.ID) -> Effect<Action> {
        let orderRepository = orderRepository
        return .run { send in
            do {
                try await orderRepository.removeOrder(id)
                await send(.orderDeleted(id))
            } catch {
                await send(.orderWriteFailed("訂單刪除失敗，請稍後再試。"))
            }
        }
    }
    
    /// 建立編輯儲存 (含新增) 的先寫後改 effect
    /// - Parameter result: 訂單草稿計算出的寫入結果
    /// - Returns: 對應的 effect
    func saveEffect(_ result: OrderDraft.WriteResult) -> Effect<Action> {
        let orderRepository = orderRepository
        return .run { send in
            do {
                if result.isNewOrder {
                    try await orderRepository.createOrder(result.order)
                } else if result.writesPhotos {
                    try await orderRepository.saveOrderPersistingPhotos(result.order)
                } else {
                    try await orderRepository.saveOrder(result.order)
                }
                await send(.orderSavePersisted(result.order, isNewOrder: result.isNewOrder))
            } catch {
                await send(.orderWriteFailed("訂單儲存失敗，請稍後再試。"))
            }
        }
    }
}
