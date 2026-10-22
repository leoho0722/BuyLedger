//
//  OrderCategoryPickerFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture

/// iPad 類別選擇器的暫存多選、搜尋與捨棄確認
@Reducer
struct OrderCategoryPickerFeature {

    // MARK: - State

    /// 完成前不提交類別，資料選項沿用清單的唯讀引用
    @ObservableState
    struct State: Equatable {

        /// 共用訂單的唯讀引用
        @SharedReader var orders: [LedgerOrder]

        /// Root 同步的共用開團唯讀引用
        @SharedReader var campaigns: [Campaign]

        /// 共用主檔的唯讀引用
        @SharedReader var lookupCatalog: LookupCatalog

        /// 清單目前已套用的類別比較基準
        var committedCategories: Set<String>

        /// 選擇器尚未套用的類別集合
        var pendingCategories: Set<String>

        /// 開啟或刷新時由清單提供的日期脈絡
        var dateContext: OrderDateContext

        /// 只過濾類別選項的搜尋文字
        var searchText = ""

        /// 搜尋欄是否持有焦點
        var isSearchFieldFocused = false

        /// 開啟時計算的展開狀態，後續由使用者操作更新
        var groupExpansion: OrderCategoryGroups.Expansion

        /// 未套用變更的捨棄確認
        @Presents var discardConfirmation: AlertState<Action.DiscardAlert>?

        /// 暫存類別與目前已套用集合是否不同
        var hasUnappliedChanges: Bool {
            pendingCategories != committedCategories
        }

        /// 依最新共用資料、暫存選取與搜尋文字計算的分組
        var categoryGroups: [OrderCategoryGroups.Display] {
            let groups = OrderCategoryGroups.groups(
                orders: orders,
                campaigns: campaigns,
                catalog: lookupCatalog,
                context: dateContext
            )
            return OrderCategoryGroups.displayGroups(
                groups: groups,
                expansion: groupExpansion,
                selected: pendingCategories,
                searchText: searchText
            )
        }

        /// 建立選擇器資料引用與暫存類別
        ///
        /// - Parameters:
        ///   - orders: 清單的共用訂單唯讀引用
        ///   - campaigns: 清單的共用開團唯讀引用
        ///   - lookupCatalog: 清單的共用主檔唯讀引用
        ///   - committedCategories: 已套用類別集合
        ///   - dateContext: 清單記錄的日期脈絡
        init(
            orders: SharedReader<[LedgerOrder]>,
            campaigns: SharedReader<[Campaign]>,
            lookupCatalog: SharedReader<LookupCatalog>,
            committedCategories: Set<String>,
            dateContext: OrderDateContext
        ) {
            self._orders = orders
            self._campaigns = campaigns
            self._lookupCatalog = lookupCatalog
            self.committedCategories = committedCategories
            self.pendingCategories = committedCategories
            self.dateContext = dateContext
            let groups = OrderCategoryGroups.groups(
                orders: orders.wrappedValue,
                campaigns: campaigns.wrappedValue,
                catalog: lookupCatalog.wrappedValue,
                context: dateContext
            )
            self.groupExpansion = OrderCategoryGroups.initialExpansion(
                groups: groups,
                selected: committedCategories
            )
        }
    }

    // MARK: - Action

    /// 選擇器的繫結、畫面操作、委派與確認事件
    enum Action: BindableAction {

        /// 搜尋與焦點欄位的雙向繫結
        ///
        /// - Parameter action: 欄位變更
        case binding(BindingAction<State>)

        /// 選擇器畫面的互動
        ///
        /// - Parameter action: 使用者操作
        case view(View)

        /// 交由清單提交或取消的結果
        ///
        /// - Parameter action: 已確認的結果
        case delegate(Delegate)

        /// 捨棄確認的呈現與操作
        ///
        /// - Parameter action: 確認捨棄或繼續編輯
        case discardConfirmation(PresentationAction<DiscardAlert>)

        /// 暫存類別、搜尋與工具列操作
        @CasePathable
        enum View {

            /// 切換單一類別的成員資格
            ///
            /// - Parameter category: 要加入或移除的類別
            case categoryToggled(String)

            /// 清空暫存類別集合
            case allTapped

            /// 切換組標題的展開，搜尋中不改儲存值
            ///
            /// - Parameter kind: 組別種類
            case groupToggled(OrderCategoryGroups.Kind)

            /// return 清除焦點並保留搜尋文字
            case searchSubmitted

            /// 清空搜尋文字並保留選取與焦點
            case searchClearTapped

            /// 將暫存集合交給清單提交
            case doneTapped

            /// 取消，有變更時先確認捨棄
            case cancelTapped
        }

        /// 清單需要處理的選擇器結果
        @CasePathable
        enum Delegate: Equatable {

            /// 提交完整暫存類別集合
            ///
            /// - Parameter categories: 要套用的類別集合
            case applied(Set<String>)

            /// 沒有變更或已確認捨棄，請清單關閉選擇器
            case cancelled
        }

        /// 捨棄未套用類別的確認選項
        @CasePathable
        enum DiscardAlert: Equatable {

            /// 確認捨棄未套用的類別
            case discard
        }
    }

    // MARK: - Body

    /// 組合搜尋繫結、選擇器互動與捨棄確認
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce(core)
            .ifLet(\.$discardConfirmation, action: \.discardConfirmation)
    }
}

// MARK: - Private Method

private extension OrderCategoryPickerFeature {

    /// 更新暫存類別，提交與關閉交給清單處理
    ///
    /// - Parameters:
    ///   - state: 目前選擇器狀態
    ///   - action: 繫結、互動或委派事件
    /// - Returns: 清單需要處理的結果，或不需後續動作的效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.categoryToggled(let category)):
            state.pendingCategories = OrderCategoryGroups.toggled(
                category,
                in: state.pendingCategories
            )
            return .none

        case .view(.allTapped):
            state.pendingCategories = []
            return .none

        case .view(.groupToggled(let kind)):
            guard !OrderCategoryGroups.isSearching(state.searchText) else {
                return .none
            }
            state.groupExpansion.toggle(kind)
            return .none

        case .view(.searchSubmitted):
            state.isSearchFieldFocused = false
            return .none

        case .view(.searchClearTapped):
            state.searchText = ""
            return .none

        case .view(.doneTapped):
            return .send(.delegate(.applied(state.pendingCategories)))

        case .view(.cancelTapped):
            guard state.hasUnappliedChanges else {
                return .send(.delegate(.cancelled))
            }
            state.discardConfirmation = OrderFilterConfirmations.discardChanges(discard: .discard)
            return .none

        case .delegate:
            return .none

        case .discardConfirmation(.presented(.discard)):
            state.pendingCategories = state.committedCategories
            return .send(.delegate(.cancelled))

        case .discardConfirmation:
            return .none
        }
    }
}
