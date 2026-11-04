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

    /// 改名表單的草稿、焦點與捨棄確認狀態
    @ObservableState
    struct State: Equatable {

        /// 尚未更改的主檔名稱
        let originalName: String

        /// 名稱輸入草稿，開啟時等於原名稱
        var draftName: String

        /// 名稱欄位是否持有鍵盤焦點
        var isNameFieldFocused = false

        /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
        var isDiscardConfirmationPresented = false

        /// 去除前後空白後的草稿名稱
        var trimmedName: String {
            draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// 去除前後空白後與原名稱不同時為已變更
        var isDirty: Bool {
            trimmedName != originalName
        }

        /// 去除前後空白後非空且與原名稱不同時可以送出
        var canSubmit: Bool {
            !trimmedName.isEmpty && trimmedName != originalName
        }

        /// 建立改名表單，草稿從原名稱開始
        ///
        /// - Parameter originalName: 尚未更改的主檔名稱
        init(originalName: String) {
            self.originalName = originalName
            self.draftName = originalName
        }
    }

    // MARK: - Action

    /// 改名表單可處理的事件
    enum Action: BindableAction {

        /// 表單欄位的綁定寫入
        ///
        /// - Parameter action: 被綁定的欄位與新值
        case binding(BindingAction<State>)

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

            /// 使用者按下取消鍵，有未儲存變更時呈現捨棄確認，否則關閉表單
            case cancelButtonTapped

            /// 使用者在捨棄確認中選擇捨棄變更，關閉表單
            case discardChangesButtonTapped

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

private extension LookupRenameFormFeature {

    /// 驗證改名表單並回傳送出的結果
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

        case .view(.saveButtonTapped(let name)):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty, trimmedName != state.originalName else {
                return .none
            }
            return .send(.delegate(.saved(oldName: state.originalName, newName: trimmedName)))

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
