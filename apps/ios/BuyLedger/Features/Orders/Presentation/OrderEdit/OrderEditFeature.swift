//
//  OrderEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 編輯或新增訂單表單的功能
@Reducer
struct OrderEditFeature {

    // MARK: - State

    /// 新增或編輯訂單時的草稿、焦點與子功能狀態
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {

        /// 原始訂單；`nil` 代表「新訂單」流程
        let original: LedgerOrder?

        /// 表單草稿；只保留未儲存變更需要比較的欄位
        var draft: OrderDraft

        /// 是否剛將無卡折抵金額調整到上限
        var isCardlessDeductionCapped: Bool = false

        /// 照片草稿與編輯狀態；既有訂單的照片在區段出現時讀取
        var photos: OrderEditPhotosFeature.State

        /// 捨棄未儲存變更的確認彈窗
        @Presents var discardConfirmation: AlertState<Action.DiscardAlert>? = nil

        /// 目前取得鍵盤焦點的欄位；`nil` 代表無焦點
        var focusedField: Field?

        /// 合併來源訂單編號；非空代表這是「合併訂單」的確認草稿
        var mergeSourceIDs: [LedgerOrder.ID] = []

        /// 正規化後的選項與選擇器的推入路由
        var pickers: OrderEditPickersFeature.State

        /// 本次開啟表單的識別值，與訂單編號無關
        let id: UUID

        /// 表單開啟時夾限後的草稿，供判斷未儲存變更
        let initialDraft: OrderDraft

        /// 表單建立時的行事曆，供完整時間格式化使用
        let calendar: Calendar

        /// 依原始訂單是否存在提供標題的本地化鍵
        var navigationTitleKey: String {
            original == nil ? "orders.list.label.newOrder" : "orders.detail.label.editOrder"
        }

        /// 客戶實付金額的繫結入口，修改時重新檢查折抵上限
        var chargedAmount: Decimal {
            get {
                draft.chargedAmount
            }
            set {
                draft.chargedAmount = newValue
            }
        }

        /// 無卡折抵金額的繫結入口，修改時重新檢查上限
        var cardlessDeductionAmount: Decimal {
            get {
                draft.cardlessDeductionAmount
            }
            set {
                draft.cardlessDeductionAmount = newValue
            }
        }

        /// 目前聚焦的欄位是否使用數字鍵盤
        var isNumericFieldFocused: Bool {
            OrderEditDraftOperations.isNumericFieldFocused(focusedField)
        }

        /// 顧客名稱、訂單來源與至少一個商品類別是否皆已填寫
        var canSave: Bool {
            OrderEditDraftOperations.canSave(draft: draft)
        }

        /// 草稿或照片有未儲存變更
        var isDirty: Bool {
            draft != initialDraft || photos.hasEditedPhotos
        }

        /// 目前付款方式是否為無卡類
        var isSelectedPaymentMethodCardless: Bool {
            OrderEditDraftOperations.selectedPaymentMethod(state: self)?.isCardless ?? false
        }

        /// 目前付款方式是否為銀行匯款
        var isSelectedPaymentMethodBankTransfer: Bool {
            OrderEditDraftOperations.selectedPaymentMethod(state: self)?.isBankTransfer ?? false
        }

        /// 目前付款方式是否為貨到付款
        var isSelectedPaymentMethodCOD: Bool {
            OrderEditDraftOperations.selectedPaymentMethod(state: self)?.isCashOnDelivery ?? false
        }

        /// 是否顯示對帳狀態列
        var shouldShowReconciliationStatusRow: Bool {
            isSelectedPaymentMethodCardless || isSelectedPaymentMethodBankTransfer
        }

        /// 是否處於合併情境
        var isMergeContext: Bool {
            !mergeSourceIDs.isEmpty || !(original?.mergedSourceIDs.isEmpty ?? true)
        }

        /// 表單可選的訂單狀態；草稿為合併狀態時才包含該選項
        var availableStatuses: [OrderStatus] {
            OrderStatusRules.selectableStatuses(for: draft.status)
        }

        /// 開團選擇列的本地化值；未選時使用「未歸團」的既有本地化鍵
        var campaignsDisplayText: LocalizedStringResource {
            draft.campaignNames.isEmpty
                ? "orders.detail.label.unassigned"
                : "\(OrderFormatters.campaignsDisplayText(draft.campaignNames))"
        }

        /// 依原始訂單與父層帶入的選項建立草稿狀態
        ///
        /// - Parameters:
        ///   - original: 要編輯的訂單；`nil` 表示新訂單
        ///   - id: 表單識別值
        ///   - options: 父層已建立的選項與注入行事曆
        ///   - currentDate: 新訂單的預設日期
        ///   - defaultCurrency: 新訂單的預設幣別；既有訂單與合併預填沿用原幣別
        ///   - prefill: 合併確認開啟時帶入的草稿、來源編號與保留照片
        init(
            original: LedgerOrder? = nil,
            id: UUID,
            options: OrderEditOptions = .empty,
            currentDate: Date,
            defaultCurrency: CurrencyCode = .twd,
            prefill: Prefill? = nil
        ) {
            self.original = original
            let prepared = OrderEditDraftOperations.prepareDraft(
                original: original,
                currentDate: currentDate,
                defaultCurrency: defaultCurrency,
                prefill: prefill
            )
            self.draft = prepared.draft
            self.initialDraft = prepared.draft
            self.isCardlessDeductionCapped = prepared.isCardlessDeductionCapped
            self.photos = OrderEditDraftOperations.photos(original: original, prefill: prefill)
            self.mergeSourceIDs = prefill?.mergeSourceIDs ?? []
            self.calendar = options.calendar
            self.pickers = OrderEditPickersFeature.State(options: options, draft: prepared.draft)
            self.id = id
        }

        /// 合併確認表單開啟時的初始資料
        struct Prefill: Equatable, Sendable {

            /// 合併後的表單草稿
            let draft: OrderDraft

            /// 合併來源訂單編號，主訂單在前
            let mergeSourceIDs: [LedgerOrder.ID]

            /// 使用者選擇保留的照片
            let keptPhotos: [Data]
        }

        /// 表單中可取得鍵盤焦點的欄位
        enum Field: Hashable {

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
            ///
            /// - Parameter id: 商品明細的識別碼
            case itemName(LedgerOrderItem.ID)

            /// 指定商品的單價
            ///
            /// - Parameter id: 商品明細的識別碼
            case itemUnitPrice(LedgerOrderItem.ID)

            /// 備註
            case notes
        }

        /// 將已落盤的主檔項目加入清單並選取
        ///
        /// - Parameter request: 已成功寫入的主檔新增請求
        mutating func applyAddedOption(_ request: LookupAdditionRequest) {
            OrderEditDraftOperations.applyAddition(request, state: &self)
        }
    }

