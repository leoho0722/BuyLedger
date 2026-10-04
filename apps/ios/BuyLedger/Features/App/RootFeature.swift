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

        /// 啟動時載入、由設定委派更新的完整偏好
        var preferences: SettingsSnapshot

        /// 常駐殼層的鎖定與解鎖狀態
        var appLock: AppLockFeature.State

        /// 訂單功能狀態
        var orders = OrdersFeature.State()

        /// 開團功能狀態；``CampaignFeature/State/orders`` 投影經 reducer 的 `onChange(of:)` 與訂單保持同步
        var campaigns = CampaignFeature.State()

        /// 總覽功能狀態；四份投影皆由 reducer 的變更監看與對應來源保持同步
        var dashboard = DashboardFeature.State()

        /// 分析功能狀態與選取的趨勢期間
        var insights = InsightsFeature.State()

        /// 更多頁的堆疊導覽與子畫面投影
        var more: MoreFeature.State

        /// 依持久層結果與設定狀態初始化畫面
        ///
        /// - Parameters:
        ///   - persistenceStatus: 持久層啟動狀態
        ///   - preferences: 啟動時已載入的完整偏好
        ///   - appVersion: App 版本與建置號顯示文字
        init(
            persistenceStatus: PersistenceContainer.Status = .healthy,
            preferences: SettingsSnapshot = .default,
            appVersion: String = "—"
        ) {
            if case .degraded = persistenceStatus {
                persistenceFailure = PersistenceFailureFeature.State()
            }
            self.preferences = preferences
            appLock = AppLockFeature.State(
                isBiometricUnlockEnabled: preferences.isBiometricUnlockEnabled,
                isLocked: preferences.isBiometricUnlockEnabled
            )
            more = MoreFeature.State(appVersion: appVersion)
            more.preferences = preferences
            dashboard.monthlyProfitGoalTwd = preferences.monthlyProfitGoalTWD
        }
    }

    // MARK: - Action

    /// App 根層級可處理的事件，依送出者與子層分組
    enum Action {

        /// 根導覽宿主送出的畫面事件
        ///
        /// - Parameter action: 啟動或切換導覽的操作
        case view(View)

        /// 持久層失敗時的復原流程
        ///
        /// - Parameter action: 阻斷畫面的呈現或復原事件
        case persistenceFailure(PresentationAction<PersistenceFailureFeature.Action>)

        /// 殼層鎖定與場景生命週期事件
        ///
        /// - Parameter action: 鎖定功能送出的事件
        case appLock(AppLockFeature.Action)

        /// 開團功能事件
        ///
        /// - Parameter action: 開團功能送出的事件
        case campaigns(CampaignFeature.Action)

        /// 總覽功能事件
        ///
        /// - Parameter action: 總覽功能送出的事件
        case dashboard(DashboardFeature.Action)

        /// 分析功能事件
        ///
        /// - Parameter action: 分析功能送出的事件
        case insights(InsightsFeature.Action)

        /// 更多頁堆疊與子畫面委派
        ///
        /// - Parameter action: 更多頁功能送出的事件
        case more(MoreFeature.Action)

        /// 訂單功能事件
        ///
        /// - Parameter action: 訂單功能送出的事件
        case orders(OrdersFeature.Action)

        /// 系統監聽回報重大時間變更
        case significantTimeChanged

        /// 根導覽宿主的使用者操作
        @CasePathable
        enum View: Equatable {

            /// 啟動幣別清單的七天期限刷新與重大時間變更監聽
            case task

            /// iPhone 分頁列切換主要分頁，保留「更多」堆疊
            ///
            /// - Parameter tab: 要切換到的主要分頁
            case tabSelected(RootTab)

            /// iPad 側邊欄切換分頁前先清空「更多」堆疊；選取目前分頁時不處理
            ///
            /// - Parameter tab: 要切換到的主要分頁
            case sidebarTabSelected(RootTab)

            /// 側邊欄智慧分組切到訂單頁並套用狀態篩選
            ///
            /// - Parameter status: 智慧分組對應的訂單狀態
            case smartGroupSelected(OrderStatus)
        }
    }

    // MARK: - Dependencies

    /// 跨頁導覽使用的目前時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 跨頁建立訂單時使用的表單識別值
    @Dependency(\.uuid) private var uuid

    /// 跨頁篩選訂單時使用的行事曆
    @Dependency(\.calendar) private var calendar

    /// 幣別清單的來源；App 啟動時向 ExchangeRate-API 的 `/codes` 下載，保存 7 天
    @Dependency(\.currencyMetadataService) private var currencyMetadataService

    /// 監聽系統重大時間變更，以刷新開團日期標題
    @Dependency(\.significantTimeChangeService) private var significantTimeChangeService

    // MARK: - Body

    /// 組合子層與根邏輯；保留 `CombineReducers`，讓尾端 `onChange` 看到子層變更後再同步投影
    var body: some Reducer<State, Action> {
        CombineReducers {
            Scope(state: \.appLock, action: \.appLock) {
                AppLockFeature()
            }

            Scope(state: \.orders, action: \.orders) {
                OrdersFeature()
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

            Scope(state: \.more, action: \.more) {
                MoreFeature()
            }

            Reduce(core)
                .ifLet(\.$persistenceFailure, action: \.persistenceFailure) {
                    PersistenceFailureFeature()
                }
        }
        .onChange(of: \.orders.orders) { _, state in
            let orders = state.orders.orders
            state.campaigns.$orders.withLock {
                $0 = orders
            }
            state.more.$orders.withLock {
                $0 = orders
            }
            state.dashboard.orders = state.orders.orders
            state.insights.orders = state.orders.orders
            return .none
        }
        .onChange(of: \.campaigns.campaigns) { _, state in
            state.orders.campaigns = state.campaigns.campaigns
            state.dashboard.campaigns = state.campaigns.campaigns
            state.insights.campaigns = state.campaigns.campaigns
            return .none
        }
        .onChange(of: \.orders.loadState) { _, state in
            state.dashboard.loadState = state.orders.loadState
            state.insights.loadState = state.orders.loadState
            return .none
        }
        .onChange(of: \.preferences) { _, state in
            state.appLock.isBiometricUnlockEnabled = state.preferences.isBiometricUnlockEnabled
            state.more.preferences = state.preferences
            state.dashboard.monthlyProfitGoalTwd = state.preferences.monthlyProfitGoalTWD
            return .none
        }
        .onChange(of: \.appLock.biometryType) { _, state in
            state.more.biometryType = state.appLock.biometryType
            return .none
        }
    }
}

