//
//  RootFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// App 根層級狀態與導覽。
@Reducer
struct RootFeature {

    // MARK: - State

    /// App 根層級狀態。
    @ObservableState
    struct State: Equatable {

        /// 目前選取的主要分頁。
        var selectedTab: RootTab = .dashboard

        /// 訂單功能狀態。
        var orders = OrdersFeature.State()

        /// 匯率工具狀態。
        var fx = FxFeature.State()

        /// 報價試算狀態。
        var quote = QuoteFeature.State()

        /// 設定頁狀態。
        var settings = SettingsFeature.State()

        /// 商品類別主檔管理狀態；放在 root 是為了攔截 `renameRequested` 等動作後同步 ``OrdersFeature/State`` 的 in-memory 副本 (cascade)。
        var categoryManagement = LookupManagementFeature.State(kind: .category)

        /// 付款方式主檔管理狀態；理由同 ``categoryManagement``。
        var paymentMethodManagement = LookupManagementFeature.State(kind: .paymentMethod)
    }

    // MARK: - Action

    /// App 根層級可處理的事件。
    @CasePathable
    enum Action: Equatable {

        /// App 啟動觸發；目前用來把 ExchangeRate-API `/codes` cache 在 TTL 內更新。
        case task

        /// 使用者切換主要分頁。
        case tabSelected(RootTab)

        /// 從非訂單分頁 (如 Dashboard 的 onboarding) 發起「新訂單」流程；會同時把 selectedTab 切到 `.orders` 並把 ``OrdersFeature/State/editOrder`` 設好，讓 ``OrdersView`` 的 sheet 能立刻顯示。
        case startNewOrder

        /// 使用者從側邊欄智慧分組點擊狀態，跳到訂單頁並套用篩選。
        case smartGroupSelected(OrderStatus)

        /// 使用者從客戶名單點擊客戶，跳到訂單頁並把搜尋字串設為客戶名。
        case customerSelected(String)

        /// 使用者從分析頁點擊類別 bar，跳到訂單頁並把搜尋字串設為類別名。
        case categorySelected(String)

        /// 訂單功能事件。
        case orders(OrdersFeature.Action)

        /// 匯率工具事件。
        case fx(FxFeature.Action)

        /// 報價試算事件。
        case quote(QuoteFeature.Action)

        /// 設定頁事件。
        case settings(SettingsFeature.Action)

        /// 商品類別主檔管理事件。
        case categoryManagement(LookupManagementFeature.Action)

        /// 付款方式主檔管理事件。
        case paymentMethodManagement(LookupManagementFeature.Action)
    }

    // MARK: - Dependency Properties

    /// 用來計算跨頁跳轉時的「目前」時間 (套用到 ``OrdersFeature/State/filteredOrders(referenceDate:)``)；測試可注入固定值。
    @Dependency(\.date) private var date

    /// 幣別主檔資料來源；App 啟動時打 ExchangeRate-API `/codes` 並 cache 7 天。
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Reducer Body

