//
//  OrderEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 編輯或新增訂單表單的功能。
///
/// 本切片僅建立 sheet 流程骨架：state 持有原始訂單 (`nil` 視為新訂單) 與草稿欄位，`saveTapped` 與 `cancelTapped` 都僅觸發 dismiss，不寫回資料。實際的儲存邏輯會在後續切片補上。
@Reducer
struct OrderEditFeature {

    // MARK: - State

    /// 編輯/新增訂單表單的狀態。
    @ObservableState
    struct State: Equatable, Identifiable, @unchecked Sendable {

        /// 原始訂單；`nil` 代表「新訂單」流程。
        let original: LedgerOrder?

        /// 客戶名稱草稿。
        var draftCustomerName: String

        /// 訂單來源草稿。
        var draftOrderSource: String

        /// 商品類別草稿。
        var draftCategory: String

        /// 訂單狀態草稿。
        var draftStatus: OrderStatus

        /// 商品幣別草稿。
        var draftCurrency: CurrencyCode

        /// 客戶收款金額草稿 (新台幣)。
        var draftChargedAmount: Decimal

        /// 無卡折抵金額草稿 (TWD)。
        ///
        /// 僅在 ``isSelectedPaymentMethodCardless`` 為 `true` 時於 UI 顯示；切換到非無卡付款方式時 `applyEditDraft` 會將其歸零，避免資料殘留影響公式。
        var draftCardlessDeductionAmount: Decimal

        /// 無卡補款金額草稿 (TWD)。
        var draftCardlessSupplementAmount: Decimal

        /// 商品折合 TWD 後的成本草稿。
        var draftItemCost: Decimal

        /// 國內運費草稿 (TWD)。
        var draftDomesticShipping: Decimal

        /// 國際運費草稿 (TWD)。
        var draftInternationalShipping: Decimal

        /// 外國國內運費草稿 (TWD)。
        var draftForeignDomesticShipping: Decimal

        /// 刷卡手續費比例草稿 (0–1，例如 0.015 = 1.5%)。
        var draftCardFeeRate: Decimal

        /// 平台手續費比例草稿 (0–1，例如 0.03 = 3%)。
        var draftPlatformFeeRate: Decimal

        /// 金流手續費比例草稿 (0–1)。
        var draftPaymentFeeRate: Decimal

        /// 商品明細草稿；可在編輯表單內新增、刪除、修改。
        var draftItems: [LedgerOrderItem]

        /// 訂購日期草稿。
        var draftDate: Date

        /// 付款方式草稿。
        var draftPaymentMethod: String

        /// 可供選擇的訂單來源清單；由父層 reducer 從現有訂單與主檔聚合後注入，並在使用者新增來源時即時擴充。
        var availableOrderSources: [String]

        /// 可供選擇的商品類別清單；由父層 reducer 從現有訂單聚合後注入，並在使用者新增類別時即時擴充。
        var availableCategories: [String]

        /// 可供選擇的付款方式清單 (含 `isCardless` 旗標)；由父層 reducer 從現有訂單與主檔聚合後注入，並在使用者新增方式時即時擴充。
        var availablePaymentMethods: [PaymentMethodInfo]

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供 (首次安裝＋無網路時 fallback 到 ``CurrencyCode/defaults``)。
        var availableCurrencies: [CurrencyCode]

        // MARK: - Identifiable Properties

        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用。
        let id: UUID

        // MARK: - Computed Properties

        /// 目前選到的付款方式是否屬於「無卡」類；用於決定收款金額區段是否顯示「無卡折抵金額」與「無卡補款金額」欄位。
        ///
        /// 在 ``availablePaymentMethods`` 中找不到對應名稱時回傳 `false`，避免使用者尚未在主檔標記 isCardless 的情況下意外顯示欄位。
        var isSelectedPaymentMethodCardless: Bool {
            let trimmed = draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }
            return availablePaymentMethods.first { $0.name == trimmed }?.isCardless ?? false
        }

        // MARK: - Init

