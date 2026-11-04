//
//  LookupAddFormFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

/// 新增主檔表單送出前驗證名稱與分類旗標
@Reducer
struct LookupAddFormFeature {

    // MARK: - State

    /// 新增表單的草稿、焦點與捨棄確認狀態
    @ObservableState
    struct State: Equatable {

        /// 新增表單這次是否包含付款方式分類
        let hasClassification: Bool

        /// 名稱輸入草稿，開啟時為空白
        var draftName = ""

        /// 是否標記為無卡類付款方式，只在付款方式表單送出
        var isDraftCardless = false

        /// 是否標記為銀行匯款類付款方式，只在付款方式表單送出
        var isDraftBankTransfer = false

        /// 是否標記為貨到付款類付款方式，只在付款方式表單送出
        var isDraftCashOnDelivery = false

        /// 名稱欄位是否持有鍵盤焦點
        var isNameFieldFocused = false

        /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
        var isDiscardConfirmationPresented = false

        /// 去除前後空白後的草稿名稱
        var trimmedName: String {
            draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// 付款方式分類旗標草稿
        var draftFlags: PaymentMethodFlags {
            PaymentMethodFlags(
                isCardless: isDraftCardless,
                isBankTransfer: isDraftBankTransfer,
                isCashOnDelivery: isDraftCashOnDelivery
            )
        }

        /// 是否有未儲存的變更
        ///
        /// 付款方式表單比對未修剪的名稱與旗標，名稱表單比對去除空白後的名稱
        var isDirty: Bool {
            if hasClassification {
                return !draftName.isEmpty
                    || isDraftCardless
                    || isDraftBankTransfer
                    || isDraftCashOnDelivery
            }
            return !trimmedName.isEmpty
        }

        /// 去除前後空白後非空時可以送出
        var canSubmit: Bool {
            !trimmedName.isEmpty
        }

        /// 建立新增表單，草稿為空白且旗標皆關閉
        ///
        /// - Parameter hasClassification: 新增表單是否包含付款方式分類
        init(hasClassification: Bool) {
            self.hasClassification = hasClassification
        }
    }

    // MARK: - Action

    /// 新增表單可處理的事件
    enum Action: BindableAction {

        /// 表單欄位的綁定寫入
        ///
        /// - Parameter action: 被綁定的欄位與新值
        case binding(BindingAction<State>)

        /// 使用者在表單按下儲存
        ///
        /// - Parameter view: 使用者送出的表單操作
        case view(View)

        /// 交給主檔管理的新增結果
        ///
        /// - Parameter delegate: 驗證後的新名稱與旗標
        case delegate(Delegate)

        /// 使用者在表單上的操作
        @CasePathable
        enum View {

            /// 使用者按下取消鍵，有未儲存變更時呈現捨棄確認，否則關閉表單
            case cancelButtonTapped

            /// 使用者在捨棄確認中選擇捨棄變更，關閉表單
            case discardChangesButtonTapped

            /// 使用者送出新名稱與分類旗標
            ///
            /// - Parameters:
            ///   - name: 輸入的新名稱
            ///   - flags: 選定的付款方式分類旗標
            case saveButtonTapped(name: String, flags: PaymentMethodFlags)
        }

        /// 交給主檔管理的新增結果
        @CasePathable
        enum Delegate: Equatable {

            /// 名稱驗證完成，可以新增主檔
            ///
            /// - Parameters:
            ///   - name: 去除前後空白的新名稱
            ///   - flags: 新主檔的付款方式分類旗標
            case saved(name: String, flags: PaymentMethodFlags)
        }
    }

    // MARK: - Dependencies

    /// 關閉目前的表單，取消與捨棄由 reducer 執行，不依賴 `View` 的 `dismiss`
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Body

    /// 組合欄位綁定與表單送出的 reducer，送出的驗證由 `core(state:action:)` 處理
    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce(core)
    }
}

// MARK: - Private Method

private extension LookupAddFormFeature {

    /// 驗證新增表單並回傳送出的結果
    ///
    /// - Parameters:
    ///   - state: 目前的表單狀態
    ///   - action: 這次收到的表單事件
    /// - Returns: 要交給主檔管理的結果，資料無效時不回傳事件
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.cancelButtonTapped):
            guard state.isDirty else {
                return dismissForm()
            }
            state.isDiscardConfirmationPresented = true
            return .none

        case .view(.discardChangesButtonTapped):
            return dismissForm()

        case .view(.saveButtonTapped(let name, let flags)):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                return .none
            }
            let submittedFlags = state.hasClassification ? flags : .none
            return .send(.delegate(.saved(name: trimmedName, flags: submittedFlags)))

        case .delegate:
            return .none
        }
    }

    /// 關閉表單，由 reducer 執行 `dismiss` effect
    ///
    /// - Returns: 執行 `dismiss` 的 effect
    func dismissForm() -> Effect<Action> {
        .run { _ in await dismiss() }
    }
}
