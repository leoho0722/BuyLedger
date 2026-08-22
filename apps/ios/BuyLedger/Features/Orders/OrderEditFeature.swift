//
//  OrderEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import PhotosUI
import SwiftUI

/// 編輯或新增訂單表單的功能
@Reducer
struct OrderEditFeature {
    
    // MARK: - State
    
    /// 編輯/新增訂單表單的狀態
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {
        
        /// 原始訂單；`nil` 代表「新訂單」流程
        let original: LedgerOrder?
        
        /// 表單草稿；只保留未儲存變更需要比較的欄位
        var draft: OrderDraft
        
        /// 是否剛將無卡折抵金額調整到上限
        var cardlessDeductionWasCapped: Bool = false
        
        /// 訂單照片草稿，最多 LedgerOrder.maxPhotoCount 張
        var draftPhotos: [Data]
        
        /// 照片載入階段；新訂單直接完成，既有訂單由 task 載入
        var photoLoadPhase: PhotoLoadPhase
        
        /// 是否曾增刪照片；只有照片已載入且為 true 才會寫入照片
        var hasEditedPhotos: Bool = false
        
        /// PhotosPicker 的選取項目；匯入後清空
        var photoPickerSelection: [PhotosPickerItem] = []
        
        /// 目前以 push 呈現的選項選擇器 route；`nil` 代表未開啟
        var pickerRoute: PickerRoute?
        
        /// 捨棄未儲存變更的確認彈窗
        @Presents var discardConfirmation: AlertState<Action.DiscardAlert>? = nil
        
        /// 目前取得鍵盤焦點的欄位；`nil` 代表無焦點
        var focusedField: Field?
        
        /// 合併來源訂單編號；非空代表這是「合併訂單」的確認草稿
        var mergeSourceIDs: [LedgerOrder.ID] = []
        
        /// 可供選擇的訂單來源
        var availableOrderSources: [String]
        
        /// 可供選擇的商品類別
        var availableCategories: [String]
        
        /// 可選付款方式清單，含分類旗標
        var availablePaymentMethods: [PaymentMethodInfo]
        
        /// 可供選擇的對帳狀態
        var availableReconciliationStatuses: [String]
        
        /// 可供選擇的開團名稱
        var availableCampaigns: [String]
        
        /// 可選幣別清單；無網路時使用預設幣別
        var availableCurrencies: [CurrencyCode]
        
        // MARK: - Identifiable Properties
        
        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用
        let id: UUID
        
        /// 表單開啟時的初始草稿，用於判斷未儲存變更
        let initialDraft: OrderDraft
        
        // MARK: - Init
        
        /// 依原始訂單建立草稿狀態
        /// - Parameters:
        ///   - original: 要編輯的訂單；`nil` 表示新訂單
        ///   - availableOrderSources: 可選的訂單來源
        ///   - availableCategories: 可選的商品類別
        ///   - availablePaymentMethods: 表單可選的付款方式；必要時包含原付款方式
        ///   - availableReconciliationStatuses: 可選的對帳狀態
        ///   - id: 表單識別值
        ///   - currentDate: 新訂單的預設日期
        init(
            original: LedgerOrder? = nil,
            id: UUID,
            availableOrderSources: [String] = [],
            availableCategories: [String] = [],
            availablePaymentMethods: [PaymentMethodInfo] = [],
            availableReconciliationStatuses: [String] = [],
            availableCampaigns: [String] = [],
            availableCurrencies: [CurrencyCode] = CurrencyCode.defaults,
            currentDate: Date
        ) {
            self.original = original
            // 以初始化後的草稿作為 dirty 比對基準。
            let draft = OrderDraft(original: original, currentDate: currentDate)
            self.draft = draft
            self.initialDraft = draft
            self.cardlessDeductionWasCapped =
            (original?.cardlessDeductionAmount ?? 0) > draft.cardlessDeductionAmount
            // 既有照片由 task 載入，不從 original 讀取
            self.draftPhotos = []
            self.photoLoadPhase = original == nil ? .loaded : .notLoaded
            
            var orderSources = availableOrderSources
            let originalOrderSource =
            original?.orderSource.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalOrderSource.isEmpty, !orderSources.contains(originalOrderSource) {
                orderSources.append(originalOrderSource)
            }
            self.availableOrderSources = orderSources.sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            
            var categories = availableCategories
            for originalCategory in (original?.categories ?? []).map({
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }) {
                if !originalCategory.isEmpty, !categories.contains(originalCategory) {
                    categories.append(originalCategory)
                }
            }
            self.availableCategories = categories.sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            
            var paymentMethods = availablePaymentMethods
            let originalPaymentMethod =
            original?.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalPaymentMethod.isEmpty,
               !paymentMethods.contains(where: { $0.name == originalPaymentMethod }) {
                // 舊訂單的付款方式可能尚未存在於主檔。
                paymentMethods.append(
                    PaymentMethodInfo(
                        name: originalPaymentMethod,
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    )
                )
            }
            self.availablePaymentMethods = paymentMethods.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            
            var reconciliationStatuses = availableReconciliationStatuses
            let originalReconciliationStatus =
            original?.reconciliationStatus.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalReconciliationStatus.isEmpty,
               !reconciliationStatuses.contains(originalReconciliationStatus) {
                reconciliationStatuses.append(originalReconciliationStatus)
            }
            self.availableReconciliationStatuses = reconciliationStatuses.sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            
            var campaigns = availableCampaigns
            for originalCampaign in (original?.campaignNames ?? []).map({
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }) {
                if !originalCampaign.isEmpty, !campaigns.contains(originalCampaign) {
                    campaigns.append(originalCampaign)
                }
            }
            self.availableCampaigns = campaigns.sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            
            var currencies = availableCurrencies
            let originalCurrency = original?.currency ?? .twd
            if !currencies.contains(originalCurrency) {
                currencies.append(originalCurrency)
            }
            self.availableCurrencies = currencies.sorted {
                $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending
            }
            
            self.id = id
        }
        
        // MARK: - Computed Properties
        
        /// 草稿或照片有未儲存變更
        var isDirty: Bool {
            draft != initialDraft || hasEditedPhotos
        }
        
        /// 無卡折抵金額的上限，即目前草稿的客戶實付金額
        var maxCardlessDeductionAmount: Decimal {
            max(0, draft.chargedAmount)
        }
        
        /// 目前付款方式是否為無卡類
        var isSelectedPaymentMethodCardless: Bool {
            let trimmed = draft.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return availablePaymentMethods.first { $0.name == trimmed }?.isCardless ?? false
        }
        
        /// 目前付款方式是否為銀行匯款
        var isSelectedPaymentMethodBankTransfer: Bool {
            let trimmed = draft.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return availablePaymentMethods.first { $0.name == trimmed }?.isBankTransfer ?? false
        }
        
        /// 目前付款方式是否為貨到付款
        var isSelectedPaymentMethodCOD: Bool {
            let trimmed = draft.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return availablePaymentMethods.first { $0.name == trimmed }?.isCashOnDelivery ?? false
        }
        
        /// 是否顯示對帳狀態 row
        var showsReconciliationStatusRow: Bool {
            isSelectedPaymentMethodCardless || isSelectedPaymentMethodBankTransfer
        }
        
        /// 是否處於合併情境
        var isMergeContext: Bool {
            !mergeSourceIDs.isEmpty || !(original?.mergedSourceIDs.isEmpty ?? true)
        }
        
        /// 狀態 Picker 的可選清單
        var availableStatuses: [OrderStatus] {
            OrderStatus.allCases.filter { $0 != .merged || draft.status == .merged }
        }
        
        /// 已選類別的顯示文字
        var categoriesDisplayText: String {
            draft.categories.joined(separator: "、")
        }
        
        /// 開團選擇列的顯示文字；未選時顯示「未歸團」
        var campaignsDisplayText: String {
            draft.campaignNames.isEmpty ? "未歸團" : draft.campaignNames.joined(separator: "、")
        }
        
        /// 還可加入的照片張數；供 PhotosPicker 的 `maxSelectionCount` 與計數標籤使用
        var remainingPhotoCapacity: Int {
            max(0, LedgerOrder.maxPhotoCount - draftPhotos.count)
        }
        
        /// 是否還能加入照片
        var canAddMorePhotos: Bool {
            photoLoadPhase == .loaded && remainingPhotoCapacity > 0
        }
        
        /// 是否可刪除既有照片
        var canRemovePhotos: Bool {
            photoLoadPhase == .loaded
        }
    }
    