    /// App 根層級 reducer。
    var body: some Reducer<State, Action> {
        Scope(state: \.orders, action: \.orders) {
            OrdersFeature()
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

        Scope(state: \.categoryManagement, action: \.categoryManagement) {
            LookupManagementFeature()
        }

        Scope(state: \.paymentMethodManagement, action: \.paymentMethodManagement) {
            LookupManagementFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                let currencyMetadataRepository = currencyMetadataRepository
                return .run { _ in
                    // TTL 7 天：7 * 24 * 3600 = 604_800 秒。
                    _ = try? await currencyMetadataRepository.refreshIfStale(604_800)
                }

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .startNewOrder:
                state.selectedTab = .orders
                state.orders.editOrder = OrderEditFeature.State()
                return .none

            case let .smartGroupSelected(status):
                state.selectedTab = .orders
                state.orders.selectedStatus = .status(status)
                state.orders.selectedDatePeriod = .all
                state.orders.selectedOrderID = state.orders.filteredOrders(referenceDate: date.now).first?.id
                return .none

            case let .customerSelected(name):
                state.selectedTab = .orders
                state.orders.searchText = name
                state.orders.selectedStatus = .all
                state.orders.selectedDatePeriod = .all
                state.orders.selectedOrderID = state.orders.filteredOrders(referenceDate: date.now).first?.id
                return .none

            case let .categorySelected(category):
                state.selectedTab = .orders
                state.orders.searchText = category
                state.orders.selectedStatus = .all
                state.orders.selectedDatePeriod = .all
                state.orders.selectedOrderID = state.orders.filteredOrders(referenceDate: date.now).first?.id
                return .none

            case .orders:
                return .none

            case .fx:
                return .none

            case .quote:
                return .none

            case .settings:
                return .none

            case let .categoryManagement(.renameRequested(from, to)):
                cascadeRename(kind: .category, from: from, to: to, in: &state)
                return .none

            case let .categoryManagement(.addConfirmed(name, _)):
                // 商品類別無 isCardless 概念，直接忽略第二個參數。
                addCategoryToOrdersMaster(name: name, in: &state)
                return .none

            case let .categoryManagement(.deleteRequested(name)):
                removeFromOrdersMaster(kind: .category, name: name, in: &state)
                return .none

            case .categoryManagement:
                return .none

            case let .paymentMethodManagement(.renameRequested(from, to)):
                cascadeRename(kind: .paymentMethod, from: from, to: to, in: &state)
                return .none

            case let .paymentMethodManagement(.addConfirmed(name, isCardless)):
                addPaymentMethodToOrdersMaster(name: name, isCardless: isCardless, in: &state)
                return .none

            case let .paymentMethodManagement(.deleteRequested(name)):
                removeFromOrdersMaster(kind: .paymentMethod, name: name, in: &state)
                return .none

            case .paymentMethodManagement:
                return .none
            }
        }
    }

    // MARK: - Private Method

    /// 在 root 端 cascade 主檔更名到 ``OrdersFeature/State`` 的 in-memory 副本，避免 LookupManagement 只更新 DB 但 OrdersFeature 拿到的還是舊字串。
    /// - Parameters:
    ///   - kind: 要 cascade 的主檔型別。
    ///   - from: 舊名稱。
    ///   - to: 新名稱。
    ///   - state: 要修改的 ``RootFeature/State``。
    private func cascadeRename(
        kind: LookupKind,
        from: String,
        to: String,
        in state: inout State
    ) {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty, !trimmedTo.isEmpty, trimmedFrom != trimmedTo else { return }

        switch kind {
        case .category:
            state.orders.categoryMaster = renameInList(
                state.orders.categoryMaster,
                from: trimmedFrom,
                to: trimmedTo
            )
            state.orders.orders = state.orders.orders.map { order in
                guard order.category == trimmedFrom else { return order }
                return rebuildOrder(order, category: trimmedTo)
            }

        case .paymentMethod:
            state.orders.paymentMethodMaster = renamePaymentMethods(
                state.orders.paymentMethodMaster,
                from: trimmedFrom,
                to: trimmedTo
            )
            state.orders.orders = state.orders.orders.map { order in
                guard order.paymentMethod == trimmedFrom else { return order }
                return rebuildOrder(order, paymentMethod: trimmedTo)
            }
        }
    }

