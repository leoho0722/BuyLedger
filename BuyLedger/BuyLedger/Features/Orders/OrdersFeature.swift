//
//  OrdersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 訂單列表與詳情選取流程。
@Reducer
struct OrdersFeature {
    
    // MARK: - State
    
    /// 訂單功能狀態。
    @ObservableState
    struct State: Equatable {
        
        /// 目前載入的訂單。
        var orders: [LedgerOrder] = []
        
        /// 搜尋文字。
        var searchText = ""
        
        /// 目前套用的狀態篩選。
        var selectedStatus: OrderStatusFilter = .all
        
        /// 目前套用的日期區間篩選。
        var selectedDatePeriod: OrderDatePeriod = .all
        
        /// 目前選取的訂單編號。
        var selectedOrderID: LedgerOrder.ID?
        
        /// 指示訂單是否正在載入。
        var isLoading = false
        
        /// 是否已完成首次載入。`true` 後再次觸發 ``OrdersFeature/Action/task`` 會直接返回，避免在訂單為空時每次切換 tab 都重設 ``isLoading`` 造成的 UI 閃爍。
        var hasLoaded = false
        
        /// 載入失敗時顯示的錯誤訊息。
        var errorMessage: String?
        
        /// 目前呈現中的編輯／新增表單；`nil` 表示未呈現。
        @Presents var editOrder: OrderEditFeature.State?

        /// 刪除訂單前的確認 alert 狀態；`nil` 表示未呈現。
        ///
        /// 使用 `AlertState` 而非 `ConfirmationDialogState`：iOS 26 起 `.confirmationDialog` 採 anchored popover 樣式，當觸發來源是 toolbar 按鈕而 modifier 又掛在 root view 上時，會出現位置偏移；改用 `.alert` 是 centered modal，跨 iOS 版本與平台都一致。
        @Presents var deletionConfirmation: AlertState<Action.Alert>?
        
        // MARK: - Filter Method

        /// 套用搜尋、狀態與日期區間篩選後的訂單。
        ///
        /// 改成 method 後 caller 必須帶入 `referenceDate`；reducer 用 `@Dependency(\.date)`、view 端則由各自的 `@Dependency(\.date)` 注入。如此可在 snapshot / unit test 中固定「現在」時間，避免跨日跑出不同結果。
        /// - Parameter referenceDate: 計算「本週／本月／上月」等相對區間的基準時間。
        /// - Returns: 過濾後的訂單。
        func filteredOrders(referenceDate: Date) -> [LedgerOrder] {
            let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let calendar = Calendar.current

            return orders.filter { order in
                let matchesStatus = selectedStatus.orderStatus.map { $0 == order.status } ?? true
                let matchesSearch = normalizedQuery.isEmpty || order.searchableText.contains(normalizedQuery)
                let matchesDate = selectedDatePeriod.includes(
                    order.date,
                    referenceDate: referenceDate,
                    calendar: calendar
                )

                return matchesStatus && matchesSearch && matchesDate
            }
        }

        /// 目前選取的訂單。
        /// - Parameter referenceDate: 與 ``filteredOrders(referenceDate:)`` 同一基準。
        /// - Returns: 對應的訂單；若 `selectedOrderID` 已不在當前篩選結果中，回傳第一筆。
        func selectedOrder(referenceDate: Date) -> LedgerOrder? {
            let filtered = filteredOrders(referenceDate: referenceDate)
            guard let selectedOrderID else { return filtered.first }
            return filtered.first { $0.id == selectedOrderID }
        }

        /// 目前訂單清單中所有不重複的商品類別，已過濾空白並依 locale 排序。
        var distinctCategories: [String] {
            let nonEmpty = orders
                .map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Array(Set(nonEmpty))
                .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }
    
    // MARK: - Action
    
    /// 訂單功能可處理的事件。
    @CasePathable
    enum Action: Equatable {
        
        /// 畫面出現時觸發載入。
        case task
        
        /// 訂單載入成功。
        case ordersLoaded([LedgerOrder])
        
        /// 訂單載入失敗。
        case ordersFailed(String)
        
        /// 使用者切換狀態篩選。
        case statusFilterSelected(OrderStatusFilter)
        
        /// 使用者切換日期區間篩選。
        case datePeriodSelected(OrderDatePeriod)
        
        /// 使用者輸入搜尋文字。
        case searchTextChanged(String)
        
        /// 使用者選取訂單。
        case orderSelected(LedgerOrder.ID?)
        
