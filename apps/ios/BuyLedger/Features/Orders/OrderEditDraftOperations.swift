//
//  OrderEditDraftOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation

/// 驗證訂單草稿、查詢付款旗標，並套用選項選取結果
enum OrderEditDraftOperations {

}

// MARK: - Internal Method

extension OrderEditDraftOperations {

    /// 準備初始草稿，夾限預填金額並保留是否曾超額的資訊
    ///
    /// - Parameters:
    ///   - original: 既有訂單；新訂單為 `nil`
    ///   - currentDate: 新訂單的預設日期
    ///   - defaultCurrency: 新訂單的預設幣別
    ///   - prefill: 合併確認帶入的草稿
    /// - Returns: 夾限後的草稿與是否顯示夾限提示
    static func prepareDraft(
        original: LedgerOrder?,
        currentDate: Date,
        defaultCurrency: CurrencyCode,
        prefill: OrderEditFeature.State.Prefill?
    ) -> (draft: OrderDraft, isCardlessDeductionCapped: Bool) {
        var draft = prefill?.draft ?? OrderDraft(
            original: original,
            currentDate: currentDate,
            defaultCurrency: defaultCurrency
        )
        let uncappedDeduction = prefill?.draft.cardlessDeductionAmount
            ?? original?.cardlessDeductionAmount ?? 0
        draft.cardlessDeductionAmount = min(
            draft.cardlessDeductionAmount,
            max(0, draft.chargedAmount)
        )
        return (
            draft: draft,
            isCardlessDeductionCapped: uncappedDeduction > draft.cardlessDeductionAmount
        )
    }

    /// 建立表單初始照片狀態，保留合併時選擇的照片
    ///
    /// - Parameters:
    ///   - original: 既有訂單；新訂單為 `nil`
    ///   - prefill: 合併草稿及保留的照片
    /// - Returns: 不帶照片編輯標記的初始狀態
    static func photos(
        original: LedgerOrder?,
        prefill: OrderEditFeature.State.Prefill?
    ) -> OrderEditPhotosFeature.State {
        OrderEditPhotosFeature.State(orderID: original?.id, draftPhotos: prefill?.keptPhotos ?? [])
    }

    /// 判斷焦點欄位是否需要數字鍵盤
    ///
    /// - Parameter focusedField: 目前取得焦點的表單欄位
    /// - Returns: 數字欄位為 `true`，其他欄位或無焦點為 `false`
    static func isNumericFieldFocused(_ focusedField: OrderEditFeature.State.Field?) -> Bool {
        switch focusedField {
        case .chargedAmount, .cardlessDeduction, .cardlessSupplement, .itemCost,
                .foreignDomesticShipping, .internationalShipping, .domesticShipping, .cardFeeRate,
                .platformFeeRate, .paymentFeeRate, .itemUnitPrice:
            return true

        case .customerName, .itemName, .notes, nil:
            return false
        }
    }