    // MARK: - Action
    
    /// 表單可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結事件
        case binding(BindingAction<State>)
        
        /// 日期選擇器寫回新日期
        case dateComponentsChanged(Date)
        
        /// 使用者按下取消
        case cancelTapped
        
        /// 使用者按下儲存
        case saveTapped
        
        /// 有未儲存變更時、取消所觸發的捨棄確認彈窗事件
        case discardConfirmation(PresentationAction<DiscardAlert>)
        
        /// 使用者透過「新增來源」彈窗確認新增一筆訂單來源名稱
        case addOrderSourceTapped(String)
        
        /// 使用者透過「新增類別」彈窗確認新增一筆類別名稱
        case addCategoryTapped(String)
        
        /// 單選模式下選擇一個商品類別 (覆寫為單元素陣列)
        case categorySelected(String)
        
        /// 多選模式 (合併情境) 下 toggle 一個商品類別的選取狀態
        case categoryToggled(String)
        
        /// 單選模式下選擇一個開團；空字串代表未歸團
        case campaignSelected(String)
        
        /// 多選模式 (合併情境) 下 toggle 一個開團的選取狀態
        case campaignToggled(String)
        
        /// 確認新增付款方式及其旗標
        case addPaymentMethodTapped(
            name: String,
            flags: PaymentMethodFlags
        )
        