        /// 依原始訂單建立草稿狀態。
        /// - Parameters:
        ///   - original: 要編輯的訂單；`nil` 表示新訂單。
        ///   - availableOrderSources: 表單可選用的既有訂單來源；不含原訂單來源時會在初始化時補上。
        ///   - availableCategories: 表單可選用的既有類別；不含原訂單類別時會在初始化時補上。
        ///   - availablePaymentMethods: 表單可選用的既有付款方式；不含原訂單付款方式時會在初始化時補上 (補上的項目 `isCardless` 預設為 `false`)。
        ///   - currentDate: 新訂單時 ``draftDate`` 的預設值；caller 應從 `@Dependency(\.date)` 取得當下時間以維持可測試性。
        init(
            original: LedgerOrder? = nil,
            availableOrderSources: [String] = [],
            availableCategories: [String] = [],
            availablePaymentMethods: [PaymentMethodInfo] = [],
            availableCurrencies: [CurrencyCode] = CurrencyCode.defaults,
            currentDate: Date = Date()
        ) {
            self.original = original
            self.draftCustomerName = original?.customer.name ?? ""
            self.draftOrderSource = original?.orderSource ?? ""
            self.draftCategory = original?.category ?? ""
            self.draftStatus = original?.status ?? .quoting
            self.draftCurrency = original?.currency ?? .twd
            self.draftChargedAmount = original?.chargedAmount ?? 0
            self.draftCardlessDeductionAmount = original?.cardlessDeductionAmount ?? 0
            self.draftCardlessSupplementAmount = original?.cardlessSupplementAmount ?? 0
            self.draftItemCost = original?.itemCost ?? 0
            self.draftDomesticShipping = original?.domesticShipping ?? 0
            self.draftInternationalShipping = original?.internationalShipping ?? 0
            self.draftForeignDomesticShipping = original?.foreignDomesticShipping ?? 0
            self.draftCardFeeRate = original?.cardFeeRate ?? 0
            self.draftPlatformFeeRate = original?.platformFeeRate ?? 0
            self.draftPaymentFeeRate = original?.paymentFeeRate ?? 0
            self.draftItems = original?.items ?? []
            self.draftDate = original?.date ?? currentDate
            self.draftPaymentMethod = original?.paymentMethod ?? ""

            var orderSources = availableOrderSources
            let originalOrderSource = original?.orderSource.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalOrderSource.isEmpty, !orderSources.contains(originalOrderSource) {
                orderSources.append(originalOrderSource)
            }
            self.availableOrderSources = orderSources.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            var categories = availableCategories
            let originalCategory = original?.category.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalCategory.isEmpty, !categories.contains(originalCategory) {
                categories.append(originalCategory)
            }
            self.availableCategories = categories.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            var paymentMethods = availablePaymentMethods
            let originalPaymentMethod = original?.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalPaymentMethod.isEmpty,
               !paymentMethods.contains(where: { $0.name == originalPaymentMethod }) {
                // 既有訂單的付款方式可能還沒被加進主檔；補上時 isCardless 預設 false，使用者可在主檔管理頁勾選後再次套用。
                paymentMethods.append(PaymentMethodInfo(name: originalPaymentMethod, isCardless: false))
            }
            self.availablePaymentMethods = paymentMethods.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            var currencies = availableCurrencies
            let originalCurrency = original?.currency ?? .twd
            if !currencies.contains(originalCurrency) {
                currencies.append(originalCurrency)
            }
            self.availableCurrencies = currencies.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }

