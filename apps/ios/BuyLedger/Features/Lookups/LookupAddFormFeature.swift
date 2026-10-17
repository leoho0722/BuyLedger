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

    /// 新增表單這次是否包含付款方式分類
    @ObservableState
    struct State: Equatable {

        /// 是否顯示付款方式分類選項
        let hasClassification: Bool
    }

    // MARK: - Action

    /// 新增表單可處理的事件
    enum Action {

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

    // MARK: - Body

    /// 只組合 reducer，表單送出的驗證由 `core(state:action:)` 處理
    var body: some Reducer<State, Action> {
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
        case let .view(.saveButtonTapped(name, flags)):
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
}
