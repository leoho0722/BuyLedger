//
//  OrdersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 訂單列表以「日」為單位分組後的單一日期區段。
struct OrderDateSection: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 區段識別值，使用該日的起始時刻 (start of day)。
    let id: Date

    // MARK: - Data Properties

    /// 區段標題 (例如「今天」「昨天」「5月26日 週一」)。
    let title: String

    /// 該日的訂單，依時間由新到舊排序。
    let orders: [LedgerOrder]
}

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

        /// 目前套用的商品類別篩選；`nil` 代表全部類別。
        var selectedCategory: String?

        /// 目前選取的訂單編號。
        var selectedOrderID: LedgerOrder.ID?

        /// 訂單來源主檔 (從 ``OrderSourceRepository`` 載入)。
        var orderSourceMaster: [String] = []

        /// 商品類別主檔 (從 ``CategoryRepository`` 載入)。
        var categoryMaster: [String] = []

        /// 付款方式主檔 (從 ``PaymentMethodRepository`` 載入)，含每筆方式是否屬於無卡類。
        var paymentMethodMaster: [PaymentMethodInfo] = []

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

        /// AI 商品明細總結 sheet 狀態；`nil` 表示未呈現。
        @Presents var aiSummary: AISummaryFeature.State?

        /// AI 功能未開啟時的提示 alert；`nil` 表示未呈現。
        @Presents var aiDisabledAlert: AlertState<Action.Alert>?

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
                let matchesCategory = selectedCategory.map { $0 == order.category } ?? true

                return matchesStatus && matchesSearch && matchesDate && matchesCategory
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

        /// 將 ``filteredOrders(referenceDate:)`` 的結果以「日」為單位分組成區段，供訂單列表以日期區段標題呈現 (列內毋須再顯示日期)。
        ///
        /// 分組與相對標題 (今天／昨天) 皆以 `referenceDate` 為基準，沿用 ``filteredOrders(referenceDate:)`` 的 `Calendar.current`；同一基準下結果一致。
        /// - Parameter referenceDate: 與 ``filteredOrders(referenceDate:)`` 同一基準的「現在」時間。
        /// - Returns: 依日期由新到舊排序的區段；每段內訂單亦由新到舊排序。
        func dateSections(referenceDate: Date) -> [OrderDateSection] {
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: filteredOrders(referenceDate: referenceDate)) {
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
                            calendar: calendar
                        ),
                        orders: (grouped[day] ?? []).sorted { $0.date > $1.date }
                    )
                }
        }

        /// 對外提供給編輯表單的「可用訂單來源」清單：合併主檔與既有訂單中使用過的來源，去重後依 locale 排序。合併規則與 ``availableCategories`` 相同。
        var availableOrderSources: [String] {
            let fromOrders = orders
                .map { $0.orderSource.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(orderSourceMaster)
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }

        /// 對外提供給編輯表單的「可用類別」清單：合併主檔與既有訂單中使用過的類別，去重後依 locale 排序。
        ///
        /// 合併目的：使用者升級到主檔機制之前，舊訂單已經有 category 字串。為了不讓他們在編輯既有訂單時看到「自己用過的類別不在選單」，把訂單裡用過但主檔還沒有的也補進來。新增動作 (``addCategoryTapped``) 仍會把該值寫入主檔，所以這份合併清單會逐漸與主檔一致。
        var availableCategories: [String] {
            let fromOrders = orders
                .map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(categoryMaster)
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }

        /// 對外提供給編輯表單的「可用付款方式」清單；合併規則同 ``availableCategories``，但保留 `isCardless` 旗標。
        ///
        /// 訂單裡用過但主檔還沒有的付款方式以 `isCardless == false` 補上；主檔有的則直接帶入 `isCardless`，使編輯表單能正確判斷是否顯示「無卡折抵金額」與「無卡補款金額」欄位。
        var availablePaymentMethods: [PaymentMethodInfo] {
            var byName: [String: PaymentMethodInfo] = [:]
            for info in paymentMethodMaster {
                byName[info.name] = info
            }
            for order in orders {
                let trimmed = order.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, byName[trimmed] == nil else { continue }
                byName[trimmed] = PaymentMethodInfo(name: trimmed, isCardless: false)
            }
            return byName.values
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }

        // MARK: - AI Method

        /// 把目前篩選後訂單的商品明細整理成給模型的純文字摘要輸入。
        ///
        /// 每筆訂單逐項列出「- [類別] 名稱 x數量 @ 單價 幣別」；為避免 token 爆量，最多納入 `maxItems` 個品項，超出以一行提示帶過。
        /// - Parameter referenceDate: 與 ``filteredOrders(referenceDate:)`` 同一基準。
        /// - Returns: 商品明細的純文字摘要；列表沒有任何品項時回傳提示字串。
        func aiItemsDigest(referenceDate: Date) -> String {
            let maxItems = 200
            let filtered = filteredOrders(referenceDate: referenceDate)
            var lines: [String] = []

            outer: for order in filtered {
                let category = order.category.trimmingCharacters(in: .whitespacesAndNewlines)
                let categoryTag = category.isEmpty ? "未分類" : category
                for item in order.items {
                    let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = trimmedName.isEmpty ? "未命名商品" : trimmedName
                    lines.append("- [\(categoryTag)] \(name) x\(item.quantity) @ \(item.unitPrice) \(order.currency.rawValue)")
                    if lines.count >= maxItems { break outer }
                }
            }

            guard !lines.isEmpty else {
                return "（目前列表沒有任何商品明細）"
            }

            var digest = lines.joined(separator: "\n")
            let totalItems = filtered.reduce(0) { $0 + $1.items.count }
            if totalItems > lines.count {
                digest += "\n…（其餘 \(totalItems - lines.count) 個品項未列出）"
            }
            return digest
        }

        /// 組出指示模型以正體中文 Markdown 總結商品明細的完整 prompt。
        /// - Parameter referenceDate: 與 ``filteredOrders(referenceDate:)`` 同一基準。
        /// - Returns: 給 Ollama 的 user prompt。
        func aiSummaryPrompt(referenceDate: Date) -> String {
            let categoryScope = selectedCategory.map { "（已篩選類別：\($0)）" } ?? "（涵蓋目前列表所有類別）"
            return """
            你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細\(categoryScope)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

            \(aiItemsDigest(referenceDate: referenceDate))

            請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
            - 一個 `##` 層級的標題
            - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

            請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
            """
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

        /// 訂單來源主檔載入完成。
        case orderSourceMasterLoaded([String])

        /// 商品類別主檔載入完成。
        case categoryMasterLoaded([String])

        /// 付款方式主檔載入完成。
        case paymentMethodMasterLoaded([PaymentMethodInfo])
        
        /// 使用者切換狀態篩選。
        case statusFilterSelected(OrderStatusFilter)
        
        /// 使用者切換日期區間篩選。
        case datePeriodSelected(OrderDatePeriod)

        /// 使用者切換商品類別篩選 (`nil` = 全部)。
        case categoryFilterSelected(String?)

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

        /// 使用者點擊「AI 總結」工具列按鈕。
        case aiSummaryTapped

        /// AI 總結 sheet 事件。
        case aiSummary(PresentationAction<AISummaryFeature.Action>)

        /// AI 未開啟提示 alert 事件。
        case aiDisabledAlert(PresentationAction<Alert>)

        /// 刪除確認 dialog 與 AI 提示 alert 共用的選項。
        @CasePathable
        enum Alert: Equatable {

            /// 使用者確認刪除指定訂單。
            case confirmDelete(LedgerOrder.ID)

            /// 使用者選擇前往設定開啟 AI 總結 (導覽由 ``RootFeature`` 攔截處理)。
            case goToAISettings
        }
    }
    
    // MARK: - Dependency Properties
    
    /// 訂單資料來源。
    @Dependency(OrderRepository.self) private var orderRepository

    /// 訂單來源主檔資料來源。
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository

    /// 商品類別主檔資料來源。
    @Dependency(CategoryRepository.self) private var categoryRepository

    /// 付款方式主檔資料來源。
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

    /// 用於新訂單的 UUID 產生器，方便在測試中注入固定值。
    @Dependency(\.uuid) private var uuid

    /// 用於新訂單的日期來源，方便在測試中注入固定值。
    @Dependency(\.date) private var date

    /// 設定持久化來源；用於讀取 `useAiSummary` 與 `aiSummaryModel`。
    @Dependency(SettingsStorage.self) private var settingsStorage

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
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    async let orderSourcesTask: Void = {
                        if let items = try? await orderSourceRepository.fetchOrderSources() {
                            await send(.orderSourceMasterLoaded(items))
                        }
                    }()
                    async let categoriesTask: Void = {
                        if let items = try? await categoryRepository.fetchCategories() {
                            await send(.categoryMasterLoaded(items))
                        }
                    }()
                    async let paymentMethodsTask: Void = {
                        if let infos = try? await paymentMethodRepository.fetchPaymentMethodInfos() {
                            await send(.paymentMethodMasterLoaded(infos))
                        }
                    }()

                    do {
                        let orders = try await orderRepository.fetchOrders()
                        await send(.ordersLoaded(orders))
                    } catch {
                        await send(.ordersFailed("訂單載入失敗，請稍後再試。"))
                    }

                    _ = await (orderSourcesTask, categoriesTask, paymentMethodsTask)
                }

            case let .orderSourceMasterLoaded(items):
                state.orderSourceMaster = items
                return .none

            case let .categoryMasterLoaded(items):
                state.categoryMaster = items
                return .none

            case let .paymentMethodMasterLoaded(infos):
                state.paymentMethodMaster = infos
                return .none
                
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

            case let .categoryFilterSelected(category):
                state.selectedCategory = category
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
                    availableOrderSources: state.availableOrderSources,
                    availableCategories: state.availableCategories,
                    availablePaymentMethods: state.availablePaymentMethods,
                    currentDate: date.now
                )
                return .none

            case .newOrderTapped:
                state.editOrder = OrderEditFeature.State(
                    availableOrderSources: state.availableOrderSources,
                    availableCategories: state.availableCategories,
                    availablePaymentMethods: state.availablePaymentMethods,
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

            case let .editOrder(.presented(.addOrderSourceTapped(name))):
                // 子 reducer 已把 name 加進 sheet 內的 availableOrderSources 並設成 draftOrderSource；
                // 父層額外寫入主檔並更新 state.orderSourceMaster，使非編輯流程 (其他訂單) 也能看到。
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                if !state.orderSourceMaster.contains(trimmed) {
                    var updated = state.orderSourceMaster
                    updated.append(trimmed)
                    state.orderSourceMaster = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                let orderSourceRepository = orderSourceRepository
                return .run { _ in
                    try? await orderSourceRepository.addOrderSource(trimmed)
                }

            case let .editOrder(.presented(.addCategoryTapped(name))):
                // 子 reducer 已把 name 加進 sheet 內的 availableCategories 並設成 draftCategory；
                // 父層額外寫入主檔並更新 state.categoryMaster，使非編輯流程 (管理頁、其他訂單) 也能看到。
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                if !state.categoryMaster.contains(trimmed) {
                    var updated = state.categoryMaster
                    updated.append(trimmed)
                    state.categoryMaster = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                let categoryRepository = categoryRepository
                return .run { _ in
                    try? await categoryRepository.addCategory(trimmed)
                }

            case let .editOrder(.presented(.addPaymentMethodTapped(name, isCardless))):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                // 同名情境：以新的 isCardless 覆寫，讓 sheet 內二次新增能更正先前忘記勾選的狀態。
                var updated = state.paymentMethodMaster
                if let index = updated.firstIndex(where: { $0.name == trimmed }) {
                    updated[index] = PaymentMethodInfo(name: trimmed, isCardless: isCardless)
                } else {
                    updated.append(PaymentMethodInfo(name: trimmed, isCardless: isCardless))
                }
                state.paymentMethodMaster = updated.sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }

                let paymentMethodRepository = paymentMethodRepository
                return .run { _ in
                    try? await paymentMethodRepository.addPaymentMethod(trimmed, isCardless)
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
                    foreignDomesticShipping: existing.foreignDomesticShipping,
                    cardFeeRate: existing.cardFeeRate,
                    platformFeeRate: existing.platformFeeRate,
                    paymentFeeRate: existing.paymentFeeRate,
                    chargedAmount: existing.chargedAmount,
                    cardlessDeductionAmount: existing.cardlessDeductionAmount,
                    cardlessSupplementAmount: existing.cardlessSupplementAmount,
                    orderSource: existing.orderSource,
                    category: existing.category,
                    paymentMethod: existing.paymentMethod,
                    notes: existing.notes
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
                    prompt: state.aiSummaryPrompt(referenceDate: date.now),
                    model: snapshot.aiSummaryModel
                )
                return .none

            // `goToAISettings` 的導覽 (切分頁 + push 設定頁) 由 ``RootFeature`` 攔截；此處 alert 由 TCA 自動關閉。
            case .aiDisabledAlert:
                return .none

            case .aiSummary:
                return .none
            }
        }
        .ifLet(\.$editOrder, action: \.editOrder) {
            OrderEditFeature()
        }
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
        .ifLet(\.$aiSummary, action: \.aiSummary) {
            AISummaryFeature()
        }
        .ifLet(\.$aiDisabledAlert, action: \.aiDisabledAlert)
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
        let trimmedOrderSource = draft.draftOrderSource.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = draft.draftCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPaymentMethod = draft.draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        // 備註為選填欄位：只 trim 首尾空白與換行 (保留段落間的內部換行)，清空時也如實存回空字串，不像必填欄位那樣 fallback 回原值。
        let trimmedNotes = draft.draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedAmount = max(0, draft.draftChargedAmount)
        let normalizedItemCost = max(0, draft.draftItemCost)
        let normalizedDom = max(0, draft.draftDomesticShipping)
        let normalizedIntl = max(0, draft.draftInternationalShipping)
        let normalizedForeignDom = max(0, draft.draftForeignDomesticShipping)
        let normalizedCardFee = clampRate(draft.draftCardFeeRate)
        let normalizedPlatformFee = clampRate(draft.draftPlatformFeeRate)
        let normalizedPaymentFee = clampRate(draft.draftPaymentFeeRate)
        // 只在選到無卡類付款方式時保留兩個金額；切回非無卡的話一律歸零，避免使用者改完付款方式仍把舊金額算進公式。
        let normalizedDeduction = draft.isSelectedPaymentMethodCardless
            ? max(0, draft.draftCardlessDeductionAmount)
            : 0
        let normalizedSupplement = draft.isSelectedPaymentMethodCardless
            ? max(0, draft.draftCardlessSupplementAmount)
            : 0

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
                foreignDomesticShipping: normalizedForeignDom,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                paymentFeeRate: normalizedPaymentFee,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: normalizedDeduction,
                cardlessSupplementAmount: normalizedSupplement,
                orderSource: trimmedOrderSource.isEmpty ? existing.orderSource : trimmedOrderSource,
                category: trimmedCategory.isEmpty ? existing.category : trimmedCategory,
                paymentMethod: trimmedPaymentMethod.isEmpty ? existing.paymentMethod : trimmedPaymentMethod,
                notes: trimmedNotes
            )
            state.orders[index] = updatedOrder
            return updatedOrder
        } else {
            let resolvedName = trimmedName.isEmpty ? "未命名客戶" : trimmedName
            let resolvedOrderSource = trimmedOrderSource.isEmpty ? "未指定" : trimmedOrderSource
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
                foreignDomesticShipping: normalizedForeignDom,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                paymentFeeRate: normalizedPaymentFee,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: normalizedDeduction,
                cardlessSupplementAmount: normalizedSupplement,
                orderSource: resolvedOrderSource,
                category: resolvedCategory,
                paymentMethod: trimmedPaymentMethod,
                notes: trimmedNotes
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
                orderSource,
                category,
                currency.rawValue,
            ] + items.map(\.name)
        )
        .joined(separator: " ")
        .lowercased()
    }
}