            self.id = UUID()
        }
    }

    // MARK: - Action

    /// 表單可處理的事件。
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件。
        case binding(BindingAction<State>)

        /// 使用者按下取消。
        case cancelTapped

        /// 使用者按下儲存。
        case saveTapped

        /// 使用者透過「新增來源」彈窗確認新增一筆訂單來源名稱。
        case addOrderSourceTapped(String)

        /// 使用者透過「新增類別」彈窗確認新增一筆類別名稱。
        case addCategoryTapped(String)

        /// 使用者透過「新增付款方式」sheet 確認新增一筆付款方式，含「是否為無卡類」旗標。
        case addPaymentMethodTapped(name: String, isCardless: Bool)

        /// 表單畫面 `.task` 觸發；用於從 repo 重新拉取最新的訂單來源／類別／付款方式主檔。
        case task

        /// 從 ``OrderSourceRepository`` 取回最新訂單來源主檔。
        case availableOrderSourcesLoaded([String])

        /// 從 ``CategoryRepository`` 取回最新類別主檔。
        case availableCategoriesLoaded([String])

        /// 從 ``PaymentMethodRepository`` 取回最新付款方式主檔 (含 `isCardless`)。
        case availablePaymentMethodsLoaded([PaymentMethodInfo])

        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔。
        case availableCurrenciesLoaded([CurrencyCode])
    }

    // MARK: - Dependency Properties

    /// 由父層注入的 dismiss effect。
    @Dependency(\.dismiss) private var dismiss

    /// 訂單來源主檔資料來源；用於 sheet `.task` 重新拉取，使「在其他訂單新增的來源」也能立即出現在編輯選單。
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository

    /// 商品類別主檔資料來源；用於 sheet `.task` 重新拉取，使「在管理頁新增的類別」也能立即出現在編輯選單。
    @Dependency(CategoryRepository.self) private var categoryRepository

    /// 付款方式主檔資料來源；理由同 ``categoryRepository``。
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

    /// 幣別主檔資料來源；用於 sheet `.task` 從 cache 拉最新清單 (cache 由 ``RootFeature`` 啟動時 TTL 7 天刷新)。
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Reducer Body

    /// 表單 reducer。
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .cancelTapped, .saveTapped:
                return .run { _ in await dismiss() }

            case let .addOrderSourceTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                if !state.availableOrderSources.contains(trimmed) {
                    var updated = state.availableOrderSources
                    updated.append(trimmed)
                    state.availableOrderSources = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                state.draftOrderSource = trimmed
                return .none

            case let .addCategoryTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                if !state.availableCategories.contains(trimmed) {
                    var updated = state.availableCategories
                    updated.append(trimmed)
                    state.availableCategories = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                state.draftCategory = trimmed
                return .none

            case let .addPaymentMethodTapped(rawName, isCardless):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                if let index = state.availablePaymentMethods.firstIndex(where: { $0.name == trimmed }) {
                    // 同名情境視為「重新套用 isCardless 旗標」：例如使用者上次新增時忘了勾選無卡，這次重新觸發以更正。
                    state.availablePaymentMethods[index] = PaymentMethodInfo(name: trimmed, isCardless: isCardless)
                } else {
                    var updated = state.availablePaymentMethods
                    updated.append(PaymentMethodInfo(name: trimmed, isCardless: isCardless))
                    state.availablePaymentMethods = updated.sorted {
                        $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }
                }
                state.draftPaymentMethod = trimmed
                return .none

            case .task:
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let currencyMetadataRepository = currencyMetadataRepository
                return .run { send in
                    async let orderSourcesTask: Void = {
                        if let items = try? await orderSourceRepository.fetchOrderSources() {
                            await send(.availableOrderSourcesLoaded(items))
                        }
                    }()
                    async let categoriesTask: Void = {
                        if let items = try? await categoryRepository.fetchCategories() {
                            await send(.availableCategoriesLoaded(items))
                        }
                    }()
                    async let paymentMethodsTask: Void = {
                        if let infos = try? await paymentMethodRepository.fetchPaymentMethodInfos() {
                            await send(.availablePaymentMethodsLoaded(infos))
                        }
                    }()
                    async let currenciesTask: Void = {
                        if let codes = try? await currencyMetadataRepository.fetchCodes(), !codes.isEmpty {
                            await send(.availableCurrenciesLoaded(codes))
                        }
                    }()
                    _ = await (orderSourcesTask, categoriesTask, paymentMethodsTask, currenciesTask)
                }

            case let .availableOrderSourcesLoaded(items):
                // 合併：把目前 draftOrderSource (可能是剛在 sheet 內新增、尚未走完整 add → repo 來回) 保留在清單。
                var merged = Set(items)
                let draftOrderSource = state.draftOrderSource.trimmingCharacters(in: .whitespacesAndNewlines)
                if !draftOrderSource.isEmpty {
                    merged.insert(draftOrderSource)
                }
                state.availableOrderSources = merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none

            case let .availableCategoriesLoaded(items):
                // 合併：把目前 draftCategory (可能是剛在 sheet 內新增、尚未走完整 add → repo 來回) 保留在清單。
                var merged = Set(items)
                let draftCategory = state.draftCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                if !draftCategory.isEmpty {
                    merged.insert(draftCategory)
                }
                state.availableCategories = merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none

            case let .availablePaymentMethodsLoaded(infos):
                // 以名稱去重後合併：主檔內的 isCardless 取代舊值 (讓使用者在管理頁切換 toggle 後 sheet 立刻看得到)；
                // 但若 draftPaymentMethod 是還沒寫進主檔的暫存字串，仍補一筆 isCardless == false 維持原本顯示。
                var merged: [String: PaymentMethodInfo] = [:]
                for info in infos {
                    merged[info.name] = info
                }
                let draftPaymentMethod = state.draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
                if !draftPaymentMethod.isEmpty, merged[draftPaymentMethod] == nil {
                    merged[draftPaymentMethod] = PaymentMethodInfo(name: draftPaymentMethod, isCardless: false)
                }
                state.availablePaymentMethods = merged.values
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                return .none

            case let .availableCurrenciesLoaded(codes):
                // 合併：把目前 draftCurrency 保留在清單，避免下拉看不到原訂單已使用的幣別。
                var merged = Set(codes)
                merged.insert(state.draftCurrency)
                state.availableCurrencies = merged
                    .sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
                return .none
            }
        }
    }
}