    // MARK: - Action

    /// 表單可處理的事件
    enum Action: BindableAction {

        /// `SwiftUI` 雙向繫結事件
        ///
        /// - Parameter action: 被修改的繫結欄位與新值
        case binding(BindingAction<State>)

        /// 使用者在表單上的操作
        ///
        /// - Parameter action: 畫面送出的表單事件
        case view(View)

        /// 交給父層處理的表單請求
        ///
        /// - Parameter action: 通過驗證後交給父層的請求
        case delegate(Delegate)

        /// 取消編輯時的捨棄確認彈窗事件
        ///
        /// - Parameter action: 彈窗的呈現或操作事件
        case discardConfirmation(PresentationAction<DiscardAlert>)

        /// 照片區段送出的事件與載入結果
        ///
        /// - Parameter action: 照片子功能要處理的事件
        case photos(OrderEditPhotosFeature.Action)

        /// 選項選擇器的繫結、畫面操作與選取請求
        ///
        /// - Parameter action: 選項子功能要處理的事件
        case pickers(OrderEditPickersFeature.Action)

        /// 使用者在表單上的操作
        @CasePathable
        enum View: Equatable {

            /// 日期選擇器寫回新日期
            ///
            /// - Parameter date: 選擇器寫回的日期
            case dateComponentsChanged(Date)

            /// 使用者按下取消
            case cancelTapped

            /// 使用者按下儲存
            case saveTapped

            /// 表單出現時，新訂單自動聚焦第一個欄位
            case task

            /// 使用者點擊「新增商品」，附加一筆空白商品明細
            case addItemTapped

            /// 使用者滑動刪除指定位置的商品明細
            ///
            /// - Parameter offsets: 要刪除的商品明細位置
            case itemsDeleted(IndexSet)
        }

        /// 交給父層處理的表單請求
        @CasePathable
        enum Delegate: Equatable {

            /// 必填完整，請父層儲存目前的草稿
            case saveRequested

            /// 請父層先寫入主檔，成功後才加入清單與選取
            ///
            /// - Parameters:
            ///   - kind: 要新增的主檔種類
            ///   - name: 已去除前後空白的名稱
            ///   - flags: 付款方式分類旗標；其他主檔使用 `.none`
            case addOptionRequested(kind: LookupKind, name: String, flags: PaymentMethodFlags)
        }

        /// 捨棄確認彈窗的選項
        @CasePathable
        enum DiscardAlert: Equatable {

            /// 使用者確認捨棄未儲存的變更並關閉表單
            case discard
        }
    }

    // MARK: - Dependencies

    /// 關閉目前呈現的表單
    @Dependency(\.dismiss) private var dismiss

    /// 日期選擇器改選分鐘時補入的現在時間，測試可注入固定值
    @Dependency(\.date) private var date

    /// 產生新商品明細的識別碼，測試可注入固定值
    @Dependency(\.uuid) private var uuid

    // MARK: - Body

    /// 組合草稿繫結、照片、選項選擇與表單事件處理
    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.photos, action: \.photos) {
            OrderEditPhotosFeature()
        }

        Scope(state: \.pickers, action: \.pickers) {
            OrderEditPickersFeature()
        }

        Reduce(core)
            .ifLet(\.$discardConfirmation, action: \.discardConfirmation)
    }
}

// MARK: - Private Method

private extension OrderEditFeature {

    /// 更新表單草稿，並套用子功能的選取或新增選項請求
    ///
    /// - Parameters:
    ///   - state: 要更新的父層表單狀態
    ///   - action: 父層或子功能送出的事件
    /// - Returns: 存檔、主檔新增或關閉表單的效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding(let bindingAction):
            return OrderEditDraftOperations.applyBinding(bindingAction, state: &state)

        case .view(let view):
            return OrderEditOperations(dismiss: dismiss) {
                date.now
            } makeItemID: {
                uuid()
            }
            .apply(view, state: &state)

        case .delegate:
            return .none

        case .discardConfirmation(.presented(.discard)):
            state.focusedField = nil
            return .run { _ in await dismiss() }

        case .discardConfirmation:
            return .none

        case .photos(let photosAction):
            return OrderEditDraftOperations.applyPhotos(photosAction, state: &state)

        case .pickers(let pickersAction):
            return OrderEditDraftOperations.applyPickers(pickersAction, state: &state)
        }
    }
}