        /// 使用者點擊「編輯」按鈕，要求編輯指定訂單。
        case editOrderTapped(LedgerOrder.ID)
        
        /// 使用者點擊「新訂單」按鈕，要求建立空白訂單。
        case newOrderTapped
        
        /// 編輯／新增表單事件。
        case editOrder(PresentationAction<OrderEditFeature.Action>)
        
        /// 透過詳情頁的「更新狀態」menu 直接切換訂單狀態。
        case statusChanged(LedgerOrder.ID, OrderStatus)

        /// 使用者點擊「刪除」按鈕，要求刪除指定訂單；先以 ``deletionConfirmation`` 二次確認。
        case deleteOrderTapped(LedgerOrder.ID)

        /// 刪除確認 dialog 事件。
        case deletionConfirmation(PresentationAction<Alert>)

        /// 刪除確認 dialog 的選項。
        @CasePathable
        enum Alert: Equatable {

            /// 使用者確認刪除指定訂單。
            case confirmDelete(LedgerOrder.ID)
        }
    }
    
    // MARK: - Dependency Properties
    
    /// 訂單資料來源。
    @Dependency(OrderRepository.self) private var orderRepository
    
    /// 用於新訂單的 UUID 產生器，方便在測試中注入固定值。
    @Dependency(\.uuid) private var uuid
    
    /// 用於新訂單的日期來源，方便在測試中注入固定值。
    @Dependency(\.date) private var date
    
    // MARK: - Reducer Body
    
    /// 訂單功能 reducer。
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                // 首次載入完成後就不再重觸發；否則訂單為空時每次切換 tab 都會把 `isLoading` 翻成 `true`，
                // 讓依賴 `!isLoading` 判斷空狀態的 view 瞬間落入「有資料」分支。
                guard !state.hasLoaded, !state.isLoading else {
                    return .none
                }
                
                let orderRepository = orderRepository
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let orders = try await orderRepository.fetchOrders()
                        await send(.ordersLoaded(orders))
                    } catch {
                        await send(.ordersFailed("訂單載入失敗，請稍後再試。"))
                    }
                }
                
            case let .ordersLoaded(orders):
                state.isLoading = false
                state.hasLoaded = true
                state.orders = orders
                state.selectedOrderID = state.selectedOrderID ?? orders.first?.id
                return .none
                
            case let .ordersFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case let .statusFilterSelected(filter):
                state.selectedStatus = filter
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now).first?.id
                return .none
                
            case let .datePeriodSelected(period):
                state.selectedDatePeriod = period
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now).first?.id
                return .none
                
            case let .searchTextChanged(searchText):
                state.searchText = searchText
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now).first?.id
                return .none
                
            case let .orderSelected(id):
                state.selectedOrderID = id
                return .none
                
            case let .editOrderTapped(id):
                guard let order = state.orders.first(where: { $0.id == id }) else {
                    return .none
                }

                state.editOrder = OrderEditFeature.State(
                    original: order,
                    availableCategories: state.distinctCategories,
                    currentDate: date.now
                )
                return .none

            case .newOrderTapped:
                state.editOrder = OrderEditFeature.State(
                    availableCategories: state.distinctCategories,
                    currentDate: date.now
                )
                return .none
                
            case .editOrder(.presented(.saveTapped)):
                guard let editState = state.editOrder else { return .none }
                guard let savedOrder = applyEditDraft(editState, to: &state) else {
                    return .none
                }
                
                let orderRepository = orderRepository
                return .run { _ in
                    try? await orderRepository.saveOrder(savedOrder)
                }
                
            case .editOrder:
                return .none
                
            case let .statusChanged(orderID, newStatus):
                guard let index = state.orders.firstIndex(where: { $0.id == orderID }) else {
                    return .none
                }
                
                let existing = state.orders[index]
                guard existing.status != newStatus else {
                    return .none
                }
                
                let updated = LedgerOrder(
                    id: existing.id,
                    customer: existing.customer,
                    status: newStatus,
                    currency: existing.currency,
                    date: existing.date,
                    items: existing.items,
                    itemCost: existing.itemCost,
                    domesticShipping: existing.domesticShipping,
                    internationalShipping: existing.internationalShipping,
                    cardFeeRate: existing.cardFeeRate,
                    platformFeeRate: existing.platformFeeRate,
                    chargedAmount: existing.chargedAmount,
                    category: existing.category
                )
                state.orders[index] = updated
                
                let orderRepository = orderRepository
                return .run { _ in
                    try? await orderRepository.saveOrder(updated)
                }

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
                    TextState("「\(order.customer.name)」的訂單 \(order.id) 將被刪除，此操作無法復原。")
                }
                return .none

            case let .deletionConfirmation(.presented(.confirmDelete(id))):
                guard let index = state.orders.firstIndex(where: { $0.id == id }) else {
                    return .none
                }

                state.orders.remove(at: index)

                if state.selectedOrderID == id {
                    state.selectedOrderID = state.filteredOrders(referenceDate: date.now).first?.id
                }

                if state.editOrder?.original?.id == id {
                    state.editOrder = nil
                }

                let orderRepository = orderRepository
                return .run { _ in
                    try? await orderRepository.removeOrder(id)
                }

            case .deletionConfirmation:
                return .none
            }
        }
        .ifLet(\.$editOrder, action: \.editOrder) {
            OrderEditFeature()
        }
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
    }
}