        /// 使用者透過「新增對帳狀態」sheet 確認新增一筆對帳狀態名稱
        case addReconciliationStatusTapped(String)
        
        /// 表單 `.task` 重新載入主檔資料
        case task
        
        /// 從 ``OrderSourceRepository`` 取回最新訂單來源主檔
        case availableOrderSourcesLoaded([String])
        
        /// 從 ``CategoryRepository`` 取回最新類別主檔
        case availableCategoriesLoaded([String])
        
        /// 載入付款方式主檔
        case availablePaymentMethodsLoaded([PaymentMethodInfo])
        
        /// 從 ``ReconciliationStatusRepository`` 取回最新對帳狀態主檔
        case availableReconciliationStatusesLoaded([String])
        
        /// 載入仍在收單的開團名稱
        case availableCampaignsLoaded([Campaign])
        
        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔
        case availableCurrenciesLoaded([CurrencyCode])
        
        /// PhotosPicker 選取項目經 ``PhotoClient`` 載入與正規化完成
        case photosImported([Data])
        
        /// 點擊縮圖時開啟照片檢視器
        case deletePhotoTapped(Int)
        
        /// 既有訂單照片載入完成後更新 state
        case photosLoaded([Data])
        
        /// 既有訂單照片載入失敗後更新 state
        case photosLoadFailed
        
        /// 使用者點擊「新增商品」，附加一筆空白商品明細
        case addItemTapped
        
        /// 使用者滑動刪除指定位置的商品明細
        case deleteItems(IndexSet)
        
        /// 使用者點擊「訂單來源」列，開啟來源選擇 sheet
        case orderSourcePickerTapped
        
        /// 使用者點擊「商品類別」列，開啟類別選擇 sheet
        case categoryPickerTapped
        
        /// 使用者點擊「開團」列 (合併情境)，開啟開團多選 sheet
        case campaignPickerTapped
        
        /// 使用者點擊「幣別」列，開啟幣別選擇 sheet
        case currencyPickerTapped
        
        /// 使用者點擊「付款方式」列，開啟付款方式選擇 sheet
        case paymentMethodPickerTapped
        
        /// 使用者點擊「對帳狀態」列，開啟對帳狀態選擇 sheet
        case reconciliationStatusPickerTapped
        
        /// 使用者在 sheet 選定訂單來源
        case orderSourceSelected(String)
        
        /// 使用者在 sheet 選定付款方式
        case paymentMethodSelected(String)
        
        /// 使用者在 sheet 選定對帳狀態
        case reconciliationStatusSelected(String)
        