    /// 把 ``LookupManagementFeature`` 新增的商品類別加進 ``OrdersFeature/State/categoryMaster`` 副本。
    /// - Parameters:
    ///   - name: 新增名稱。
    ///   - state: 要修改的 ``RootFeature/State``。
    private func addCategoryToOrdersMaster(
        name: String,
        in state: inout State
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !state.orders.categoryMaster.contains(trimmed) else { return }

        var updated = state.orders.categoryMaster
        updated.append(trimmed)
        state.orders.categoryMaster = updated.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    /// 把 ``LookupManagementFeature`` 新增的付款方式 (含 `isCardless`) 加進 ``OrdersFeature/State/paymentMethodMaster`` 副本；若名稱已存在則僅更新旗標。
    /// - Parameters:
    ///   - name: 新增名稱。
    ///   - isCardless: 是否屬於無卡類付款方式。
    ///   - state: 要修改的 ``RootFeature/State``。
    private func addPaymentMethodToOrdersMaster(
        name: String,
        isCardless: Bool,
        in state: inout State
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = state.orders.paymentMethodMaster
        if let index = updated.firstIndex(where: { $0.name == trimmed }) {
            updated[index] = PaymentMethodInfo(name: trimmed, isCardless: isCardless)
        } else {
            updated.append(PaymentMethodInfo(name: trimmed, isCardless: isCardless))
        }
        state.orders.paymentMethodMaster = updated.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// 把 ``LookupManagementFeature`` 刪除的項目從 ``OrdersFeature/State`` 的 master 副本中移除。
    /// - Parameters:
    ///   - kind: 主檔型別。
    ///   - name: 要移除的名稱。
    ///   - state: 要修改的 ``RootFeature/State``。
    private func removeFromOrdersMaster(
        kind: LookupKind,
        name: String,
        in state: inout State
    ) {
        switch kind {
        case .category:
            state.orders.categoryMaster.removeAll { $0 == name }
        case .paymentMethod:
            state.orders.paymentMethodMaster.removeAll { $0.name == name }
        }
    }

    /// 把 [PaymentMethodInfo] 中名稱為 `oldName` 的項目改名為 `newName`，保留原有 `isCardless`；若 `newName` 已存在則合併 (任一邊曾標記無卡的就視為無卡)。
    /// - Parameters:
    ///   - list: 原始陣列。
    ///   - oldName: 舊名稱。
    ///   - newName: 新名稱。
    /// - Returns: 重新命名後的排序陣列。
    private func renamePaymentMethods(
        _ list: [PaymentMethodInfo],
        from oldName: String,
        to newName: String
    ) -> [PaymentMethodInfo] {
        var byName: [String: PaymentMethodInfo] = [:]
        for info in list {
            if info.name == oldName {
                let merged = byName[newName]
                let isCardless = info.isCardless || (merged?.isCardless ?? false)
                byName[newName] = PaymentMethodInfo(name: newName, isCardless: isCardless)
            } else {
                let merged = byName[info.name]
                let isCardless = info.isCardless || (merged?.isCardless ?? false)
                byName[info.name] = PaymentMethodInfo(name: info.name, isCardless: isCardless)
            }
        }
        return byName.values
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// 把 list 中等於 `oldName` 的項目替換成 `newName`，去重後依 locale 排序。
    /// - Parameters:
    ///   - list: 原始陣列。
    ///   - oldName: 舊名稱。
    ///   - newName: 新名稱。
    /// - Returns: 重新命名後的排序陣列。
    private func renameInList(
        _ list: [String],
        from oldName: String,
        to newName: String
    ) -> [String] {
        let replaced = list.map { $0 == oldName ? newName : $0 }
        return Array(Set(replaced))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// 因為 ``LedgerOrder`` 是 immutable struct，更新 category 或 paymentMethod 必須以 memberwise init 重建。
    /// - Parameters:
    ///   - order: 原本的訂單。
    ///   - category: 若不為 `nil` 則覆寫 category。
    ///   - paymentMethod: 若不為 `nil` 則覆寫 paymentMethod。
    /// - Returns: 重建後的訂單。
    private func rebuildOrder(
        _ order: LedgerOrder,
        category: String? = nil,
        paymentMethod: String? = nil
    ) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            category: category ?? order.category,
            paymentMethod: paymentMethod ?? order.paymentMethod
        )
    }
}
