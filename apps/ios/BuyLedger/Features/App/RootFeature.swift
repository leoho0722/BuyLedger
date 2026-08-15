//
//  RootFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// App 根層級狀態與導覽
@Reducer
struct RootFeature {
    
    // MARK: - State
    
    /// App 根層級狀態
    @ObservableState
    struct State: Equatable {
        
        /// 持久層開啟失敗時的阻斷畫面；`nil` 時才可呈現正常導覽
        @Presents var persistenceFailure: PersistenceFailureFeature.State?
        
        /// 目前選取的主要分頁
        var selectedTab: RootTab = .dashboard
        
        /// 訂單功能狀態
        var orders = OrdersFeature.State()
        
        /// 客戶彙總狀態，隨 orders 同步
        var customers = CustomersFeature.State()
        
        /// 開團功能狀態；``CampaignFeature/State/orders`` 投影經 reducer 的 onChange 與
        var campaigns = CampaignFeature.State()
        
        /// 總覽功能狀態；四份投影皆由 reducer 的變更監看與對應來源保持同步
        var dashboard = DashboardFeature.State()
        
        /// 分析功能狀態與選取的趨勢期間
        var insights = InsightsFeature.State()
        
        /// 匯率工具狀態
        var fx = FxFeature.State()
        
        /// 報價試算狀態
        var quote = QuoteFeature.State()
        
        /// 設定頁狀態
        var settings = SettingsFeature.State()
        
        /// 四種主檔管理狀態，依主檔種類分組
        var lookupManagements: IdentifiedArrayOf<LookupManagementFeature.State> = [
            LookupManagementFeature.State(kind: .orderSource),
            LookupManagementFeature.State(kind: .category),
            LookupManagementFeature.State(kind: .paymentMethod),
            LookupManagementFeature.State(kind: .reconciliationStatus),
        ]
        
        /// 「更多」分頁的導覽路徑
        var morePath: [MoreRoute] = []
        
        // MARK: - Init
        
        /// 依持久層結果與帳本保護設定初始化畫面
        /// - Parameters:
        ///   - persistenceOutcome: 持久層啟動結果
        ///   - isBiometricUnlockEnabled: 啟動當下讀取到的帳本保護設定，預設 `false`
        init(
            persistenceOutcome: PersistenceContainer.Outcome = .healthy,
            isBiometricUnlockEnabled: Bool = false
        ) {
            if case .degraded = persistenceOutcome {
                persistenceFailure = PersistenceFailureFeature.State()
            }
            settings.appLock.isBiometricUnlockEnabled = isBiometricUnlockEnabled
            settings.appLock.isLocked = isBiometricUnlockEnabled
        }
    }
    
    // MARK: - Action
    
    /// App 根層級可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結事件 (分析頁期間、設定深連結開關等純 UI 狀態)
        case binding(BindingAction<State>)
        
        /// App 啟動觸發；目前用來把 ExchangeRate-API `/codes` cache 在 TTL 內更新
        case task
        
        /// 使用者切換主要分頁
        case tabSelected(RootTab)
        
        /// 從非訂單分頁 (如 Dashboard 的 onboarding) 發起「新訂單」流程
        case startNewOrder
        
        /// 使用者從側邊欄智慧分組點擊狀態，跳到訂單頁並套用篩選
        case smartGroupSelected(OrderStatus)
        
        /// 使用者從客戶名單點擊客戶，跳到訂單頁並把搜尋字串設為客戶名
        case customerSelected(String)
        
        /// 使用者從分析頁點擊類別 bar，跳到訂單頁並把搜尋字串設為類別名
        case categorySelected(String)
        
        /// 從總覽或分析頁開啟指定開團詳情
        case campaignSelected(String)
        
        /// 訂單功能事件
        case orders(OrdersFeature.Action)
        
        /// 客戶彙總功能事件
        case customers(CustomersFeature.Action)
        
        /// 開團功能事件
        case campaigns(CampaignFeature.Action)
        
        /// 總覽功能事件
        case dashboard(DashboardFeature.Action)
        
        /// 分析功能事件
        case insights(InsightsFeature.Action)
        
        /// 匯率工具事件
        case fx(FxFeature.Action)
        
        /// 報價試算事件
        case quote(QuoteFeature.Action)
        
        /// 設定頁事件
        case settings(SettingsFeature.Action)
        
        /// 四種主檔管理事件，以主檔種類識別是哪一個畫面送出
        case lookupManagements(IdentifiedActionOf<LookupManagementFeature>)
        