        /// 使用者在 sheet 選定幣別 (以 ISO 4217 code 傳入)
        case currencySelected(String)
        
        /// 點擊縮圖時開啟照片檢視器
        case photoTapped(Int)
        
        /// 捨棄確認彈窗的選項
        @CasePathable
        enum DiscardAlert: Equatable {
            
            /// 使用者確認捨棄未儲存的變更並關閉表單
            case discard
        }
    }
    
    // MARK: - Dependency Properties
    
    /// 由父層注入的 dismiss effect
    @Dependency(\.dismiss) private var dismiss
    
    /// 「現在」時間；日期選擇器寫回時用來補上當下秒數，測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 評估開團結單日自動轉狀態的行事曆
    @Dependency(\.calendar) private var calendar
    
    /// 產生新商品明細列的 id；測試可注入固定值以維持可測試性
    @Dependency(\.uuid) private var uuid
    
    /// 訂單來源資料；表單開啟時重新載入
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository
    
    /// 商品類別資料；表單開啟時重新載入
    @Dependency(CategoryRepository.self) private var categoryRepository
    
    /// 付款方式主檔資料來源；理由同 ``categoryRepository``
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository
    
    /// 對帳狀態主檔資料來源；理由同 ``categoryRepository``
    @Dependency(ReconciliationStatusRepository.self) private var reconciliationStatusRepository
    
    /// 開團資料來源；sheet 自行載入
    @Dependency(CampaignRepository.self) private var campaignRepository
    
    /// 幣別資料來源；sheet 從 cache 載入
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository
    
    /// 照片匯入管線；把 PhotosPicker 選取項目載入並正規化為可持久化的 JPEG data
    @Dependency(PhotoClient.self) private var photoClient
    
    /// 訂單資料來源；載入既有訂單照片
    @Dependency(OrderRepository.self) private var orderRepository
    
    // MARK: - Reducer Body
    
    /// 表單 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce {
            state,
            action in
            switch action {
            case .binding(\.photoPickerSelection):
                let items = state.photoPickerSelection
                guard !items.isEmpty else {
                    return .none
                }
                
                let photoClient = photoClient
                return .run { send in
                    await send(.photosImported(photoClient.importPhotos(items)))
                }
                
            case .binding(\.draft.cardlessDeductionAmount),
                    .binding(\.draft.chargedAmount):
                // 任一相關欄位變更都重新限制折抵金額。
                state.reconcileCardlessDeductionCap()
                return .none
                
            case .binding:
                return .none
                
            case let .dateComponentsChanged(newValue):
                // 把 picker 寫回的年月日時分，與「當下這一刻」的秒合併寫入 draft.date
                // 使用固定的 Gregorian／UTC 曆法，讓日期計算可重現。
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
                
                let currentSeconds = calendar.component(.second, from: date.now)
                var components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: newValue
                )
                components.second = currentSeconds
                state.draft.date = calendar.date(from: components) ?? newValue
                return .none
                
            case .saveTapped:
                state.focusedField = nil
                return .run { _ in await dismiss() }
                
            case .cancelTapped:
                // 有未儲存變更時先確認，否則直接關閉。
                guard state.isDirty else {
                    state.focusedField = nil
                    return .run { _ in await dismiss() }
                }
                
                state.discardConfirmation = AlertState {
                    TextState("捨棄變更")
                } actions: {
                    ButtonState(role: .destructive, action: .discard) {
                        TextState("捨棄變更")
                    }
                    ButtonState(role: .cancel) {
                        TextState("繼續編輯")
                    }
                } message: {
                    TextState("這張訂單有尚未儲存的變更，離開後將不會保留。")
                }
                return .none
                
            case .discardConfirmation(.presented(.discard)):
                state.focusedField = nil
                return .run { _ in await dismiss() }
                
            case .discardConfirmation:
                return .none
                
            case let .addOrderSourceTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                
                if !state.availableOrderSources.contains(trimmed) {
                    var updated = state.availableOrderSources
                    updated.append(trimmed)
                    state.availableOrderSources = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                state.draft.orderSource = trimmed
                return .none
                
            case let .addCategoryTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                
                if !state.availableCategories.contains(trimmed) {
                    var updated = state.availableCategories
                    updated.append(trimmed)
                    state.availableCategories = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                if state.isMergeContext {
                    // 多選情境：新增的類別直接加入選取，不覆蓋既有選取
                    if !state.draft.categories.contains(trimmed) {
                        state.draft.categories.append(trimmed)
                    }
                } else {
                    state.draft.categories = [trimmed]
                }
                return .none
                
            case let .categorySelected(name):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                
                state.draft.categories = [trimmed]
                return .none
                
            case let .categoryToggled(name):
                if let index = state.draft.categories.firstIndex(of: name) {
                    state.draft.categories.remove(at: index)
                } else {
                    state.draft.categories.append(name)
                }
                return .none
                
            case let .campaignSelected(name):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                state.draft.campaignNames = trimmed.isEmpty ? [] : [trimmed]
                return .none
                
            case let .campaignToggled(name):
                if let index = state.draft.campaignNames.firstIndex(of: name) {
                    state.draft.campaignNames.remove(at: index)
                } else {
                    state.draft.campaignNames.append(name)
                }
                return .none
                
            case let .addPaymentMethodTapped(rawName, flags):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                
                if let index = state.availablePaymentMethods.firstIndex(where: {
                    $0.name == trimmed
                }) {
                    // 同名時更新付款方式旗標。
                    state.availablePaymentMethods[index] = PaymentMethodInfo(name: trimmed, flags: flags)
                } else {
                    var updated = state.availablePaymentMethods
                    updated.append(PaymentMethodInfo(name: trimmed, flags: flags))
                    state.availablePaymentMethods = updated.sorted {
                        $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }
                }
                state.draft.paymentMethod = trimmed
                return .none
                
            case let .addReconciliationStatusTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                
                if !state.availableReconciliationStatuses.contains(trimmed) {
                    var updated = state.availableReconciliationStatuses
                    updated.append(trimmed)
                    state.availableReconciliationStatuses = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                state.draft.reconciliationStatus = trimmed
                return .none
                
            case .task:
                // 新訂單自動聚焦第一個欄位，既有訂單不搶焦點。
                if state.original == nil,
                   state.focusedField == nil {
                    state.focusedField = .customerName
                }
                
                // 既有訂單的照片依 id 載入
                var pendingPhotoOrderID: LedgerOrder.ID?
                if let original = state.original,
                   state.photoLoadPhase == .notLoaded {
                    state.photoLoadPhase = .loading
                    pendingPhotoOrderID = original.id
                }
                let photoOrderID = pendingPhotoOrderID
                
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let reconciliationStatusRepository = reconciliationStatusRepository
                let campaignRepository = campaignRepository
                let currencyMetadataRepository = currencyMetadataRepository
                let orderRepository = orderRepository
                
                return .run { send in
                    async let orderSourcesTask: Void = {
                        do {
                            let items = try await orderSourceRepository.fetchOrderSources()
                            await send(.availableOrderSourcesLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let categoriesTask: Void = {
                        do {
                            let items = try await categoryRepository.fetchCategories()
                            await send(.availableCategoriesLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let paymentMethodsTask: Void = {
                        do {
                            let infos = try await paymentMethodRepository.fetchPaymentMethodInfos()
                            await send(.availablePaymentMethodsLoaded(infos))
                        } catch {
                            return
                        }
                    }()
                    async let reconciliationStatusesTask: Void = {
                        do {
                            let items =
                            try await reconciliationStatusRepository
                                .fetchReconciliationStatuses()
                            await send(.availableReconciliationStatusesLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let campaignsTask: Void = {
                        do {
                            let items = try await campaignRepository.fetchCampaigns()
                            await send(.availableCampaignsLoaded(items))
                        } catch {
                            return
                        }
                    }()
                    async let currenciesTask: Void = {
                        do {
                            let codes = try await currencyMetadataRepository.fetchCodes()
                            if !codes.isEmpty {
                                await send(.availableCurrenciesLoaded(codes))
                            }
                        } catch {
                            return
                        }
                    }()
                    async let photosTask: Void = {
                        guard let photoOrderID else {
                            return
                        }
                        do {
                            let photos = try await orderRepository.fetchOrderPhotos(photoOrderID)
                            await send(.photosLoaded(photos))
                        } catch {
                            await send(.photosLoadFailed)
                        }
                    }()
                    _ = await (
                        orderSourcesTask, categoriesTask, paymentMethodsTask,
                        reconciliationStatusesTask, campaignsTask, currenciesTask, photosTask
                    )
                }
                
            case let .availableOrderSourcesLoaded(items):
                // 保留表單中剛新增的訂單來源
                var merged = Set(items)
                let trimmedOrderSource = state.draft.orderSource.trimmingCharacters(
                    in: .whitespacesAndNewlines)
                if !trimmedOrderSource.isEmpty {
                    merged.insert(trimmedOrderSource)
                }
                state.availableOrderSources =
                merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none
                
            case let .availableCategoriesLoaded(items):
                // 保留表單中剛新增的商品類別
                var merged = Set(items)
                for draftCategory in state.draft.categories.map({
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }) where !draftCategory.isEmpty {
                    merged.insert(draftCategory)
                }
                state.availableCategories =
                merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none
                
            case let .availablePaymentMethodsLoaded(infos):
                // 依名稱去重，並以主檔的 isCardless 為準
                // 草稿中的新名稱仍補上 isCardless = false
                var merged: [String: PaymentMethodInfo] = [:]
                for info in infos {
                    merged[info.name] = info
                }
                let trimmedPaymentMethod = state.draft.paymentMethod.trimmingCharacters(
                    in: .whitespacesAndNewlines)
                if !trimmedPaymentMethod.isEmpty,
                   merged[trimmedPaymentMethod] == nil {
                    merged[trimmedPaymentMethod] = PaymentMethodInfo(
                        name: trimmedPaymentMethod,
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    )
                }
                state.availablePaymentMethods = merged.values
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                return .none
                
            case let .availableReconciliationStatusesLoaded(items):
                // 保留表單中剛新增的對帳狀態
                var merged = Set(items)
                let trimmedReconciliationStatus = state.draft.reconciliationStatus
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedReconciliationStatus.isEmpty {
                    merged.insert(trimmedReconciliationStatus)
                }
                state.availableReconciliationStatuses =
                merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none
                
            case let .availableCampaignsLoaded(campaigns):
                // 評估結單日狀態後，只顯示仍在收單的開團
                var ongoingNames: [String] = []
                if !campaigns.isEmpty {
                    let now = date.now
                    ongoingNames =
                    campaigns
                        .map { $0.evaluatingAutoClose(asOf: now, calendar: calendar) }
                        .filter { $0.status == .ongoing }
                        .map(\.name)
                }
                var merged = Set(ongoingNames)
                // 合併時保留目前已選的開團。
                for draftCampaign in state.draft.campaignNames.map({
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }) where !draftCampaign.isEmpty {
                    merged.insert(draftCampaign)
                }
                state.availableCampaigns =
                merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none
                
            case let .availableCurrenciesLoaded(codes):
                // 合併時保留目前幣別。
                var merged = Set(codes)
                merged.insert(state.draft.currency)
                state.availableCurrencies =
                merged
                    .sorted {
                        $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending
                    }
                return .none
                
            case let .photosImported(imported):
                // 依剩餘容量截斷照片，匯入後清空選取。
                let appended = imported.prefix(state.remainingPhotoCapacity)
                state.draftPhotos.append(contentsOf: appended)
                state.photoPickerSelection = []
                if !appended.isEmpty {
                    // 使用者確實增刪過照片，儲存時才會走帶照片的專用寫入路徑
                    state.hasEditedPhotos = true
                }
                return .none
                
            case let .deletePhotoTapped(index):
                guard state.draftPhotos.indices.contains(index) else {
                    return .none
                }
                
                state.draftPhotos.remove(at: index)
                state.hasEditedPhotos = true
                return .none
                
            case let .photosLoaded(photos):
                state.draftPhotos = photos
                state.photoLoadPhase = .loaded
                return .none
                
            case .photosLoadFailed:
                state.photoLoadPhase = .failed
                return .none
                
            case .addItemTapped:
                state.draft.items.append(
                    LedgerOrderItem(id: uuid(), name: "", quantity: 1, unitPrice: 0)
                )
                return .none
                
            case let .deleteItems(offsets):
                state.draft.items.remove(atOffsets: offsets)
                return .none
                
            case .orderSourcePickerTapped:
                state.pickerRoute = .orderSource
                return .none
                
            case .categoryPickerTapped:
                state.pickerRoute = .category
                return .none
                
            case .campaignPickerTapped:
                state.pickerRoute = .campaign
                return .none
                
            case .currencyPickerTapped:
                state.pickerRoute = .currency
                return .none
                
            case .paymentMethodPickerTapped:
                state.pickerRoute = .paymentMethod
                return .none
                
            case .reconciliationStatusPickerTapped:
                state.pickerRoute = .reconciliationStatus
                return .none
                
            case let .orderSourceSelected(source):
                state.draft.orderSource = source
                return .none
                
            case let .paymentMethodSelected(method):
                state.draft.paymentMethod = method
                return .none
                
            case let .reconciliationStatusSelected(status):
                state.draft.reconciliationStatus = status
                return .none
                
            case let .currencySelected(code):
                state.draft.currency = CurrencyCode(rawValue: code)
                return .none
                
            case let .photoTapped(index):
                state.pickerRoute = .photoViewer(index: index)
                return .none
            }
        }
        .ifLet(\.$discardConfirmation, action: \.discardConfirmation)
    }
}

// MARK: - Nested Types

extension OrderEditFeature.State {
    
    /// 訂單照片草稿，最多 LedgerOrder.maxPhotoCount 張
    enum PhotoLoadPhase: Equatable {
        
        // MARK: - Cases
        
        /// 尚未觸發載入 (表單開啟瞬間、`.task` 尚未執行)
        case notLoaded
        
        /// 載入中
        case loading
        
        /// 已載入完成
        /// ``OrderEditFeature/State/draftPhotos`` 即為該訂單的實際照片
        case loaded
        
        /// 載入失敗
        case failed
    }
    
    /// 表單中可取得鍵盤焦點的欄位
    enum Field: Hashable {
        
        // MARK: - Cases
        
        /// 客戶名稱
        case customerName
        
        /// 客戶實付
        case chargedAmount
        
        /// 無卡折抵金額
        case cardlessDeduction
        
        /// 無卡補款金額
        case cardlessSupplement
        
        /// 商品成本
        case itemCost
        
        /// 外國國內運費
        case foreignDomesticShipping
        
        /// 國際運費
        case internationalShipping
        
        /// 國內運費
        case domesticShipping
        
        /// 刷卡手續費率
        case cardFeeRate
        
        /// 平台手續費率
        case platformFeeRate
        
        /// 金流手續費率
        case paymentFeeRate
        
        /// 指定商品的名稱
        case itemName(LedgerOrderItem.ID)
        
        /// 指定商品的數量
        case itemQuantity(LedgerOrderItem.ID)
        
        /// 指定商品的單價
        case itemUnitPrice(LedgerOrderItem.ID)
        
        /// 備註
        case notes
    }
    
    /// 訂單編輯表單內可 push 呈現的選項選擇器 route
    enum PickerRoute: Hashable {
        
        // MARK: - Cases
        
        /// 訂單來源選擇器
        case orderSource
        
        /// 商品類別選擇器
        case category
        
        /// 開團選擇器 (合併情境多選)
        case campaign
        
        /// 付款方式選擇器
        case paymentMethod
        
        /// 對帳狀態選擇器
        case reconciliationStatus
        
        /// 幣別選擇器
        case currency
        
        /// 照片檢視器 (以推進呈現，避免在編輯 sheet 上再疊一層 modal)
        case photoViewer(index: Int)
    }
    
}

// MARK: - Internal Method

extension OrderEditFeature.State {
    
    /// 依「無卡折抵金額不得超過客戶實付金額」的不變量收斂目前草稿
    mutating func reconcileCardlessDeductionCap() {
        let cap = maxCardlessDeductionAmount
        if draft.cardlessDeductionAmount > cap {
            draft.cardlessDeductionAmount = cap
            cardlessDeductionWasCapped = true
        } else {
            cardlessDeductionWasCapped = false
        }
    }
}
