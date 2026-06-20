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

// MARK: - Static Method

extension OrderDateSection {

    /// 把訂單依「日」分組為日期區段，供訂單列表與合併候選清單共用。
    ///
    /// 分組鍵為 `calendar.startOfDay`；區段依日期由新到舊排序，段內訂單亦由新到舊排序，標題經 ``OrderFormatters/daySectionTitle(for:referenceDate:calendar:)`` 產生 (今天/昨天/格式化日期)。
    /// - Parameters:
    ///   - orders: 要分組的訂單。
    ///   - referenceDate: 判斷「今天／昨天」的基準時間。
    ///   - calendar: 分組與標題使用的曆法。
    /// - Returns: 依日期由新到舊排序的區段。
    static func group(_ orders: [LedgerOrder], referenceDate: Date, calendar: Calendar) -> [OrderDateSection] {
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
                        calendar: calendar
                    ),
                    orders: (grouped[day] ?? []).sorted { $0.date > $1.date }
                )
            }
    }
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

        /// 目前套用的付款方式篩選；`nil` 代表全部付款方式。
        var selectedPaymentMethod: String?

        /// 目前選取的訂單編號。
        var selectedOrderID: LedgerOrder.ID?

        /// 是否處於多選模式 (進入後列點擊改為勾選、顯示批次工具列)。
        var isSelecting = false

        /// 多選模式下已勾選的訂單編號集合。
        var selectedOrderIDs: Set<LedgerOrder.ID> = []

        /// 訂單來源主檔 (從 ``OrderSourceRepository`` 載入)。
        var orderSourceMaster: [String] = []

        /// 商品類別主檔 (從 ``CategoryRepository`` 載入)。
        var categoryMaster: [String] = []

        /// 付款方式主檔 (從 ``PaymentMethodRepository`` 載入)，含每筆方式是否屬於無卡類。
        var paymentMethodMaster: [PaymentMethodInfo] = []

        /// 對帳狀態主檔 (從 ``VerificationStatusRepository`` 載入)。
        var verificationStatusMaster: [String] = []

        /// 開團主檔 (從 ``CampaignRepository`` 載入)；持有完整 ``Campaign`` 而非僅名稱，以便訂單列表按開團狀態篩選時解析每筆訂單所屬團的狀態。
        var campaigns: [Campaign] = []

        /// 目前套用的指定開團篩選；`nil` 代表全部開團。
        var selectedCampaign: String?

        /// 目前套用的開團狀態篩選；`nil` 代表全部狀態。
        var selectedCampaignStatus: CampaignStatus?

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

        /// 「合併訂單」流程 (候選選擇 → 照片挑選) 的 sheet 狀態；`nil` 表示未呈現。
        @Presents var orderMerge: OrderMergeFeature.State?

        // MARK: - Filter Method

        /// 套用搜尋、狀態與日期區間篩選後的訂單。
        ///
        /// 改成 method 後 caller 必須帶入 `referenceDate` 與 `calendar`；reducer / view 端皆由各自的 `@Dependency(\.date)` 與 `@Dependency(\.calendar)` 注入。如此可在 snapshot / unit test 中固定「現在」時間與行事曆，避免跨日或跨時區跑出不同結果。
        /// - Parameters:
        ///   - referenceDate: 計算「本週／本月／上月」等相對區間的基準時間。
        ///   - calendar: 判斷日期區間所用的行事曆 (含時區)；測試應注入固定 gregorian／UTC。
        /// - Returns: 過濾後的訂單。
        func filteredOrders(referenceDate: Date, calendar: Calendar) -> [LedgerOrder] {
            let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            return orders.filter { order in
                let matchesStatus = selectedStatus.orderStatus.map { $0 == order.status } ?? true
                let matchesSearch = normalizedQuery.isEmpty || order.searchableText.contains(normalizedQuery)
                let matchesDate = selectedDatePeriod.includes(
                    order.date,
                    referenceDate: referenceDate,
                    calendar: calendar
                )
                let matchesCategory = selectedCategory.map { order.categories.contains($0) } ?? true
                let matchesPaymentMethod = selectedPaymentMethod.map { $0 == order.paymentMethod } ?? true
                let matchesCampaign = selectedCampaign.map { order.campaignNames.contains($0) } ?? true
                let matchesCampaignStatus = selectedCampaignStatus.map { status in
                    campaignStatuses(for: order).contains(status)
                } ?? true

                return matchesStatus
                    && matchesSearch
                    && matchesDate
                    && matchesCategory
                    && matchesPaymentMethod
                    && matchesCampaign
                    && matchesCampaignStatus
            }
        }

        /// 解析訂單所屬開團的狀態集合；任一所屬開團符合篩選狀態即視為命中。未歸團或在 ``campaigns`` 找不到對應開團時為空集合。
        /// - Parameter order: 要解析的訂單。
        /// - Returns: 所屬各開團的狀態集合。
        func campaignStatuses(for order: LedgerOrder) -> Set<CampaignStatus> {
            Set(
                order.campaignNames.compactMap { name -> CampaignStatus? in
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return nil }
                    return campaigns.first { $0.name == trimmed }?.status
                }
            )
        }

        /// 目前選取的訂單。
        /// - Parameters:
        ///   - referenceDate: 與 ``filteredOrders(referenceDate:calendar:)`` 同一基準。
        ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆。
        /// - Returns: 對應的訂單；若 `selectedOrderID` 已不在當前篩選結果中，回傳第一筆。
        func selectedOrder(referenceDate: Date, calendar: Calendar) -> LedgerOrder? {
            let filtered = filteredOrders(referenceDate: referenceDate, calendar: calendar)
            guard let selectedOrderID else { return filtered.first }
            return filtered.first { $0.id == selectedOrderID }
        }

        /// 將 ``filteredOrders(referenceDate:calendar:)`` 的結果以「日」為單位分組成區段，供訂單列表以日期區段標題呈現 (列內毋須再顯示日期)。
        ///
        /// 分組與相對標題 (今天／昨天) 皆以 `referenceDate` 與 `calendar` 為基準；同一基準下結果一致。
        /// - Parameters:
        ///   - referenceDate: 與 ``filteredOrders(referenceDate:calendar:)`` 同一基準的「現在」時間。
        ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆。
        /// - Returns: 依日期由新到舊排序的區段；每段內訂單亦由新到舊排序。
        func dateSections(referenceDate: Date, calendar: Calendar) -> [OrderDateSection] {
            OrderDateSection.group(
                filteredOrders(referenceDate: referenceDate, calendar: calendar),
                referenceDate: referenceDate,
                calendar: calendar
            )
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
                .flatMap(\.categories)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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

        /// 對外提供給編輯表單的「可用對帳狀態」清單：合併主檔與既有訂單中使用過的對帳狀態，去重後依 locale 排序。合併規則與 ``availableCategories`` 相同。
        var availableVerificationStatuses: [String] {
            let fromOrders = orders
                .map { $0.verificationStatus.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(verificationStatusMaster)
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }

        /// 對外提供給編輯表單的「可用開團」清單：合併開團主檔名稱與既有訂單中使用過的開團名稱，去重後依 locale 排序。合併規則與 ``availableCategories`` 相同。
        var availableCampaigns: [String] {
            let fromOrders = orders
                .flatMap(\.campaignNames)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var merged = Set(campaigns.map(\.name))
            merged.formUnion(fromOrders)
            return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }

        /// 對外提供給編輯表單下拉選單的「可歸屬開團」清單：僅取狀態為開團中 (``CampaignStatus/ongoing``) 的開團名稱，依 locale 排序。
        /// 已收單的開團不列入，避免下拉選單項目過長；正在編輯的訂單若已歸屬已收單開團，由 ``OrderEditFeature`` 的 init 自動保留該既有選項，不會遺失。
        var ongoingCampaigns: [String] {
            let names = campaigns
                .filter { $0.status == .ongoing }
                .map(\.name)
            return Set(names).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }

        // MARK: - AI Method

        /// 把目前篩選後訂單的商品明細整理成給模型的純文字摘要輸入。
        ///
        /// 每筆訂單逐項列出「- [類別] 名稱 x數量 @ 單價 幣別」；為避免 token 爆量，最多納入 `maxItems` 個品項，超出以一行提示帶過。
        /// - Parameters:
        ///   - referenceDate: 與 ``filteredOrders(referenceDate:calendar:)`` 同一基準。
        ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆。
        /// - Returns: 商品明細的純文字摘要；列表沒有任何品項時回傳提示字串。
        func aiItemsDigest(referenceDate: Date, calendar: Calendar) -> String {
            let maxItems = 200
            let filtered = filteredOrders(referenceDate: referenceDate, calendar: calendar)
            var lines: [String] = []

            outer: for order in filtered {
                let categoryNames = order.categories
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                let categoryTag = categoryNames.isEmpty ? "未分類" : categoryNames.joined(separator: "、")
                for item in order.items {
                    let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = trimmedName.isEmpty ? "未命名商品" : trimmedName
                    lines.append("- [\(categoryTag)] \(name) x\(item.quantity) @ \(item.unitPrice) \(order.currency.rawValue)")
                    if lines.count >= maxItems { break outer }
                }
            }

            guard !lines.isEmpty else {
                return "(目前列表沒有任何商品明細)"
            }

            var digest = lines.joined(separator: "\n")
            let totalItems = filtered.reduce(0) { $0 + $1.items.count }
            if totalItems > lines.count {
                digest += "\n…(其餘 \(totalItems - lines.count) 個品項未列出)"
            }
            return digest
        }

        /// 組出指示模型以正體中文 Markdown 總結商品明細的完整 prompt。
        /// - Parameters:
        ///   - referenceDate: 與 ``filteredOrders(referenceDate:calendar:)`` 同一基準。
        ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆。
        /// - Returns: 給 Ollama 的 user prompt。
        func aiSummaryPrompt(referenceDate: Date, calendar: Calendar) -> String {
            let categoryScope = selectedCategory.map { "(已篩選類別：\($0))" } ?? "(涵蓋目前列表所有類別)"
            return """
            你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細\(categoryScope)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

            \(aiItemsDigest(referenceDate: referenceDate, calendar: calendar))

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

        /// 對帳狀態主檔載入完成。
        case verificationStatusMasterLoaded([String])

        /// 開團主檔載入完成。
        case campaignsLoaded([Campaign])

        /// 使用者切換狀態篩選。
        case statusFilterSelected(OrderStatusFilter)

        /// 使用者切換日期區間篩選。
        case datePeriodSelected(OrderDatePeriod)

        /// 使用者切換商品類別篩選 (`nil` = 全部)。
        case categoryFilterSelected(String?)

        /// 使用者切換付款方式篩選 (`nil` = 全部)。
        case paymentMethodFilterSelected(String?)

        /// 使用者切換指定開團篩選 (`nil` = 全部開團)。
        case campaignFilterSelected(String?)

        /// 使用者切換開團狀態篩選 (`nil` = 全部狀態)。
        case campaignStatusFilterSelected(CampaignStatus?)

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

        /// 使用者從訂單列 context menu 或詳情頁觸發「合併訂單」；參數為主訂單編號。
        case mergeOrderTapped(LedgerOrder.ID)

        /// 合併流程 sheet 事件；完成 delegate 由父層在此回收。
        case orderMerge(PresentationAction<OrderMergeFeature.Action>)

        /// 合併資料選定完成、合併 sheet 收合後，以合併草稿與保留照片開啟確認表單 (兩段 sheet 序列化呈現)。
        case mergeConfirmationReady(OrderMerge.Draft, keptPhotos: [Data])

        /// 合併持久化失敗：以快照整批回復 in-memory 訂單，避免半合併狀態。
        case mergePersistenceFailed([LedgerOrder])

        /// 透過詳情頁的「更新狀態」menu 直接切換訂單狀態。
        case statusChanged(LedgerOrder.ID, OrderStatus)

        /// 進入／退出多選模式；退出時清空已選集合。
        case selectionModeToggled

        /// 多選模式下切換單筆訂單的勾選狀態。
        case orderSelectionToggled(LedgerOrder.ID)

        /// 全選目前篩選後清單。
        case selectAllTapped

        /// 清除目前已選集合。
        case clearSelectionTapped

        /// 對已選訂單批次套用同一目標狀態 (目標清單已排除 merged)。
        case batchStatusChanged(OrderStatus)

        /// 切換訂單收款狀態 (待收款／已收款)；供開團詳情頁逐筆勾稽收款使用。
        case receiptStatusChanged(LedgerOrder.ID, PaymentReceiptStatus)

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

    /// 對帳狀態主檔資料來源。
    @Dependency(VerificationStatusRepository.self) private var verificationStatusRepository

    /// 開團主檔資料來源。
    @Dependency(CampaignRepository.self) private var campaignRepository

    /// 用於新訂單的 UUID 產生器，方便在測試中注入固定值。
    @Dependency(\.uuid) private var uuid

    /// 用於新訂單的日期來源，方便在測試中注入固定值。
    @Dependency(\.date) private var date

    /// 訂單篩選與日期分組所用的行事曆 (含時區)；測試可注入固定 gregorian／UTC。
    @Dependency(\.calendar) private var calendar

    /// 合併流程兩段 sheet 序列化呈現的延遲時脈；測試可注入 immediate clock。
    @Dependency(\.continuousClock) private var clock

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
                let verificationStatusRepository = verificationStatusRepository
                let campaignRepository = campaignRepository
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    async let orderSourcesTask: Void = {
                        if let items = try? await orderSourceRepository.fetchOrderSources() {
                            await send(.orderSourceMasterLoaded(items))
                        }
                    }()
                    async let campaignsTask: Void = {
                        if let items = try? await campaignRepository.fetchCampaigns() {
                            await send(.campaignsLoaded(items))
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
                    async let verificationStatusesTask: Void = {
                        if let items = try? await verificationStatusRepository.fetchVerificationStatuses() {
                            await send(.verificationStatusMasterLoaded(items))
                        }
                    }()

                    do {
                        let orders = try await orderRepository.fetchOrders()
                        await send(.ordersLoaded(orders))
                    } catch {
                        await send(.ordersFailed("訂單載入失敗，請稍後再試。"))
                    }

                    _ = await (orderSourcesTask, campaignsTask, categoriesTask, paymentMethodsTask, verificationStatusesTask)
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

            case let .verificationStatusMasterLoaded(items):
                state.verificationStatusMaster = items
                return .none

            case let .campaignsLoaded(campaigns):
                state.campaigns = campaigns
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
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .datePeriodSelected(period):
                state.selectedDatePeriod = period
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .categoryFilterSelected(category):
                state.selectedCategory = category
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .paymentMethodFilterSelected(paymentMethod):
                state.selectedPaymentMethod = paymentMethod
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .campaignFilterSelected(campaign):
                state.selectedCampaign = campaign
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .campaignStatusFilterSelected(campaignStatus):
                state.selectedCampaignStatus = campaignStatus
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
                return .none

            case let .searchTextChanged(searchText):
                state.searchText = searchText
                state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
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
                    availableVerificationStatuses: state.availableVerificationStatuses,
                    availableCampaigns: state.ongoingCampaigns,
                    currentDate: date.now
                )
                return .none

            case .newOrderTapped:
                state.editOrder = OrderEditFeature.State(
                    availableOrderSources: state.availableOrderSources,
                    availableCategories: state.availableCategories,
                    availablePaymentMethods: state.availablePaymentMethods,
                    availableVerificationStatuses: state.availableVerificationStatuses,
                    availableCampaigns: state.ongoingCampaigns,
                    currentDate: date.now
                )
                return .none

            case .editOrder(.presented(.saveTapped)):
                guard let editState = state.editOrder else { return .none }

                // 合併草稿：寫入新訂單之外，還要把來源訂單轉「已合併」，並以單一持久化操作落盤。
                if !editState.mergeSourceIDs.isEmpty {
                    // 快照供持久化失敗時整批回復，確保 in-memory 不留半合併狀態。
                    let previousOrders = state.orders
                    guard let savedOrder = applyEditDraft(editState, to: &state) else {
                        return .none
                    }

                    let sourceIDs = editState.mergeSourceIDs
                    state.orders = state.orders.map { order in
                        guard sourceIDs.contains(order.id), order.id != savedOrder.id else { return order }
                        return order.withStatus(.merged)
                    }

                    let orderRepository = orderRepository
                    return .run { send in
                        do {
                            try await orderRepository.mergeOrders(savedOrder, sourceIDs)
                        } catch {
                            await send(.mergePersistenceFailed(previousOrders))
                        }
                    }
                }

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
                // 子 reducer 已把 name 加進 sheet 內的 availableCategories 並設成 draftCategories；
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

            case let .editOrder(.presented(.addPaymentMethodTapped(name, isCardless, isBankTransfer, isCashOnDelivery))):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                // 同名情境：以新的 isCardless / isBankTransfer / isCashOnDelivery 覆寫，讓 sheet 內二次新增能更正先前忘記勾選的狀態。
                var updated = state.paymentMethodMaster
                if let index = updated.firstIndex(where: { $0.name == trimmed }) {
                    updated[index] = PaymentMethodInfo(
                        name: trimmed, 
                        isCardless: isCardless, 
                        isBankTransfer: isBankTransfer, 
                        isCashOnDelivery: isCashOnDelivery
                    )
                } else {
                    updated.append(PaymentMethodInfo(
                        name: trimmed, 
                        isCardless: isCardless, 
                        isBankTransfer: isBankTransfer, 
                        isCashOnDelivery: isCashOnDelivery
                    ))
                }
                state.paymentMethodMaster = updated.sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }

                let paymentMethodRepository = paymentMethodRepository
                return .run { _ in
                    try? await paymentMethodRepository.addPaymentMethod(trimmed, isCardless, isBankTransfer, isCashOnDelivery)
                }

            case let .editOrder(.presented(.addVerificationStatusTapped(name))):
                // 子 reducer 已把 name 加進 sheet 內的 availableVerificationStatuses 並設成 draftVerificationStatus；
                // 父層額外寫入主檔並更新 state.verificationStatusMaster，使非編輯流程 (管理頁、其他訂單) 也能看到。
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                if !state.verificationStatusMaster.contains(trimmed) {
                    var updated = state.verificationStatusMaster
                    updated.append(trimmed)
                    state.verificationStatusMaster = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                let verificationStatusRepository = verificationStatusRepository
                return .run { _ in
                    try? await verificationStatusRepository.addVerificationStatus(trimmed)
                }

            case .editOrder:
                return .none

            case let .mergeOrderTapped(orderID):
                // 已合併/已取消的訂單不可作為主訂單 (入口在 view 端同樣隱藏，此處為防衛)。
                guard let primary = state.orders.first(where: { $0.id == orderID }),
                      primary.status != .merged,
                      primary.status != .cancelled else {
                    return .none
                }

                state.orderMerge = OrderMergeFeature.State(primary: primary, orders: state.orders)
                return .none

            case let .orderMerge(.presented(.delegate(.completed(primary, secondary, keptPhotos)))):
                // 以付款方式主檔旗標建構無卡判定，計算合併草稿 (純函式)。
                let cardlessNames = Set(state.availablePaymentMethods.filter(\.isCardless).map(\.name))
                let draft = OrderMerge.makeDraft(
                    primary: primary,
                    secondary: secondary,
                    now: date.now,
                    isCardless: { cardlessNames.contains($0) }
                )

                // 先收合合併 sheet，延遲一拍再開啟確認表單，避免同 frame 換 sheet 的 presentation race。
                state.orderMerge = nil
                let clock = clock
                return .run { send in
                    try? await clock.sleep(for: .milliseconds(500))
                    await send(.mergeConfirmationReady(draft, keptPhotos: keptPhotos))
                }

            case .orderMerge:
                return .none

            case let .mergeConfirmationReady(draft, keptPhotos):
                var editState = OrderEditFeature.State(
                    availableOrderSources: state.availableOrderSources,
                    availableCategories: state.availableCategories,
                    availablePaymentMethods: state.availablePaymentMethods,
                    availableVerificationStatuses: state.availableVerificationStatuses,
                    availableCampaigns: state.availableCampaigns,
                    currentDate: date.now
                )
                editState.draftCustomerName = draft.customer.name
                editState.draftOrderSource = draft.orderSource
                editState.draftCategories = draft.categories
                editState.draftStatus = draft.status
                editState.draftCurrency = draft.currency
                editState.draftChargedAmount = draft.chargedAmount
                editState.draftCardlessDeductionAmount = draft.cardlessDeductionAmount
                editState.draftCardlessSupplementAmount = draft.cardlessSupplementAmount
                editState.draftItemCost = draft.itemCost
                editState.draftDomesticShipping = draft.domesticShipping
                editState.draftInternationalShipping = draft.internationalShipping
                editState.draftForeignDomesticShipping = draft.foreignDomesticShipping
                editState.draftCardFeeRate = draft.cardFeeRate
                editState.draftPlatformFeeRate = draft.platformFeeRate
                editState.draftPaymentFeeRate = draft.paymentFeeRate
                editState.draftItems = draft.items
                editState.draftNotes = draft.notes
                editState.draftDate = draft.date
                editState.draftPaymentMethod = draft.paymentMethod
                editState.draftVerificationStatus = draft.verificationStatus
                editState.draftCampaignNames = draft.campaignNames
                editState.draftPaymentReceiptStatus = draft.paymentReceiptStatus
                editState.draftPhotos = keptPhotos
                editState.mergeSourceIDs = draft.mergeSourceIDs
                state.editOrder = editState
                return .none

            case let .mergePersistenceFailed(previousOrders):
                // 持久化失敗：回復快照，新單與舊單狀態同進退；以既有錯誤訊息路徑提示。
                state.orders = previousOrders
                state.errorMessage = "合併訂單儲存失敗，請稍後再試。"
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
                    categories: existing.categories,
                    paymentMethod: existing.paymentMethod,
                    notes: existing.notes,
                    verificationStatus: existing.verificationStatus,
                    campaignNames: existing.campaignNames,
                    paymentReceiptStatus: existing.paymentReceiptStatus,
                    isCashOnDelivery: existing.isCashOnDelivery,
                    photos: existing.photos,
                    mergedSourceIDs: existing.mergedSourceIDs
                )
                state.orders[index] = updated

                let orderRepository = orderRepository
                return .run { _ in
                    try? await orderRepository.saveOrder(updated)
                }

            case .selectionModeToggled:
                state.isSelecting.toggle()
                if !state.isSelecting {
                    state.selectedOrderIDs = []
                }
                return .none

            case let .orderSelectionToggled(id):
                if state.selectedOrderIDs.contains(id) {
                    state.selectedOrderIDs.remove(id)
                } else {
                    state.selectedOrderIDs.insert(id)
                }
                return .none

            case .selectAllTapped:
                let filtered = state.filteredOrders(referenceDate: date.now, calendar: calendar)
                state.selectedOrderIDs = Set(filtered.map(\.id))
                return .none

            case .clearSelectionTapped:
                state.selectedOrderIDs = []
                return .none

            case let .batchStatusChanged(newStatus):
                // merged 僅由合併流程寫入；批次目標清單已於 view 端排除，此處為防衛。
                guard newStatus != .merged else {
                    return .none
                }

                // 對已選訂單逐筆重建狀態，略過已是目標狀態者；收集實際變更以單次批次落盤。
                let selectedIDs = state.selectedOrderIDs
                var changed: [LedgerOrder] = []
                for index in state.orders.indices {
                    let order = state.orders[index]
                    guard selectedIDs.contains(order.id), order.status != newStatus else {
                        continue
                    }
                    let updated = order.withStatus(newStatus)
                    state.orders[index] = updated
                    changed.append(updated)
                }

                // 無論是否有實際變更皆退出多選並清空選取。
                state.isSelecting = false
                state.selectedOrderIDs = []

                guard !changed.isEmpty else {
                    return .none
                }

                let orderRepository = orderRepository
                let changedOrders = changed
                return .run { _ in
                    try? await orderRepository.saveOrders(changedOrders)
                }

            case let .receiptStatusChanged(orderID, newReceiptStatus):
                guard let index = state.orders.firstIndex(where: { $0.id == orderID }),
                      state.orders[index].paymentReceiptStatus != newReceiptStatus else {
                    return .none
                }

                let existing = state.orders[index]
                let updated = LedgerOrder(
                    id: existing.id,
                    customer: existing.customer,
                    status: existing.status,
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
                    categories: existing.categories,
                    paymentMethod: existing.paymentMethod,
                    notes: existing.notes,
                    verificationStatus: existing.verificationStatus,
                    campaignNames: existing.campaignNames,
                    paymentReceiptStatus: newReceiptStatus,
                    isCashOnDelivery: existing.isCashOnDelivery,
                    photos: existing.photos,
                    mergedSourceIDs: existing.mergedSourceIDs
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
                    state.selectedOrderID = state.filteredOrders(referenceDate: date.now, calendar: calendar).first?.id
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
                    prompt: state.aiSummaryPrompt(referenceDate: date.now, calendar: calendar),
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
        .ifLet(\.$orderMerge, action: \.orderMerge) {
            OrderMergeFeature()
        }
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
        let normalizedCategories = normalizedNames(draft.draftCategories)
        let trimmedPaymentMethod = draft.draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        // 備註為選填欄位：只 trim 首尾空白與換行 (保留段落間的內部換行)，清空時也如實存回空字串，不像必填欄位那樣 fallback 回原值。
        let trimmedNotes = draft.draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCampaignNames = normalizedNames(draft.draftCampaignNames)

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
        // 對帳狀態僅在付款方式屬於無卡或銀行匯款時有意義；切回其他付款方式一律清成空字串，避免殘留無關狀態。
        let normalizedVerificationStatus = draft.showsVerificationStatusRow
            ? draft.draftVerificationStatus.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""

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
                categories: normalizedCategories.isEmpty ? existing.categories : normalizedCategories,
                paymentMethod: trimmedPaymentMethod.isEmpty ? existing.paymentMethod : trimmedPaymentMethod,
                notes: trimmedNotes,
                verificationStatus: normalizedVerificationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: draft.draftPaymentReceiptStatus,
                isCashOnDelivery: draft.isSelectedPaymentMethodCOD,
                photos: draft.draftPhotos,
                mergedSourceIDs: existing.mergedSourceIDs
            )
            state.orders[index] = updatedOrder
            return updatedOrder
        } else {
            let resolvedName = trimmedName.isEmpty ? "未命名客戶" : trimmedName
            let resolvedOrderSource = trimmedOrderSource.isEmpty ? "未指定" : trimmedOrderSource
            let resolvedCategories = normalizedCategories.isEmpty ? ["未分類"] : normalizedCategories
            let initials = String(resolvedName.prefix(2)).uppercased()
            let draftID = "BL-DRAFT-\(uuid().uuidString.prefix(6))"

            // 合併草稿沿用主訂單的客戶 (保留 initials 與 tier，避免被視為新客戶)；一般新訂單維持 .new。
            let mergePrimaryCustomer = draft.mergeSourceIDs.first
                .flatMap { primaryID in state.orders.first { $0.id == primaryID }?.customer }
            let resolvedCustomer = mergePrimaryCustomer.map {
                LedgerCustomer(name: resolvedName, initials: $0.initials, tier: $0.tier)
            } ?? LedgerCustomer(name: resolvedName, initials: initials, tier: .new)

            let newOrder = LedgerOrder(
                id: draftID,
                customer: resolvedCustomer,
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
                categories: resolvedCategories,
                paymentMethod: trimmedPaymentMethod,
                notes: trimmedNotes,
                verificationStatus: normalizedVerificationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: draft.draftPaymentReceiptStatus,
                isCashOnDelivery: draft.isSelectedPaymentMethodCOD,
                photos: draft.draftPhotos,
                mergedSourceIDs: draft.mergeSourceIDs
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

    /// 將草稿名稱陣列正規化：逐元素 trim、去除空字串與重複 (保序)。
    /// - Parameter names: 草稿陣列 (類別或開團)。
    /// - Returns: 正規化後的名稱陣列。
    func normalizedNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}

// MARK: - Private Method

private extension LedgerOrder {

    /// 回傳僅變更狀態的複本；``LedgerOrder`` 為 immutable struct，須以 memberwise init 重建。
    /// - Parameter newStatus: 新的訂單狀態。
    /// - Returns: 重建後的訂單。
    func withStatus(_ newStatus: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: newStatus,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            paymentFeeRate: paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            verificationStatus: verificationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 供訂單列表搜尋使用的正規化文字。
    var searchableText: String {
        (
            [
                id,
                customer.name,
                customer.initials,
                orderSource,
                currency.rawValue,
            ] + categories + items.map(\.name)
        )
        .joined(separator: " ")
        .lowercased()
    }
}
