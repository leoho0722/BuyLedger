//
//  OrderFilterFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 整合篩選面板的暫存選擇、搜尋與捨棄確認
@Reducer
struct OrderFilterFeature {

    // MARK: - State

    /// 面板內的選擇與唯讀選項，套用前不修改清單篩選
    @ObservableState
    struct State: Equatable {

        /// 清單共用的唯讀訂單，供整理已使用的選項
        @SharedReader var orders: [LedgerOrder]

        /// 清單共用的唯讀主檔，開啟後仍可反映主檔更新
        @SharedReader var lookupCatalog: LookupCatalog

        /// 清單已套用的三欄篩選，由父層同步
        var committedFilterSelection: OrderFilterSelection

        /// 面板尚未套用的日期、類別與付款方式
        var pendingFilterSelection: OrderFilterSelection

        /// 面板內搜尋類別與付款方式的文字
        var filterSheetSearchText = ""

        /// 有未套用變更時顯示的捨棄確認
        @Presents var filterDiscardConfirmation: AlertState<Action.FilterDiscardAlert>?

        /// 面板是否有尚未套用的變更
        var hasUnappliedFilterChanges: Bool {
            pendingFilterSelection != committedFilterSelection
        }

        /// 主檔與訂單類別依面板搜尋文字取出的名稱
        var filterSheetFilteredCategories: [String] {
            OrdersListQuery.matching(
                OrdersListQuery.availableCategories(orders: orders, catalog: lookupCatalog),
                searchText: filterSheetSearchText
            )
        }

        /// 主檔與訂單付款方式依面板搜尋文字取出的名稱
        var filterSheetFilteredPaymentMethods: [String] {
            OrdersListQuery.filteredPaymentMethods(state: self)
        }

        /// 以清單的共用資料與已套用篩選建立面板，搜尋文字初始為空
        ///
        /// - Parameters:
        ///   - orders: 共用訂單的唯讀引用
        ///   - lookupCatalog: 共用主檔的唯讀引用
        ///   - committedFilterSelection: 清單已套用的篩選
        init(
            orders: SharedReader<[LedgerOrder]>,
            lookupCatalog: SharedReader<LookupCatalog>,
            committedFilterSelection: OrderFilterSelection
        ) {
            self._orders = orders
            self._lookupCatalog = lookupCatalog
            self.committedFilterSelection = committedFilterSelection
            self.pendingFilterSelection = committedFilterSelection
        }
    }

    // MARK: - Action

    /// 面板內的操作、交給清單的結果與捨棄確認事件
    enum Action: BindableAction {

        /// 搜尋欄的雙向繫結
        ///
        /// - Parameter action: 欄位變更
        case binding(BindingAction<State>)

        /// 使用者在面板內的操作
        ///
        /// - Parameter action: 實際互動
        case view(View)

        /// 清單需要提交或關閉的結果
        ///
        /// - Parameter action: 套用選擇或取消
        case delegate(Delegate)

        /// 捨棄確認的呈現事件
        ///
        /// - Parameter action: 捨棄或繼續編輯
        case filterDiscardConfirmation(PresentationAction<FilterDiscardAlert>)

        /// 日期、類別、付款方式與面板按鈕的操作
        @CasePathable
        enum View {

            /// 選擇尚未套用的日期區間
            ///
            /// - Parameter period: 暫存的日期區間
            case filterPendingDatePeriodSelected(OrderDatePeriod)

            /// 選擇尚未套用的商品類別
            ///
            /// - Parameter category: 暫存類別；`nil` 代表全部
            case filterPendingCategorySelected(String?)

            /// 選擇尚未套用的付款方式
            ///
            /// - Parameter paymentMethod: 暫存付款方式；`nil` 代表全部
            case filterPendingPaymentMethodSelected(String?)

            /// 點擊套用，交給清單提交暫存選擇
            case filterApplyTapped

            /// 點擊取消，有變更時先確認捨棄
            case filterCancelTapped
        }

        /// 清單需要處理的篩選結果
        @CasePathable
        enum Delegate: Equatable {

            /// 提交日期、類別與付款方式，狀態與搜尋文字保持原值
            ///
            /// - Parameter selection: 要套用的三欄選擇
            case applied(OrderFilterSelection)

            /// 沒有變更或已確認捨棄，請清單關閉面板
            case cancelled
        }

        /// 捨棄未套用篩選的確認選項
        @CasePathable
        enum FilterDiscardAlert: Equatable {

            /// 確認捨棄變更
            case discard
        }
    }

    // MARK: - Body

    /// 組合搜尋繫結、面板互動與捨棄確認
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce(core)
            .ifLet(\.$filterDiscardConfirmation, action: \.filterDiscardConfirmation)
    }
}

// MARK: - Private Method

private extension OrderFilterFeature {

    /// 更新面板暫存，提交與關閉交給清單處理
    ///
    /// - Parameters:
    ///   - state: 面板目前的狀態
    ///   - action: 使用者操作或委派
    /// - Returns: 清單需要處理的結果，或不需後續動作的效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.filterPendingDatePeriodSelected(let period)):
            OrdersFilterOperations.filterPendingDatePeriodSelected(period, state: &state)
            return .none

        case .view(.filterPendingCategorySelected(let category)):
            OrdersFilterOperations.filterPendingCategorySelected(category, state: &state)
            return .none

        case .view(.filterPendingPaymentMethodSelected(let paymentMethod)):
            OrdersFilterOperations.filterPendingPaymentMethodSelected(paymentMethod, state: &state)
            return .none

        case .view(.filterApplyTapped):
            return .send(.delegate(.applied(state.pendingFilterSelection)))

        case .view(.filterCancelTapped):
            guard let delegate = OrdersFilterOperations.filterCancelTapped(state: &state) else {
                return .none
            }
            return .send(.delegate(delegate))

        case .delegate:
            return .none

        case .filterDiscardConfirmation(.presented(.discard)):
            OrdersFilterOperations.filterDiscardConfirmed(state: &state)
            return .send(.delegate(.cancelled))

        case .filterDiscardConfirmation:
            return .none
        }
    }
}
