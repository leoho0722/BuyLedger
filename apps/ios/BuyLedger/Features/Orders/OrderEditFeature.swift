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
///
/// State 持有原始訂單 (`nil` 視為新訂單) 與各草稿欄位，並維護表單內可即時新增的主檔清單 (訂單來源／商品類別／付款方式／對帳狀態／幣別)。`saveTapped` 與 `cancelTapped` 僅觸發 dismiss；實際寫回資料由父層 ``OrdersFeature`` 攔截 `saveTapped` (`applyEditDraft`) 後持久化
@Reducer
struct OrderEditFeature {

    // MARK: - State

    /// 編輯/新增訂單表單的狀態
    @ObservableState
    struct State: Equatable, Identifiable, @unchecked Sendable {

        /// 原始訂單；`nil` 代表「新訂單」流程
        let original: LedgerOrder?

        /// 客戶名稱草稿
        var draftCustomerName: String

        /// 訂單來源草稿
        var draftOrderSource: String

        /// 商品類別草稿 (至少一個才可儲存)
        ///
        /// 一般訂單編輯為單選、維持單元素陣列；合併情境 (``isMergeContext``) 才開放多選
        var draftCategories: [String]

        /// 訂單狀態草稿
        var draftStatus: OrderStatus

        /// 商品幣別草稿
        var draftCurrency: CurrencyCode

        /// 客戶收款金額草稿 (新台幣)
        var draftChargedAmount: Decimal

        /// 無卡折抵金額草稿 (TWD)
        ///
        /// 僅在 ``isSelectedPaymentMethodCardless`` 為 `true` 時於 UI 顯示；切換到非無卡付款方式時 `applyEditDraft` 會將其歸零，避免資料殘留影響公式
        var draftCardlessDeductionAmount: Decimal

        /// 無卡補款金額草稿 (TWD)
        var draftCardlessSupplementAmount: Decimal

        /// 商品折合 TWD 後的成本草稿
        var draftItemCost: Decimal

        /// 國內運費草稿 (TWD)
        var draftDomesticShipping: Decimal

        /// 國際運費草稿 (TWD)
        var draftInternationalShipping: Decimal

        /// 外國國內運費草稿 (TWD)
        var draftForeignDomesticShipping: Decimal

        /// 刷卡手續費比例草稿 (0–1，例如 0.015 = 1.5%)
        var draftCardFeeRate: Decimal

        /// 平台手續費比例草稿 (0–1，例如 0.03 = 3%)
        var draftPlatformFeeRate: Decimal

        /// 金流手續費比例草稿 (0–1)
        var draftPaymentFeeRate: Decimal

        /// 商品明細草稿；可在編輯表單內新增、刪除、修改
        var draftItems: [LedgerOrderItem]

        /// 訂單備註草稿；對應 ``LedgerOrder/notes``，可在表單中編輯，留空代表無備註
        var draftNotes: String

        /// 訂購日期草稿
        var draftDate: Date

        /// 付款方式草稿
        var draftPaymentMethod: String

        /// 對帳狀態草稿
        ///
        /// 僅在 ``showsVerificationStatusRow`` 為 `true` 時於 UI 顯示與編輯；切換到非無卡／非銀行匯款付款方式時，父層 `applyEditDraft` 會在儲存時清成空字串
        var draftVerificationStatus: String

        /// 歸屬開團名稱草稿；空陣列代表未歸團 (散單)。僅能從 ``availableCampaigns`` 既有開團中選擇，不在此表單內新增開團
        ///
        /// 一般訂單編輯為單選、維持單元素陣列；合併情境 (``isMergeContext``) 才開放多選
        var draftCampaignNames: [String]

        /// 收款狀態草稿 (待收款／已收款)；對所有付款方式皆顯示
        var draftPaymentReceiptStatus: PaymentReceiptStatus

        /// 訂單照片草稿 (已正規化的 JPEG data)；上限 ``LedgerOrder/maxPhotoCount`` 張，由 reducer 在 ``OrderEditFeature/Action/photosImported(_:)`` 截斷守門
        var draftPhotos: [Data]

