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

    /// 付款方式表單開啟時的名稱與分類旗標
    @ObservableState
    struct State: Equatable {

        /// 尚未更改的付款方式名稱
        let originalName: String

        /// 開啟表單時的付款方式分類旗標
        let flags: PaymentMethodFlags
    }

    // MARK: - Action

    /// 付款方式表單可處理的事件
    enum Action {

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
            case saved(
                originalName: String,
                newName: String,
                flags: PaymentMethodFlags
            )
        }
    }

    // MARK: - Body

    /// 只組合 reducer，表單送出的驗證由 `core(state:action:)` 處理
    var body: some Reducer<State, Action> {
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
        case let .view(.saveButtonTapped(name, flags)):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                return .none
            }
            return .send(
                .delegate(
                    .saved(
                        originalName: state.originalName,
                        newName: trimmedName,
                        flags: flags
                    )
                )
            )

        case .delegate:
            return .none
        }
    }
}