// MARK: - Private Method

private extension OrdersFeature {
    
    /// 將 ``OrderEditFeature`` 的草稿套用到目前訂單清單。
    /// - Parameters:
    ///   - draft: 草稿狀態。
    ///   - state: 將被修改的 ``State``。
    /// - Returns: 套用後的訂單，供呼叫端進一步寫入持久化層；找不到目標訂單時回傳 `nil`。
    @discardableResult
    func applyEditDraft(_ draft: OrderEditFeature.State, to state: inout State) -> LedgerOrder? {
        let trimmedName = draft.draftCustomerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = draft.draftCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let normalizedAmount = max(0, draft.draftChargedAmount)
        let normalizedItemCost = max(0, draft.draftItemCost)
        let normalizedDom = max(0, draft.draftDomesticShipping)
        let normalizedIntl = max(0, draft.draftInternationalShipping)
        let normalizedCardFee = clampRate(draft.draftCardFeeRate)
        let normalizedPlatformFee = clampRate(draft.draftPlatformFeeRate)
        
        if let original = draft.original,
           let index = state.orders.firstIndex(where: { $0.id == original.id }) {
            let existing = state.orders[index]
            let updatedCustomer = LedgerCustomer(
                name: trimmedName.isEmpty ? existing.customer.name : trimmedName,
                initials: existing.customer.initials,
                tier: existing.customer.tier
            )
            
            let updatedOrder = LedgerOrder(
                id: existing.id,
                customer: updatedCustomer,
                status: draft.draftStatus,
                currency: draft.draftCurrency,
                date: draft.draftDate,
                items: draft.draftItems,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDom,
                internationalShipping: normalizedIntl,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                chargedAmount: normalizedAmount,
                category: trimmedCategory.isEmpty ? existing.category : trimmedCategory
            )
            state.orders[index] = updatedOrder
            return updatedOrder
        } else {
            let resolvedName = trimmedName.isEmpty ? "未命名客戶" : trimmedName
            let resolvedCategory = trimmedCategory.isEmpty ? "未分類" : trimmedCategory
            let initials = String(resolvedName.prefix(2)).uppercased()
            let draftID = "BL-DRAFT-\(uuid().uuidString.prefix(6))"
            
            let newOrder = LedgerOrder(
                id: draftID,
                customer: LedgerCustomer(name: resolvedName, initials: initials, tier: .new),
                status: draft.draftStatus,
                currency: draft.draftCurrency,
                date: draft.draftDate,
                items: draft.draftItems,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDom,
                internationalShipping: normalizedIntl,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                chargedAmount: normalizedAmount,
                category: resolvedCategory
            )
            
            state.orders.insert(newOrder, at: 0)
            state.selectedOrderID = draftID
            return newOrder
        }
    }
    
    /// 將手續費比例 clamp 到 `[0, 1]` 區間，避免介面誤輸入造成損益失真。
    /// - Parameter value: 待 clamp 的比例。
    /// - Returns: clamp 後的比例。
    func clampRate(_ value: Decimal) -> Decimal {
        max(0, min(1, value))
    }
}

// MARK: - Private Method

private extension LedgerOrder {
    
    /// 供訂單列表搜尋使用的正規化文字。
    var searchableText: String {
        (
            [
                id,
                customer.name,
                customer.initials,
                category,
                currency.rawValue,
            ] + items.map(\.name)
        )
        .joined(separator: " ")
        .lowercased()
    }
}