        /// PhotosPicker 的當前選取項目；one-shot 模式——匯入完成即清空，讓下次開啟 picker 重新選取
        var photoPickerSelection: [PhotosPickerItem] = []

        /// 是否顯示「訂單來源」選擇 sheet
        var showsOrderSourceSheet = false

        /// 是否顯示「商品類別」選擇 sheet
        var showsCategorySheet = false

        /// 是否顯示「付款方式」選擇 sheet
        var showsPaymentMethodSheet = false

        /// 是否顯示「對帳狀態」選擇 sheet
        var showsVerificationStatusSheet = false

        /// 是否顯示「幣別」選擇 sheet
        var showsCurrencySheet = false

        /// 是否顯示「開團」多選 sheet (僅合併情境使用；一般訂單編輯維持 inline `Picker`)
        var showsCampaignSheet = false

        /// 照片檢視器目前聚焦的照片；`nil` 代表檢視器未開啟
        var photoViewerSelection: PhotoViewerSelection?

        /// 合併來源訂單編號；非空代表這是「合併訂單」的確認草稿
        ///
        /// 由 ``OrdersFeature`` 在合併流程建立草稿時填入；儲存時父層據此把舊單轉「已合併」並把這組 id 寫入新訂單的 ``LedgerOrder/mergedSourceIDs``。一般編輯／新增流程一律為空陣列
        var mergeSourceIDs: [LedgerOrder.ID] = []

        /// 可供選擇的訂單來源清單；由父層 reducer 從現有訂單與主檔聚合後注入，並在使用者新增來源時即時擴充
        var availableOrderSources: [String]

        /// 可供選擇的商品類別清單；由父層 reducer 從現有訂單聚合後注入，並在使用者新增類別時即時擴充
        var availableCategories: [String]

        /// 可供選擇的付款方式清單 (含 `isCardless` / `isBankTransfer` 旗標)；由父層 reducer 從現有訂單與主檔聚合後注入，並在使用者新增方式時即時擴充
        var availablePaymentMethods: [PaymentMethodInfo]

        /// 可供選擇的對帳狀態清單；由父層 reducer 從現有訂單與主檔聚合後注入，並在使用者新增狀態時即時擴充
        var availableVerificationStatuses: [String]

        /// 可供選擇的開團清單 (名稱)；由父層 reducer 從現有訂單與開團主檔聚合後注入，供訂單歸團選單使用
        var availableCampaigns: [String]

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供 (首次安裝＋無網路時 fallback 到 ``CurrencyCode/defaults``)
        var availableCurrencies: [CurrencyCode]

        // MARK: - Identifiable Properties

        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用
        let id: UUID

        // MARK: - Init