    /// 檢查草稿必填欄位是否完整
    ///
    /// - Parameter draft: 要檢查的訂單草稿
    /// - Returns: 客戶名稱、來源與至少一個類別皆非空白時為 `true`
    static func canSave(draft: OrderDraft) -> Bool {
        let fields = [draft.customerName, draft.orderSource]
        let hasCategory = draft.categories.contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return hasCategory && fields.allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// 依草稿中的付款名稱，取得可選清單中對應的付款方式
    ///
    /// - Parameter state: 持有草稿與付款選項的父層狀態
    /// - Returns: 清單中的付款方式；空名稱或沒有對應項目時為 `nil`
    static func selectedPaymentMethod(state: OrderEditFeature.State) -> PaymentMethodInfo? {
        let trimmed = state.draft.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return state.pickers.availablePaymentMethods.first { $0.name == trimmed }
    }

    /// 將已選類別依原有分隔符號串接，供編輯畫面顯示
    ///
    /// - Parameter draft: 持有已選類別的父層草稿
    /// - Returns: 以頓號分隔的類別名稱
    static func categoriesDisplayText(draft: OrderDraft) -> String {
        draft.categories.joined(separator: "、")
    }

    /// 金額欄位變更時重新檢查無卡折抵上限，其他欄位只由 `BindingReducer` 寫入
    ///
    /// - Parameters:
    ///   - action: 表單欄位的雙向繫結變更
    ///   - state: 持有草稿與上限提示的表單狀態
    /// - Returns: 不產生效果
    static func applyBinding(
        _ action: BindingAction<OrderEditFeature.State>,
        state: inout OrderEditFeature.State
    ) -> Effect<OrderEditFeature.Action> {
        if case \.chargedAmount = action {
            reconcileCardlessDeductionCap(state: &state)
        } else if case \.cardlessDeductionAmount = action {
            reconcileCardlessDeductionCap(state: &state)
        }
        return .none
    }

    /// 把照片區段要求的檢視位置交給選擇器路由，其他照片事件不改表單
    ///
    /// - Parameters:
    ///   - action: 照片區段送出的事件
    ///   - state: 持有照片與選擇器路由的表單狀態
    /// - Returns: 不產生效果
    static func applyPhotos(
        _ action: OrderEditPhotosFeature.Action,
        state: inout OrderEditFeature.State
    ) -> Effect<OrderEditFeature.Action> {
        switch action {
        case .delegate(.photoViewerRequested(let index)):
            state.pickers.pickerRoute = .photoViewer(index: index)
            return .none

        case .binding, .view, .photoImportResponse, .photosLoadResponse:
            return .none
        }
    }

    /// 把選擇器子功能的事件套用到表單，選取結果寫入草稿，其他事件不改草稿
    ///
    /// - Parameters:
    ///   - action: 選擇器子功能送出的事件
    ///   - state: 唯一持有訂單草稿的父層狀態
    /// - Returns: 新增選項時轉送父層的主檔請求，其他選取不產生效果
    static func applyPickers(
        _ action: OrderEditPickersFeature.Action,
        state: inout OrderEditFeature.State
    ) -> Effect<OrderEditFeature.Action> {
        switch action {
        case .delegate(let selection):
            return apply(selection, state: &state)

        case .binding, .view:
            return .none
        }
    }

    /// 選取新增的選項，合併情境新增類別時保留既有選取
    ///
    /// - Parameters:
    ///   - plan: 新增成功的主檔項目
    ///   - state: 要套用選取的父層狀態
    static func applyAddition(_ plan: OrderOptionWritePlan, state: inout OrderEditFeature.State) {
        OrderEditPickerOperations.applyAddition(plan, state: &state.pickers)
        let name = plan.name
        switch plan.kind {
        case .orderSource:
            state.draft.orderSource = name

        case .category:
            if state.isMergeContext {
                if !state.draft.categories.contains(name) {
                    state.draft.categories.append(name)
                }
            } else {
                state.draft.categories = [name]
            }

        case .paymentMethod:
            state.draft.paymentMethod = name

        case .reconciliationStatus:
            state.draft.reconciliationStatus = name
        }
    }
}

// MARK: - Private Method

private extension OrderEditDraftOperations {

    /// 依客戶實付金額限制無卡折抵金額，並更新提示狀態
    ///
    /// - Parameter state: 要更新金額與提示的父層狀態
    static func reconcileCardlessDeductionCap(state: inout OrderEditFeature.State) {
        let cap = max(0, state.draft.chargedAmount)
        if state.draft.cardlessDeductionAmount > cap {
            state.draft.cardlessDeductionAmount = cap
            state.isCardlessDeductionCapped = true
        } else {
            state.isCardlessDeductionCapped = false
        }
    }

    /// 將子層選取請求套用到父層持有的草稿
    ///
    /// - Parameters:
    ///   - selection: 子層回報的選取或新增選項
    ///   - state: 唯一持有訂單草稿的父層狀態
    /// - Returns: 新增選項時轉送父層原有的主檔請求；其他選取不產生效果
    static func apply(
        _ selection: OrderEditPickersFeature.Action.Delegate,
        state: inout OrderEditFeature.State
    ) -> Effect<OrderEditFeature.Action> {
        switch selection {
        case .orderSourceSelected(let name):
            state.draft.orderSource = name

        case .categorySelected(let name):
            state.draft.categories = [name]

        case .categoryToggled(let name):
            if let index = state.draft.categories.firstIndex(of: name) {
                state.draft.categories.remove(at: index)
            } else {
                state.draft.categories.append(name)
            }

        case .campaignSelected(let name):
            state.draft.campaignNames = name.isEmpty ? [] : [name]

        case .campaignToggled(let name):
            if let index = state.draft.campaignNames.firstIndex(of: name) {
                state.draft.campaignNames.remove(at: index)
            } else {
                state.draft.campaignNames.append(name)
            }

        case .paymentMethodSelected(let name):
            state.draft.paymentMethod = name

        case .reconciliationStatusSelected(let name):
            state.draft.reconciliationStatus = name

        case .currencySelected(let code):
            state.draft.currency = CurrencyCode(rawValue: code)

        case .addOptionRequested(let kind, let name, let flags):
            return .send(.delegate(.addOptionRequested(kind: kind, name: name, flags: flags)))
        }
        return .none
    }
}
