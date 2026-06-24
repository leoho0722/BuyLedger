//
//  RootFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// App 根層級狀態與導覽
@Reducer
struct RootFeature {

    // MARK: - State

    /// App 根層級狀態
    @ObservableState
    struct State: Equatable {

        /// 目前選取的主要分頁
        var selectedTab: RootTab = .dashboard

        /// 訂單功能狀態
        var orders = OrdersFeature.State()

        /// 開團功能狀態
        var campaigns = CampaignFeature.State()

        /// 匯率工具狀態
        var fx = FxFeature.State()

        /// 報價試算狀態
        var quote = QuoteFeature.State()

        /// 設定頁狀態
        var settings = SettingsFeature.State()

        /// 訂單來源主檔管理狀態；理由同 ``categoryManagement``
        var orderSourceManagement = LookupManagementFeature.State(kind: .orderSource)

        /// 商品類別主檔管理狀態；放在 root 是為了攔截 `renameRequested` 等動作後同步 ``OrdersFeature/State`` 的 in-memory 副本 (cascade)
        var categoryManagement = LookupManagementFeature.State(kind: .category)

        /// 付款方式主檔管理狀態；理由同 ``categoryManagement``
        var paymentMethodManagement = LookupManagementFeature.State(kind: .paymentMethod)

        /// 對帳狀態主檔管理狀態；理由同 ``categoryManagement``
        var verificationStatusManagement = LookupManagementFeature.State(kind: .verificationStatus)

        /// 設為 `true` 時，「更多」分頁的 NavigationStack 會 push 到設定頁；供 AI 提示 alert 深連結開啟設定用 (iOS/iPadOS)
        var showsSettingsFromDeepLink = false
    }

    // MARK: - Action

    /// App 根層級可處理的事件
    @CasePathable
    enum Action: Equatable {

        /// App 啟動觸發；目前用來把 ExchangeRate-API `/codes` cache 在 TTL 內更新
        case task

        /// 使用者切換主要分頁
        case tabSelected(RootTab)

        /// 設定「更多」分頁是否 push 到設定頁 (deep-link 開關，供 MoreView 的 navigationDestination 雙向繫結)
        case setShowsSettingsFromDeepLink(Bool)

        /// 從非訂單分頁 (如 Dashboard 的 onboarding) 發起「新訂單」流程；會同時把 selectedTab 切到 `.orders` 並把 ``OrdersFeature/State/editOrder`` 設好，讓 ``OrdersView`` 的 sheet 能立刻顯示
        case startNewOrder

        /// 使用者從側邊欄智慧分組點擊狀態，跳到訂單頁並套用篩選
        case smartGroupSelected(OrderStatus)

        /// 使用者從客戶名單點擊客戶，跳到訂單頁並把搜尋字串設為客戶名
        case customerSelected(String)

        /// 使用者從分析頁點擊類別 bar，跳到訂單頁並把搜尋字串設為類別名
        case categorySelected(String)

        /// 使用者從 Dashboard 開團卡或 Insights 開團排行點擊某個開團，跳到開團頁並開啟該團詳情
        case campaignSelected(String)

        /// 訂單功能事件
        case orders(OrdersFeature.Action)

        /// 開團功能事件
        case campaigns(CampaignFeature.Action)

        /// 匯率工具事件
        case fx(FxFeature.Action)

        /// 報價試算事件
        case quote(QuoteFeature.Action)

        /// 設定頁事件
        case settings(SettingsFeature.Action)

        /// 訂單來源主檔管理事件
        case orderSourceManagement(LookupManagementFeature.Action)

        /// 商品類別主檔管理事件
        case categoryManagement(LookupManagementFeature.Action)

        /// 付款方式主檔管理事件
        case paymentMethodManagement(LookupManagementFeature.Action)

        /// 對帳狀態主檔管理事件
        case verificationStatusManagement(LookupManagementFeature.Action)
    }

