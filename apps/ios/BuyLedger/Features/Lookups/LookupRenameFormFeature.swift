//
//  LookupRenameFormFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

/// 改名表單送出前驗證新名稱
@Reducer
struct LookupRenameFormFeature {

    // MARK: - State

    /// 改名表單開啟時的主檔名稱
    @ObservableState
    struct State: Equatable {

        /// 尚未更改的主檔名稱
        let originalName: String
    }

    // MARK: - Action

    /// 改名表單可處理的事件
    enum Action {

        /// 使用者在表單按下儲存
        ///
        /// - Parameter view: 使用者送出的表單操作
        case view(View)

        /// 交給主檔管理的改名結果
        ///
        /// - Parameter delegate: 驗證後的新舊名稱
        case delegate(Delegate)

        /// 使用者在表單上的操作
        @CasePathable
        enum View {

            /// 使用者送出新名稱
            ///
            /// - Parameter name: 輸入的新名稱
            case saveButtonTapped(name: String)
        }

        /// 交給主檔管理的改名結果
        @CasePathable
        enum Delegate: Equatable {

            /// 新名稱有效且與原名稱不同
            ///
            /// - Parameters:
            ///   - oldName: 原主檔名稱
            ///   - newName: 去除前後空白的新名稱
            case saved(oldName: String, newName: String)
        }
    }

    // MARK: - Body

    /// 只組合 reducer，表單送出的驗證由 `core(state:action:)` 處理
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension LookupRenameFormFeature {

    /// 驗證改名表單並回傳送出的結果
    ///
    /// - Parameters:
    ///   - state: 目前的表單狀態
    ///   - action: 這次收到的表單事件
    /// - Returns: 要交給主檔管理的結果，資料無效時不回傳事件
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .view(.saveButtonTapped(name)):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty, trimmedName != state.originalName else {
                return .none
            }
            return .send(
                .delegate(
                    .saved(
                        oldName: state.originalName,
                        newName: trimmedName
                    )
                )
            )

        case .delegate:
            return .none
        }
    }
}