        /// 持久層失敗時的復原流程
        case persistenceFailure(PresentationAction<PersistenceFailureFeature.Action>)
    }
    
    // MARK: - Dependency Properties
    
    /// 跨頁導覽使用的目前時間；測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 跨頁建立訂單時使用的表單識別值
    @Dependency(\.uuid) private var uuid
    
    /// 跨頁篩選訂單時使用的行事曆
    @Dependency(\.calendar) private var calendar
    
    /// 幣別主檔資料來源；App 啟動時打 ExchangeRate-API `/codes` 並 cache 7 天
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository
    
    // MARK: - Reducer Body
    
    /// App 根層級 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        CombineReducers {
            Scope(state: \.orders, action: \.orders) {
                OrdersFeature()
            }
            
            Scope(state: \.customers, action: \.customers) {
                CustomersFeature()
            }
            
            Scope(state: \.campaigns, action: \.campaigns) {
                CampaignFeature()
            }
            
            Scope(state: \.dashboard, action: \.dashboard) {
                DashboardFeature()
            }
            
            Scope(state: \.insights, action: \.insights) {
                InsightsFeature()
            }
            
            Scope(state: \.fx, action: \.fx) {
                FxFeature()
            }
            
            Scope(state: \.quote, action: \.quote) {
                QuoteFeature()
            }
            
            Scope(state: \.settings, action: \.settings) {
                SettingsFeature()
            }
            
            Reduce { state, action in
                switch action {
                case .binding:
                    return .none
                    
                case .task:
                    let currencyMetadataRepository = currencyMetadataRepository
                    return .merge(
                        .concatenate(
                            .send(.settings(.task)),
                            // 先載入設定，再開始生物辨識驗證
                            .send(.settings(.appLock(.appDidBecomeActive)))
                        ),
                        .run { _ in
                            // TTL 7 天：7 * 24 * 3600 = 604_800 秒
                            do {
                                _ = try await currencyMetadataRepository.refreshIfStale(604_800)
                            } catch {
                                // 背景更新失敗不影響已載入的本機資料
                            }
                        }
                    )
                    
                case let .tabSelected(tab):
                    state.selectedTab = tab
                    return .none
                    
                case .startNewOrder:
                    state.selectedTab = .orders
                    state.orders.editOrder = OrderEditFeature.State(
                        id: uuid(), currentDate: date.now)
                    return .none
                    
                case let .smartGroupSelected(status):
                    // 只切換狀態篩選，不覆寫其他篩選條件
                    state.selectedTab = .orders
                    state.orders.selectedStatus = .status(status)
                    state.orders.selectFirstFilteredOrder(
                        referenceDate: date.now, calendar: calendar)
                    return .none
                    
                case let .customerSelected(name):
                    // 先清空更多分頁路徑，再切到訂單頁
                    state.morePath.removeAll()
                    state.selectedTab = .orders
                    state.orders.searchText = name
                    state.orders.selectedStatus = .all
                    state.orders.selectedDatePeriod = .all
                    // 同 smart group：客戶名深連結時清掉殘留類別篩選
                    state.orders.selectedCategory = nil
                    state.orders.selectFirstFilteredOrder(
                        referenceDate: date.now, calendar: calendar)
                    return .none
                    
                case let .categorySelected(category):
                    // 類別 deep link 使用精準 category 篩選，避免 searchText 誤中
                    state.selectedTab = .orders
                    state.orders.searchText = ""
                    state.orders.selectedStatus = .all
                    state.orders.selectedDatePeriod = .all
                    state.orders.selectedCategory = category
                    state.orders.selectFirstFilteredOrder(
                        referenceDate: date.now, calendar: calendar)
                    return .none
                    
                case let .campaignSelected(name):
                    // 從 Dashboard 開團卡或 Insights 開團排行深連結：切到開團頁並選取該團
                    // (CampaignListView 觀察 selectedCampaignID 後 push 詳情)
                    state.selectedTab = .campaigns
                    state.campaigns.selectedCampaignID =
                    state.campaigns.campaigns.first { $0.name == name }?.id
                    return .none
                    
                    // AI 未開啟提示 alert 的「前往開啟」：導覽由 root 負責
                case .orders(.aiDisabledAlert(.presented(.goToAISettings))):
                    // 切到「更多」分頁並 push 設定頁
                    state.selectedTab = .more
                    // 同一次狀態更新內先清空再推入，確保設定頁永遠只有一份且掛在根層
                    state.morePath = [.settings]
                    return .none
                    
                case .orders:
                    return .none
                    
                    // 客戶名單出現時直接轉發訂單載入。
                case .customers(.task):
                    return .send(.orders(.task))
                    
                case let .customers(.delegate(.customerTapped(name))):
                    return .send(.customerSelected(name))
                    
                case .customers:
                    return .none
                    
                case let .campaigns(.delegate(.receiptStatusToggled(id, status))):
                    return .send(.orders(.receiptStatusChanged(id, status)))
                    
                case let .campaigns(.campaignRenamed(from, to)):
                    // DB cascade 已完成，此處同步訂單副本；開團投影由 onChange 集中同步
                    let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedFrom.isEmpty, !trimmedTo.isEmpty, trimmedFrom != trimmedTo {
                        state.orders.orders = state.orders.orders.map { order in
                            guard order.campaignNames.contains(trimmedFrom) else {
                                return order
                            }
                            return order.renamingCampaign(from: trimmedFrom, to: trimmedTo)
                        }
                    }
                    return .none
                    
                case let .campaigns(.campaignDeleted(_, name)):
                    // DB cascade 已完成，此處同步記憶體副本；開團投影由 onChange 集中同步
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        state.orders.orders = state.orders.orders.map { order in
                            guard order.campaignNames.contains(trimmedName) else {
                                return order
                            }
                            return order.removingCampaign(trimmedName)
                        }
                    }
                    return .none
                    
                case .campaigns:
                    // 開團投影改由
                    // onChange(of: \.campaigns.campaigns) 集中同步，此分支不再需要手動觸發
                    return .none
                    
                case .dashboard(.delegate(.refresh)):
                    // 只做轉發、不自帶守衛：去重仍由 OrdersFeature 既有的載入守衛負責
                    // 依序送出兩個 effect。
                    return .concatenate(
                        .send(.orders(.task)),
                        .send(.settings(.task))
                    )
                    
                case let .dashboard(.delegate(.campaignTapped(name))):
                    return .send(.campaignSelected(name))
                    
                case .dashboard(.delegate(.newOrderTapped)):
                    return .send(.startNewOrder)
                    
                case .dashboard(.delegate(.viewAllOrdersTapped)):
                    return .send(.tabSelected(.orders))
                    
                case .dashboard:
                    return .none
                    
                case .insights(.delegate(.refresh)):
                    return .send(.orders(.task))
                    
                case let .insights(.delegate(.campaignTapped(name))):
                    return .send(.campaignSelected(name))
                    
                case let .insights(.delegate(.categoryTapped(name))):
                    return .send(.categorySelected(name))
                    
                case .insights:
                    return .none
                    
                case .fx:
                    return .none
                    
                case .quote:
                    return .none
                    
                case .settings:
                    return .none
                    
                    // 共享目錄已由子 reducer 更新，此處只處理訂單 cascade
                case let .lookupManagements(.element(id: kind, action: .renameRequested(from, to))):
                    cascadeRename(kind: kind, from: from, to: to, in: &state)
                    return .none
                    
                case let .lookupManagements(
                    .element(id: .paymentMethod, action: .paymentMethodEditSucceeded(plan))):
                    // 付款方式主檔已由 LookupManagementFeature 寫入目錄。
                    // 此處只把同一份已正規化 payload 轉送給訂單 reducer 套用到既有訂單列
                    return .send(.orders(.paymentMethodFlagsApplied(plan.affectedOrders)))
                    
                case .lookupManagements:
                    return .none
                    
                case .persistenceFailure:
                    return .none
                }
            }
        }
        .ifLet(\.$persistenceFailure, action: \.persistenceFailure) {
            PersistenceFailureFeature()
        }
        .forEach(\.lookupManagements, action: \.lookupManagements) {
            LookupManagementFeature()
        }
        .onChange(of: \.orders.orders) { _, state in
            // 在此同步所有訂單投影
            state.customers.orders = state.orders.orders
            state.campaigns.orders = state.orders.orders
            state.dashboard.orders = state.orders.orders
            state.insights.orders = state.orders.orders
            return .none
        }
        .onChange(of: \.campaigns.campaigns) { _, state in
            // 在此同步所有開團投影
            state.orders.campaigns = state.campaigns.campaigns
            state.dashboard.campaigns = state.campaigns.campaigns
            state.insights.campaigns = state.campaigns.campaigns
            return .none
        }
        .onChange(of: \.orders.loadState) { _, state in
            // 總覽與分析共用訂單載入狀態投影
            state.dashboard.loadState = state.orders.loadState
            state.insights.loadState = state.orders.loadState
            return .none
        }
        .onChange(of: \.settings.monthlyProfitGoalTwd) { _, state in
            state.dashboard.monthlyProfitGoalTwd = state.settings.monthlyProfitGoalTwd
            return .none
        }
    }
}