// MARK: - Private Method

private extension RootFeature {

    /// 以根功能解析後的時間與行事曆建立共用導覽操作
    var navigation: RootNavigationOperations {
        RootNavigationOperations(referenceDate: date.now, calendar: calendar)
    }

    /// 依收到的事件更新 App 根層狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的根層狀態，直接就地修改
    ///   - action: 這次收到的根層事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task):
            return .merge(
                .run { [currencyMetadataService] _ in
                    // TTL 7 天：7 * 24 * 3600 = 604_800 秒
                    _ = try? await currencyMetadataService.refreshIfStale(604_800)  // 失敗可忽略，本機資料仍可用
                },
                .run { [significantTimeChangeService] send in
                    for await _ in significantTimeChangeService.changes() {
                        await send(.significantTimeChanged)
                    }
                }
            )

        case .view(.tabSelected(let tab)):
            state.selectedTab = tab
            return .none

        case .view(.sidebarTabSelected(let tab)):
            guard tab != state.selectedTab else {
                return .none
            }
            state.more.popToRoot()
            state.selectedTab = tab
            return .none

        case .view(.smartGroupSelected(let status)):
            // 「更多」路徑非空時切分頁會讓 iPad 的 NavigationSplitView 崩潰，先清空
            state.more.popToRoot()
            navigation.showOrders(status: status, state: &state)
            return .none

        case .persistenceFailure:
            return .none

        case .appLock(.delegate(.didBecomeActive)):
            state.campaigns.refreshDateContext(
                CampaignDateContext(now: date.now, calendar: calendar)
            )
            return .none

        case .appLock:
            return .none

        case .campaigns(.delegate(.campaignDeleted(let name))):
            // DB cascade 已完成，此處同步訂單副本；投影由 onChange 集中同步
            RootCascadeOperations.campaignDeleted(name, in: &state.orders.orders)
            return .none

        case .campaigns(.delegate(.campaignRenamed(let from, let to))):
            RootCascadeOperations.campaignRenamed(from: from, to: to, in: &state.orders.orders)
            return .none

        case .campaigns(.delegate(.receiptStatusToggled(let orderID, let status))):
            return .send(.orders(.receiptStatusChanged(orderID, status)))

        case .campaigns:
            return .none

        case .dashboard(.delegate(.refresh)):
            // 只做轉發、不自帶守衛：去重仍由 OrdersFeature 既有的載入守衛負責
            return .send(.orders(.task))

        case .dashboard(.delegate(.campaignTapped(let name))):
            navigation.showCampaign(named: name, state: &state)
            return .none

        case .dashboard(.delegate(.newOrderTapped)):
            // OrdersView 必須先進入畫面階層，才能掛上它持有的新訂單 sheet
            state.selectedTab = .orders
            state.orders.editOrder = OrderEditFeature.State(id: uuid(), currentDate: date.now)
            return .none

        case .dashboard(.delegate(.viewAllOrdersTapped)):
            state.selectedTab = .orders
            return .none

        case .dashboard:
            return .none

        case .insights(.delegate(.refresh)):
            return .send(.orders(.task))

        case .insights(.delegate(.campaignTapped(let name))):
            navigation.showCampaign(named: name, state: &state)
            return .none

        case .insights(.delegate(.categoryTapped(let name))):
            navigation.showOrders(category: name, state: &state)
            return .none

        case .insights:
            return .none

        case .more(.delegate(.ordersLoadRequested)):
            return .send(.orders(.task))

        case .more(.delegate(.customerSelected(let name))):
            navigation.showOrders(customer: name, state: &state)
            return .none

        case .more(.delegate(.lookupItemRenamed(let kind, let rename))):
            RootCascadeOperations.lookupItemRenamed(rename, kind: kind, in: &state.orders.orders)
            return .none

        case .more(.delegate(.paymentMethodEdited(let plan))):
            // 轉送已正規化的訂單，不重算付款方式旗標，也不重複落盤
            return .send(.orders(.paymentMethodFlagsApplied(plan.affectedOrders)))

        case .more(.delegate(.preferencesChanged(let snapshot))):
            state.preferences = snapshot
            return .none

        case .more:
            return .none

        case .orders(.delegate(.aiSettingsRequested)):
            state.selectedTab = .more
            // 同一次狀態更新內先清空再推入，確保設定頁永遠只有一份且掛在根層
            state.more.showSettings()
            return .none

        case .orders:
            return .none

        case .significantTimeChanged:
            state.campaigns.refreshDateContext(
                CampaignDateContext(now: date.now, calendar: calendar)
            )
            return .none
        }
    }
}