    // MARK: - Dependency Properties

    /// 用來計算跨頁跳轉時的「目前」時間 (套用到 ``OrdersFeature/State/filteredOrders(referenceDate:calendar:)``)；測試可注入固定值
    @Dependency(\.date) private var date

    /// 跨頁跳轉重算選取訂單時，訂單篩選所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar

    /// 幣別主檔資料來源；App 啟動時打 ExchangeRate-API `/codes` 並 cache 7 天
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Reducer Body

    /// App 根層級 reducer
    var body: some Reducer<State, Action> {
        Scope(state: \.orders, action: \.orders) {
            OrdersFeature()
        }

        Scope(state: \.campaigns, action: \.campaigns) {
            CampaignFeature()
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

        Scope(state: \.orderSourceManagement, action: \.orderSourceManagement) {
            LookupManagementFeature()
        }

        Scope(state: \.categoryManagement, action: \.categoryManagement) {
            LookupManagementFeature()
        }

        Scope(state: \.paymentMethodManagement, action: \.paymentMethodManagement) {
            LookupManagementFeature()
        }

        Scope(state: \.verificationStatusManagement, action: \.verificationStatusManagement) {
            LookupManagementFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                let currencyMetadataRepository = currencyMetadataRepository
                return .run { _ in
                    // TTL 7 天：7 * 24 * 3600 = 604_800 秒
                    _ = try? await currencyMetadataRepository.refreshIfStale(604_800)
                }

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case let .setShowsSettingsFromDeepLink(value):
                state.showsSettingsFromDeepLink = value
                return .none

            case .startNewOrder:
                state.selectedTab = .orders
                state.orders.editOrder = OrderEditFeature.State(currentDate: date.now)
                return .none

            case let .smartGroupSelected(status):
                state.selectedTab = .orders
                state.orders.selectedStatus = .status(status)
                state.orders.selectedDatePeriod = .all
                // 清掉殘留類別篩選，避免使用者帶著前一頁的類別狀態跳到 smart group 後被「狀態 + 類別」夾擊出空列表
                state.orders.selectedCategory = nil
                state.orders.selectedOrderID = state.orders.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .customerSelected(name):
                state.selectedTab = .orders
                state.orders.searchText = name
                state.orders.selectedStatus = .all
                state.orders.selectedDatePeriod = .all
                // 同 smart group：客戶名深連結時清掉殘留類別篩選
                state.orders.selectedCategory = nil
                state.orders.selectedOrderID = state.orders.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .categorySelected(category):
                // 從分析頁類別排行深連結進訂單頁時，以 `selectedCategory` 精準欄位比對而非 `searchText` 模糊比對：
                // 後者會把品名/客戶名等含相同字串的訂單誤包進來，也讓訂單頁的類別篩選膠囊無法 highlight
                state.selectedTab = .orders
                state.orders.searchText = ""
                state.orders.selectedStatus = .all
                state.orders.selectedDatePeriod = .all
                state.orders.selectedCategory = category
                state.orders.selectedOrderID = state.orders.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .campaignSelected(name):
                // 從 Dashboard 開團卡或 Insights 開團排行深連結：切到開團頁並選取該團 (CampaignListView 觀察 selectedCampaignID 後 push 詳情)
                state.selectedTab = .campaigns
                state.campaigns.selectedCampaignID = state.campaigns.campaigns.first { $0.name == name }?.id
                return .none

            // AI 未開啟提示 alert 的「前往開啟」：導覽由 root 負責
            case .orders(.aiDisabledAlert(.presented(.goToAISettings))):
                #if os(macOS)
                // macOS：開啟標準偏好設定視窗 (⌘,)，AI 開關位於 SettingsMacView
                return .run { _ in
                    await MainActor.run {
                        _ = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }
                #else
                // iOS / iPadOS：切到「更多」分頁並 push 設定頁
                state.selectedTab = .more
                state.showsSettingsFromDeepLink = true
                return .none
                #endif

            case .orders:
                return .none

            case let .campaigns(.campaignRenamed(from, to)):
                // CampaignFeature 已處理開團主檔與訂單表 (DB) 的 cascade；此處只同步 OrdersFeature 的 in-memory 副本
                let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedFrom.isEmpty, !trimmedTo.isEmpty, trimmedFrom != trimmedTo {
                    state.orders.orders = state.orders.orders.map { order in
                        guard order.campaignNames.contains(trimmedFrom) else { return order }
                        return rebuildOrder(
                            order,
                            campaignNames: order.campaignNames.map { $0 == trimmedFrom ? trimmedTo : $0 }
                        )
                    }
                }
                state.orders.campaigns = state.campaigns.campaigns
                return .none

            case .campaigns:
                // 任何開團變更 (載入／自動轉狀態／新增／狀態／結團／刪除) 後，同步 OrdersFeature 的開團副本，
                // 供訂單編輯選團與訂單列表按開團狀態篩選使用
                state.orders.campaigns = state.campaigns.campaigns
                return .none

            case .fx:
                return .none

            case .quote:
                return .none

            case .settings:
                return .none

            case let .orderSourceManagement(.renameRequested(from, to)):
                cascadeRename(kind: .orderSource, from: from, to: to, in: &state)
                return .none

            case let .orderSourceManagement(.addConfirmed(name, _, _, _)):
                // 訂單來源無 isCardless / isBankTransfer / isCashOnDelivery 概念，直接忽略後三個參數
                addOrderSourceToOrdersMaster(name: name, in: &state)
                return .none

            case let .orderSourceManagement(.deleteRequested(name)):
                removeFromOrdersMaster(kind: .orderSource, name: name, in: &state)
                return .none

            case .orderSourceManagement:
                return .none

            case let .categoryManagement(.renameRequested(from, to)):
                cascadeRename(kind: .category, from: from, to: to, in: &state)
                return .none

            case let .categoryManagement(.addConfirmed(name, _, _, _)):
                // 商品類別無 isCardless / isBankTransfer / isCashOnDelivery 概念，直接忽略後三個參數
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

            case let .paymentMethodManagement(.addConfirmed(name, isCardless, isBankTransfer, isCashOnDelivery)):
                addPaymentMethodToOrdersMaster(name: name, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery, in: &state)
                return .none

            case let .paymentMethodManagement(.deleteRequested(name)):
                removeFromOrdersMaster(kind: .paymentMethod, name: name, in: &state)
                return .none

            case let .paymentMethodManagement(.editConfirmed(originalName, name, isCardless, isBankTransfer, isCashOnDelivery)):
                let trimmedOriginal = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedNew = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty else { return .none }
                // 名稱變更先 cascade 到 in-memory master 與訂單表 (rename 會合併舊旗標)，
                // 再以使用者實際勾選權威覆寫旗標，確保可取消勾選
                if trimmedNew != trimmedOriginal {
                    cascadeRename(kind: .paymentMethod, from: trimmedOriginal, to: trimmedNew, in: &state)
                }
                addPaymentMethodToOrdersMaster(name: trimmedNew, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery, in: &state)
                return .none

            case .paymentMethodManagement:
                return .none

            case let .verificationStatusManagement(.renameRequested(from, to)):
                cascadeRename(kind: .verificationStatus, from: from, to: to, in: &state)
                return .none

            case let .verificationStatusManagement(.addConfirmed(name, _, _, _)):
                // 對帳狀態無 isCardless / isBankTransfer / isCashOnDelivery 概念，直接忽略後三個參數
                addVerificationStatusToOrdersMaster(name: name, in: &state)
                return .none

            case let .verificationStatusManagement(.deleteRequested(name)):
                removeFromOrdersMaster(kind: .verificationStatus, name: name, in: &state)
                return .none

            case .verificationStatusManagement:
                return .none
            }
        }
    }

    // MARK: - Private Method

    /// 在 root 端 cascade 主檔更名到 ``OrdersFeature/State`` 的 in-memory 副本，避免 LookupManagement 只更新 DB 但 OrdersFeature 拿到的還是舊字串
    /// - Parameters:
    ///   - kind: 要 cascade 的主檔型別
    ///   - from: 舊名稱
    ///   - to: 新名稱
    ///   - state: 要修改的 ``RootFeature/State``
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
        case .orderSource:
            state.orders.orderSourceMaster = renameInList(
                state.orders.orderSourceMaster,
                from: trimmedFrom,
                to: trimmedTo
            )
            state.orders.orders = state.orders.orders.map { order in
                guard order.orderSource == trimmedFrom else { return order }
                return rebuildOrder(order, orderSource: trimmedTo)
            }

        case .category:
            state.orders.categoryMaster = renameInList(
                state.orders.categoryMaster,
                from: trimmedFrom,
                to: trimmedTo
            )
            state.orders.orders = state.orders.orders.map { order in
                guard order.categories.contains(trimmedFrom) else { return order }
                return rebuildOrder(
                    order,
                    categories: order.categories.map { $0 == trimmedFrom ? trimmedTo : $0 }
                )
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

        case .verificationStatus:
            state.orders.verificationStatusMaster = renameInList(
                state.orders.verificationStatusMaster,
                from: trimmedFrom,
                to: trimmedTo
            )
            state.orders.orders = state.orders.orders.map { order in
                guard order.verificationStatus == trimmedFrom else { return order }
                return rebuildOrder(order, verificationStatus: trimmedTo)
            }
        }
    }

