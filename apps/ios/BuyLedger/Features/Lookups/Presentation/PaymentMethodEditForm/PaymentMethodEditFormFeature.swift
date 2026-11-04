//
//  PaymentMethodEditFormFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

/// 付款方式表單送出前驗證名稱並保留分類旗標
@Reducer
struct PaymentMethodEditFormFeature {

    // MARK: - State

    /// 付款方式表單的草稿、焦點與捨棄確認狀態
    @ObservableState
    struct State: Equatable {

        /// 尚未更改的付款方式名稱
        let originalName: String

        /// 開啟表單時的付款方式分類旗標
        let flags: PaymentMethodFlags

        /// 名稱輸入草稿，開啟時等於原名稱
        var draftName: String

        /// 是否標記為無卡類付款方式，開啟時等於原旗標
        var isDraftCardless: Bool

        /// 是否標記為銀行匯款類付款方式，開啟時等於原旗標
        var isDraftBankTransfer: Bool

        /// 是否標記為貨到付款類付款方式，開啟時等於原旗標
        var isDraftCashOnDelivery: Bool

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

        /// 名稱未修剪比對，或分類旗標與開啟時不同時為已變更
        var isDirty: Bool {
            draftName != originalName || draftFlags != flags
        }

        /// 去除前後空白後非空時可以送出
        var canSubmit: Bool {
            !trimmedName.isEmpty
        }

        /// 建立付款方式表單，草稿從開啟時的名稱與旗標開始
        ///
        /// - Parameters:
        ///   - originalName: 尚未更改的付款方式名稱
        ///   - flags: 開啟表單時的付款方式分類旗標
        init(originalName: String, flags: PaymentMethodFlags) {
            self.originalName = originalName
            self.flags = flags
            self.draftName = originalName
            self.isDraftCardless = flags.isCardless
            self.isDraftBankTransfer = flags.isBankTransfer
            self.isDraftCashOnDelivery = flags.isCashOnDelivery
        }
    }

    // MARK: - Action

    /// 付款方式表單可處理的事件
    enum Action: BindableAction {

        /// 表單欄位的綁定寫入
        ///
        /// - Parameter action: 被綁定的欄位與新值
        case binding(BindingAction<State>)

        /// 使用者在表單按下儲存
        ///
        /// - Parameter view: 使用者送出的表單操作
        case view(View)

        /// 交給主檔管理的編輯結果
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

            /// 使用者送出付款方式名稱與分類旗標
            ///
            /// - Parameters:
            ///   - name: 輸入的新名稱
            ///   - flags: 選定的付款方式分類旗標
            case saveButtonTapped(name: String, flags: PaymentMethodFlags)
        }

        /// 交給主檔管理的編輯結果
        @CasePathable
        enum Delegate: Equatable {

            /// 名稱有效後交由父層進行付款方式更正
            ///
            /// - Parameters:
            ///   - originalName: 尚未更改的付款方式名稱
            ///   - newName: 去除前後空白的新名稱
            ///   - flags: 選定的付款方式分類旗標
            case saved(originalName: String, newName: String, flags: PaymentMethodFlags)
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

private extension PaymentMethodEditFormFeature {

    /// 驗證付款方式表單並回傳送出的結果
    ///
    /// - Parameters:
    ///   - state: 目前的表單狀態
    ///   - action: 這次收到的表單事件
    /// - Returns: 要交給主檔管理的結果，名稱無效時不回傳事件
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
            return .send(
                .delegate(
                    .saved(originalName: state.originalName, newName: trimmedName, flags: flags)
                )
            )

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