// MARK: - Nested Types

extension RootFeature {
    
    /// 「更多」分頁可抵達的目的地
    enum MoreRoute: Hashable, CaseIterable {
        
        // MARK: - Cases
        
        /// 匯率工具
        case fx
        
        /// 客戶名單
        case customers
        
        /// 報價試算
        case quote
        
        /// 訂單來源主檔管理
        case orderSources
        
        /// 商品類別主檔管理
        case categories
        
        /// 付款方式主檔管理
        case paymentMethods
        
        /// 對帳狀態主檔管理
        case reconciliationStatuses
        
        /// 設定
        case settings
    }
}

// MARK: - Private Method

private extension RootFeature {
    
    /// 在 root 端把主檔更名 cascade 到訂單表，讓引用該值的訂單同步更新
    /// - Parameters:
    ///   - kind: 要 cascade 的主檔型別
    ///   - from: 舊名稱
    ///   - to: 新名稱
    ///   - state: 要修改的 ``RootFeature/State``
    func cascadeRename(
        kind: LookupKind,
        from: String,
        to: String,
        in state: inout State
    ) {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty,
              !trimmedTo.isEmpty,
              trimmedFrom != trimmedTo else {
            return
        }
        
        state.orders.orders = state.orders.orders.map { order in
            guard kind.isReferenced(by: order, name: trimmedFrom) else {
                return order
            }
            return kind.renamingReference(in: order, from: trimmedFrom, to: trimmedTo)
        }
    }
}