    /// 把 ``LookupManagementFeature`` 新增的訂單來源加進 ``OrdersFeature/State/orderSourceMaster`` 副本
    /// - Parameters:
    ///   - name: 新增名稱
    ///   - state: 要修改的 ``RootFeature/State``
    private func addOrderSourceToOrdersMaster(
        name: String,
        in state: inout State
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !state.orders.orderSourceMaster.contains(trimmed) else { return }

        var updated = state.orders.orderSourceMaster
        updated.append(trimmed)
        state.orders.orderSourceMaster = updated.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    /// 把 ``LookupManagementFeature`` 新增的商品類別加進 ``OrdersFeature/State/categoryMaster`` 副本
    /// - Parameters:
    ///   - name: 新增名稱
    ///   - state: 要修改的 ``RootFeature/State``
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

    /// 把 ``LookupManagementFeature`` 新增的付款方式 (含 `isCardless`、`isBankTransfer` 與 `isCashOnDelivery`) 加進 ``OrdersFeature/State/paymentMethodMaster`` 副本；若名稱已存在則僅更新旗標
    /// - Parameters:
    ///   - name: 新增名稱
    ///   - isCardless: 是否屬於無卡類付款方式
    ///   - isBankTransfer: 是否屬於銀行匯款類付款方式
    ///   - isCashOnDelivery: 是否屬於貨到付款類付款方式
    ///   - state: 要修改的 ``RootFeature/State``
    private func addPaymentMethodToOrdersMaster(
        name: String,
        isCardless: Bool,
        isBankTransfer: Bool,
        isCashOnDelivery: Bool,
        in state: inout State
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = state.orders.paymentMethodMaster
        if let index = updated.firstIndex(where: { $0.name == trimmed }) {
            updated[index] = PaymentMethodInfo(name: trimmed, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery)
        } else {
            updated.append(PaymentMethodInfo(name: trimmed, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery))
        }
        state.orders.paymentMethodMaster = updated.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// 把 ``LookupManagementFeature`` 新增的對帳狀態加進 ``OrdersFeature/State/verificationStatusMaster`` 副本
    /// - Parameters:
    ///   - name: 新增名稱
    ///   - state: 要修改的 ``RootFeature/State``
    private func addVerificationStatusToOrdersMaster(
        name: String,
        in state: inout State
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !state.orders.verificationStatusMaster.contains(trimmed) else { return }

        var updated = state.orders.verificationStatusMaster
        updated.append(trimmed)
        state.orders.verificationStatusMaster = updated.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    /// 把 ``LookupManagementFeature`` 刪除的項目從 ``OrdersFeature/State`` 的 master 副本中移除
    /// - Parameters:
    ///   - kind: 主檔型別
    ///   - name: 要移除的名稱
    ///   - state: 要修改的 ``RootFeature/State``
    private func removeFromOrdersMaster(
        kind: LookupKind,
        name: String,
        in state: inout State
    ) {
        switch kind {
        case .orderSource:
            state.orders.orderSourceMaster.removeAll { $0 == name }
        case .category:
            state.orders.categoryMaster.removeAll { $0 == name }
        case .paymentMethod:
            state.orders.paymentMethodMaster.removeAll { $0.name == name }
        case .verificationStatus:
            state.orders.verificationStatusMaster.removeAll { $0 == name }
        }
    }

    /// 把 [PaymentMethodInfo] 中名稱為 `oldName` 的項目改名為 `newName`，保留原有 `isCardless`、`isBankTransfer` 與 `isCashOnDelivery`；若 `newName` 已存在則合併 (任一邊曾標記無卡／銀行匯款／貨到付款的就視為該類)
    /// - Parameters:
    ///   - list: 原始陣列
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Returns: 重新命名後的排序陣列
    private func renamePaymentMethods(
        _ list: [PaymentMethodInfo],
        from oldName: String,
        to newName: String
    ) -> [PaymentMethodInfo] {
        var byName: [String: PaymentMethodInfo] = [:]
        for info in list {
            let key = info.name == oldName ? newName : info.name
            let merged = byName[key]
            let isCardless = info.isCardless || (merged?.isCardless ?? false)
            let isBankTransfer = info.isBankTransfer || (merged?.isBankTransfer ?? false)
            let isCashOnDelivery = info.isCashOnDelivery || (merged?.isCashOnDelivery ?? false)
            byName[key] = PaymentMethodInfo(name: key, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery)
        }
        return byName.values
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// 把 list 中等於 `oldName` 的項目替換成 `newName`，去重後依 locale 排序
    /// - Parameters:
    ///   - list: 原始陣列
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Returns: 重新命名後的排序陣列
    private func renameInList(
        _ list: [String],
        from oldName: String,
        to newName: String
    ) -> [String] {
        let replaced = list.map { $0 == oldName ? newName : $0 }
        return Array(Set(replaced))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// 因為 ``LedgerOrder`` 是 immutable struct，更新 orderSource、categories 或 paymentMethod 必須以 memberwise init 重建
    /// - Parameters:
    ///   - order: 原本的訂單
    ///   - orderSource: 若不為 `nil` 則覆寫 orderSource
    ///   - categories: 若不為 `nil` 則覆寫 categories
    ///   - paymentMethod: 若不為 `nil` 則覆寫 paymentMethod
    ///   - verificationStatus: 若不為 `nil` 則覆寫 verificationStatus
    ///   - campaignNames: 若不為 `nil` 則覆寫 campaignNames
    /// - Returns: 重建後的訂單
    private func rebuildOrder(
        _ order: LedgerOrder,
        orderSource: String? = nil,
        categories: [String]? = nil,
        paymentMethod: String? = nil,
        verificationStatus: String? = nil,
        campaignNames: [String]? = nil
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
            orderSource: orderSource ?? order.orderSource,
            categories: categories ?? order.categories,
            paymentMethod: paymentMethod ?? order.paymentMethod,
            notes: order.notes,
            verificationStatus: verificationStatus ?? order.verificationStatus,
            campaignNames: campaignNames ?? order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
}