        /// 依原始訂單建立草稿狀態
        /// - Parameters:
        ///   - original: 要編輯的訂單；`nil` 表示新訂單
        ///   - availableOrderSources: 表單可選用的既有訂單來源；不含原訂單來源時會在初始化時補上
        ///   - availableCategories: 表單可選用的既有類別；不含原訂單類別時會在初始化時補上
        ///   - availablePaymentMethods: 表單可選用的既有付款方式；不含原訂單付款方式時會在初始化時補上 (補上的項目 `isCardless` / `isBankTransfer` 預設為 `false`)
        ///   - availableVerificationStatuses: 表單可選用的既有對帳狀態；不含原訂單對帳狀態時會在初始化時補上
        ///   - currentDate: 新訂單時 ``draftDate`` 的預設值；caller 應從 `@Dependency(\.date)` 取得當下時間以維持可測試性
        init(
            original: LedgerOrder? = nil,
            availableOrderSources: [String] = [],
            availableCategories: [String] = [],
            availablePaymentMethods: [PaymentMethodInfo] = [],
            availableVerificationStatuses: [String] = [],
            availableCampaigns: [String] = [],
            availableCurrencies: [CurrencyCode] = CurrencyCode.defaults,
            currentDate: Date = Date()
        ) {
            self.original = original
            self.draftCustomerName = original?.customer.name ?? ""
            self.draftOrderSource = original?.orderSource ?? ""
            self.draftCategories = original?.categories ?? []
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
            self.draftNotes = original?.notes ?? ""
            self.draftDate = original?.date ?? currentDate
            self.draftPaymentMethod = original?.paymentMethod ?? ""
            self.draftVerificationStatus = original?.verificationStatus ?? ""
            self.draftCampaignNames = original?.campaignNames ?? []
            self.draftPaymentReceiptStatus = original?.paymentReceiptStatus ?? .pending
            self.draftPhotos = original?.photos ?? []

            var orderSources = availableOrderSources
            let originalOrderSource = original?.orderSource.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalOrderSource.isEmpty, !orderSources.contains(originalOrderSource) {
                orderSources.append(originalOrderSource)
            }
            self.availableOrderSources = orderSources.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            var categories = availableCategories
            for originalCategory in (original?.categories ?? []).map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
                if !originalCategory.isEmpty, !categories.contains(originalCategory) {
                    categories.append(originalCategory)
                }
            }
            self.availableCategories = categories.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            var paymentMethods = availablePaymentMethods
            let originalPaymentMethod = original?.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalPaymentMethod.isEmpty,
               !paymentMethods.contains(where: { $0.name == originalPaymentMethod }) {
                // 既有訂單的付款方式可能還沒被加進主檔；補上時旗標預設 false，使用者可在主檔管理頁勾選後再次套用
                paymentMethods.append(PaymentMethodInfo(name: originalPaymentMethod, isCardless: false, isBankTransfer: false, isCashOnDelivery: false))
            }
            self.availablePaymentMethods = paymentMethods.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            var verificationStatuses = availableVerificationStatuses
            let originalVerificationStatus = original?.verificationStatus.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalVerificationStatus.isEmpty, !verificationStatuses.contains(originalVerificationStatus) {
                verificationStatuses.append(originalVerificationStatus)
            }
            self.availableVerificationStatuses = verificationStatuses.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            var campaigns = availableCampaigns
            for originalCampaign in (original?.campaignNames ?? []).map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
                if !originalCampaign.isEmpty, !campaigns.contains(originalCampaign) {
                    campaigns.append(originalCampaign)
                }
            }
            self.availableCampaigns = campaigns.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            var currencies = availableCurrencies
            let originalCurrency = original?.currency ?? .twd
            if !currencies.contains(originalCurrency) {
                currencies.append(originalCurrency)
            }
            self.availableCurrencies = currencies.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }

            self.id = UUID()
        }

        // MARK: - Computed Properties

        /// 目前選到的付款方式是否屬於「無卡」類；用於決定收款金額區段是否顯示「無卡折抵金額」與「無卡補款金額」欄位
        ///
        /// 在 ``availablePaymentMethods`` 中找不到對應名稱時回傳 `false`，避免使用者尚未在主檔標記 isCardless 的情況下意外顯示欄位
        var isSelectedPaymentMethodCardless: Bool {
            let trimmed = draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return availablePaymentMethods.first { $0.name == trimmed }?.isCardless ?? false
        }

        /// 目前選到的付款方式是否屬於「銀行匯款」類；判定方式與 ``isSelectedPaymentMethodCardless`` 相同，只是改看 `isBankTransfer` 旗標
        var isSelectedPaymentMethodBankTransfer: Bool {
            let trimmed = draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return availablePaymentMethods.first { $0.name == trimmed }?.isBankTransfer ?? false
        }

        /// 目前選到的付款方式是否屬於「貨到付款」類；判定方式與 ``isSelectedPaymentMethodCardless`` 相同，只是改看 `isCashOnDelivery` 旗標
        ///
        /// 儲存時由父層 ``OrdersFeature`` 以此值快照寫入 ``LedgerOrder/isCashOnDelivery``，讓 ``OrderSummary`` 能在獲利中扣除三種運費
        var isSelectedPaymentMethodCOD: Bool {
            let trimmed = draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return availablePaymentMethods.first { $0.name == trimmed }?.isCashOnDelivery ?? false
        }

        /// 是否在「付款方式」row 底下顯示「對帳狀態」row：選到的付款方式屬於無卡或銀行匯款 (款項不會即時入帳、需事後人工對帳) 時為 `true`
        var showsVerificationStatusRow: Bool {
            isSelectedPaymentMethodCardless || isSelectedPaymentMethodBankTransfer
        }

        /// 是否處於合併情境：本草稿是合併確認草稿 (``mergeSourceIDs`` 非空)，或正在編輯由合併產生的訂單
        ///
        /// 類別與開團僅在此情境改用多選 picker；一般訂單編輯維持單選體驗
        var isMergeContext: Bool {
            !mergeSourceIDs.isEmpty || !(original?.mergedSourceIDs.isEmpty ?? true)
        }

        /// 狀態 Picker 的可選清單
        ///
        /// 「已合併」只能由合併流程寫入，不開放手動選擇；僅當目前狀態已是「已合併」時保留該選項 (顯示現值，並作為誤合併後把舊單改回其他狀態的手動回復路徑)
        var availableStatuses: [OrderStatus] {
            OrderStatus.allCases.filter { $0 != .merged || draftStatus == .merged }
        }

        /// 類別 trigger row 的顯示文字：以「、」串接已選類別；未選任何類別時為空字串 (由 view 顯示 placeholder)
        var categoriesDisplayText: String {
            draftCategories.joined(separator: "、")
        }

        /// 開團 trigger row 的顯示文字：以「、」串接已選開團；未選任何開團時顯示「未歸團」
        var campaignsDisplayText: String {
            draftCampaignNames.isEmpty ? "未歸團" : draftCampaignNames.joined(separator: "、")
        }

        /// 還可加入的照片張數；供 PhotosPicker 的 `maxSelectionCount` 與計數標籤使用
        var remainingPhotoCapacity: Int {
            max(0, LedgerOrder.maxPhotoCount - draftPhotos.count)
        }

        /// 是否還能加入照片 (尚未達 ``LedgerOrder/maxPhotoCount`` 上限)；上限已滿時編輯表單隱藏加入按鈕
        var canAddMorePhotos: Bool {
            remainingPhotoCapacity > 0
        }
    }

    // MARK: - Action

    /// 表單可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件
        case binding(BindingAction<State>)

        /// 日期選擇器寫回新值：reducer 以注入時間補上當下秒數後寫入 ``State/draftDate``
        case dateComponentsChanged(Date)

        /// 使用者按下取消
        case cancelTapped

        /// 使用者按下儲存
        case saveTapped

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

        /// 使用者透過「新增付款方式」sheet 確認新增一筆付款方式，含「是否為無卡類」「是否為銀行匯款類」與「是否為貨到付款類」旗標
        case addPaymentMethodTapped(name: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool)

        /// 使用者透過「新增對帳狀態」sheet 確認新增一筆對帳狀態名稱
        case addVerificationStatusTapped(String)

        /// 表單畫面 `.task` 觸發；用於從 repo 重新拉取最新的訂單來源／類別／付款方式／對帳狀態／開團主檔
        case task

        /// 從 ``OrderSourceRepository`` 取回最新訂單來源主檔
        case availableOrderSourcesLoaded([String])

        /// 從 ``CategoryRepository`` 取回最新類別主檔
        case availableCategoriesLoaded([String])

        /// 從 ``PaymentMethodRepository`` 取回最新付款方式主檔 (含 `isCardless` / `isBankTransfer`)
        case availablePaymentMethodsLoaded([PaymentMethodInfo])

        /// 從 ``VerificationStatusRepository`` 取回最新對帳狀態主檔
        case availableVerificationStatusesLoaded([String])

        /// 從 ``CampaignRepository`` 取回最新開團主檔；handler 只取開團中 (``CampaignStatus/ongoing``) 的名稱填入選單
        case availableCampaignsLoaded([Campaign])

        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔
        case availableCurrenciesLoaded([CurrencyCode])

        /// PhotosPicker 選取項目經 ``PhotoClient`` 載入與正規化完成
        case photosImported([Data])

        /// 使用者點擊縮圖的刪除鈕，移除指定 index 的草稿照片
        case deletePhotoTapped(Int)

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
        case verificationStatusPickerTapped

        /// 使用者在 sheet 選定訂單來源
        case orderSourceSelected(String)

        /// 使用者在 sheet 選定付款方式
        case paymentMethodSelected(String)

        /// 使用者在 sheet 選定對帳狀態
        case verificationStatusSelected(String)

        /// 使用者在 sheet 選定幣別 (以 ISO 4217 code 傳入)
        case currencySelected(String)

        /// 使用者點擊縮圖，開啟指定 index 的照片檢視器
        case photoTapped(Int)

        /// 使用者關閉照片檢視器
        case photoViewerDismissed
    }

    // MARK: - Dependency Properties

    /// 由父層注入的 dismiss effect
    @Dependency(\.dismiss) private var dismiss

    /// 「現在」時間；日期選擇器寫回時用來補上當下秒數，測試可注入固定值
    @Dependency(\.date) private var date

    /// 產生新商品明細列的 id；測試可注入固定值以維持可測試性
    @Dependency(\.uuid) private var uuid

    /// 訂單來源主檔資料來源；用於 sheet `.task` 重新拉取，使「在其他訂單新增的來源」也能立即出現在編輯選單
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository

    /// 商品類別主檔資料來源；用於 sheet `.task` 重新拉取，使「在管理頁新增的類別」也能立即出現在編輯選單
    @Dependency(CategoryRepository.self) private var categoryRepository

    /// 付款方式主檔資料來源；理由同 ``categoryRepository``
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

    /// 對帳狀態主檔資料來源；理由同 ``categoryRepository``
    @Dependency(VerificationStatusRepository.self) private var verificationStatusRepository

    /// 開團主檔資料來源；用於 sheet `.task` 自行載入開團，讓任一入口 (含 Dashboard 直接開新訂單) 的選單都拿得到開團中的開團，不必依賴 caller 傳入
    @Dependency(CampaignRepository.self) private var campaignRepository

    /// 幣別主檔資料來源；用於 sheet `.task` 從 cache 拉最新清單 (cache 由 ``RootFeature`` 啟動時 TTL 7 天刷新)
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    /// 照片匯入管線；把 PhotosPicker 選取項目載入並正規化為可持久化的 JPEG data
    @Dependency(PhotoClient.self) private var photoClient

    // MARK: - Reducer Body

    /// 表單 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
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

            case .binding:
                return .none

            case let .dateComponentsChanged(newValue):
                // 把 picker 寫回的年月日時分，與「當下這一刻」的秒合併寫入 draftDate
                // 採固定 gregorian + UTC 曆：時區只影響年月日時的對應、不影響「秒」數值，
                // 故在 UTC 下抽秒/改秒/組回與本地時區一致；當下時間走注入的 date 以維持可測試
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

                let currentSeconds = calendar.component(.second, from: date.now)
                var components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: newValue
                )
                components.second = currentSeconds
                state.draftDate = calendar.date(from: components) ?? newValue
                return .none

            case .cancelTapped, .saveTapped:
                return .run { _ in await dismiss() }

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
                state.draftOrderSource = trimmed
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
                    if !state.draftCategories.contains(trimmed) {
                        state.draftCategories.append(trimmed)
                    }
                } else {
                    state.draftCategories = [trimmed]
                }
                return .none

            case let .categorySelected(name):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }

                state.draftCategories = [trimmed]
                return .none

            case let .categoryToggled(name):
                if let index = state.draftCategories.firstIndex(of: name) {
                    state.draftCategories.remove(at: index)
                } else {
                    state.draftCategories.append(name)
                }
                return .none

            case let .campaignSelected(name):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                state.draftCampaignNames = trimmed.isEmpty ? [] : [trimmed]
                return .none

            case let .campaignToggled(name):
                if let index = state.draftCampaignNames.firstIndex(of: name) {
                    state.draftCampaignNames.remove(at: index)
                } else {
                    state.draftCampaignNames.append(name)
                }
                return .none

            case let .addPaymentMethodTapped(rawName, isCardless, isBankTransfer, isCashOnDelivery):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }

                if let index = state.availablePaymentMethods.firstIndex(where: { $0.name == trimmed }) {
                    // 同名情境視為「重新套用旗標」：例如使用者上次新增時忘了勾選無卡／銀行匯款／貨到付款，這次重新觸發以更正
                    state.availablePaymentMethods[index] = PaymentMethodInfo(name: trimmed, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery)
                } else {
                    var updated = state.availablePaymentMethods
                    updated.append(PaymentMethodInfo(name: trimmed, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery))
                    state.availablePaymentMethods = updated.sorted {
                        $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }
                }
                state.draftPaymentMethod = trimmed
                return .none

            case let .addVerificationStatusTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }

                if !state.availableVerificationStatuses.contains(trimmed) {
                    var updated = state.availableVerificationStatuses
                    updated.append(trimmed)
                    state.availableVerificationStatuses = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                state.draftVerificationStatus = trimmed
                return .none

            case .task:
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let verificationStatusRepository = verificationStatusRepository
                let campaignRepository = campaignRepository
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
                    async let verificationStatusesTask: Void = {
                        if let items = try? await verificationStatusRepository.fetchVerificationStatuses() {
                            await send(.availableVerificationStatusesLoaded(items))
                        }
                    }()
                    async let campaignsTask: Void = {
                        if let items = try? await campaignRepository.fetchCampaigns() {
                            await send(.availableCampaignsLoaded(items))
                        }
                    }()
                    async let currenciesTask: Void = {
                        if let codes = try? await currencyMetadataRepository.fetchCodes(), !codes.isEmpty {
                            await send(.availableCurrenciesLoaded(codes))
                        }
                    }()
                    _ = await (orderSourcesTask, categoriesTask, paymentMethodsTask, verificationStatusesTask, campaignsTask, currenciesTask)
                }

            case let .availableOrderSourcesLoaded(items):
                // 合併：把目前 draftOrderSource (可能是剛在 sheet 內新增、尚未走完整 add → repo 來回) 保留在清單
                var merged = Set(items)
                let draftOrderSource = state.draftOrderSource.trimmingCharacters(in: .whitespacesAndNewlines)
                if !draftOrderSource.isEmpty {
                    merged.insert(draftOrderSource)
                }
                state.availableOrderSources = merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none

            case let .availableCategoriesLoaded(items):
                // 合併：把目前 draftCategories (可能含剛在 sheet 內新增、尚未走完整 add → repo 來回的項目) 保留在清單
                var merged = Set(items)
                for draftCategory in state.draftCategories.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !draftCategory.isEmpty {
                    merged.insert(draftCategory)
                }
                state.availableCategories = merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none

            case let .availablePaymentMethodsLoaded(infos):
                // 以名稱去重後合併：主檔內的 isCardless 取代舊值 (讓使用者在管理頁切換 toggle 後 sheet 立刻看得到)；
                // 但若 draftPaymentMethod 是還沒寫進主檔的暫存字串，仍補一筆 isCardless == false 維持原本顯示
                var merged: [String: PaymentMethodInfo] = [:]
                for info in infos {
                    merged[info.name] = info
                }
                let draftPaymentMethod = state.draftPaymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
                if !draftPaymentMethod.isEmpty, merged[draftPaymentMethod] == nil {
                    merged[draftPaymentMethod] = PaymentMethodInfo(
                        name: draftPaymentMethod,
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    )
                }
                state.availablePaymentMethods = merged.values
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                return .none

            case let .availableVerificationStatusesLoaded(items):
                // 合併：把目前 draftVerificationStatus (可能是剛在 sheet 內新增、尚未走完整 add → repo 來回) 保留在清單
                var merged = Set(items)
                let draftVerificationStatus = state.draftVerificationStatus.trimmingCharacters(in: .whitespacesAndNewlines)
                if !draftVerificationStatus.isEmpty {
                    merged.insert(draftVerificationStatus)
                }
                state.availableVerificationStatuses = merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none

            case let .availableCampaignsLoaded(campaigns):
                // 只取開團中 (ongoing) 的開團名稱填入選單，避免項目過長；已收單的開團不列入
                // 合併目前 draftCampaignNames (正在編輯訂單已歸屬的已收單開團、或合併情境的多選來源) 保留在清單，避免既有歸屬選項消失
                var merged = Set(campaigns.filter { $0.status == .ongoing }.map(\.name))
                for draftCampaign in state.draftCampaignNames.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !draftCampaign.isEmpty {
                    merged.insert(draftCampaign)
                }
                state.availableCampaigns = merged
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                return .none

            case let .availableCurrenciesLoaded(codes):
                // 合併：把目前 draftCurrency 保留在清單，避免下拉看不到原訂單已使用的幣別
                var merged = Set(codes)
                merged.insert(state.draftCurrency)
                state.availableCurrencies = merged
                    .sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
                return .none

            case let .photosImported(imported):
                // 以剩餘容量截斷，無論 picker 回傳幾張都不超過上限；匯入完成即清空選取 (one-shot)
                state.draftPhotos.append(contentsOf: imported.prefix(state.remainingPhotoCapacity))
                state.photoPickerSelection = []
                return .none

            case let .deletePhotoTapped(index):
                guard state.draftPhotos.indices.contains(index) else {
                    return .none
                }

                state.draftPhotos.remove(at: index)
                return .none

            case .addItemTapped:
                state.draftItems.append(
                    LedgerOrderItem(id: uuid(), name: "", quantity: 1, unitPrice: 0)
                )
                return .none

            case let .deleteItems(offsets):
                state.draftItems.remove(atOffsets: offsets)
                return .none

            case .orderSourcePickerTapped:
                state.showsOrderSourceSheet = true
                return .none

            case .categoryPickerTapped:
                state.showsCategorySheet = true
                return .none

            case .campaignPickerTapped:
                state.showsCampaignSheet = true
                return .none

            case .currencyPickerTapped:
                state.showsCurrencySheet = true
                return .none

            case .paymentMethodPickerTapped:
                state.showsPaymentMethodSheet = true
                return .none

            case .verificationStatusPickerTapped:
                state.showsVerificationStatusSheet = true
                return .none

            case let .orderSourceSelected(source):
                state.draftOrderSource = source
                return .none

            case let .paymentMethodSelected(method):
                state.draftPaymentMethod = method
                return .none

            case let .verificationStatusSelected(status):
                state.draftVerificationStatus = status
                return .none

            case let .currencySelected(code):
                state.draftCurrency = CurrencyCode(rawValue: code)
                return .none

            case let .photoTapped(index):
                state.photoViewerSelection = PhotoViewerSelection(id: index)
                return .none

            case .photoViewerDismissed:
                state.photoViewerSelection = nil
                return .none
            }
        }
    }
}

// MARK: - Nested Types

extension OrderEditFeature {

    /// 照片檢視器的開啟狀態：以被點擊照片的 index 作為 sheet item 的識別值
    struct PhotoViewerSelection: Identifiable, Equatable {

        // MARK: - Identifiable Properties

        /// 被點擊照片在 ``OrderEditFeature/State/draftPhotos`` 中的 index，同時作為 item 識別
        let id: Int
    }
}
