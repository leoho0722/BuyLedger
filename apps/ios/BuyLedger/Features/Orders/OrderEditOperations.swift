//
//  OrderEditOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 使用父層提供的相依更新日期、新增商品與關閉表單
struct OrderEditOperations: Sendable {

    // MARK: - Properties

    /// 關閉目前表單的相依效果
    let dismiss: DismissEffect

    /// 日期選擇器改選分鐘時才讀取的現在時間，供補入秒數
    ///
    /// - Returns: 相依提供的現在時間
    let now: @Sendable () -> Date

    /// 新增商品明細時才呼叫的識別碼產生器
    ///
    /// - Returns: 新商品明細的識別碼
    let makeItemID: @Sendable () -> UUID
}

// MARK: - Internal Method

extension OrderEditOperations {

    /// 依父層畫面事件處理表單操作
    ///
    /// - Parameters:
    ///   - action: 草稿編輯畫面送出的事件
    ///   - state: 要套用操作的父層狀態
    /// - Returns: 存檔、取消或關閉效果；同步編輯不產生效果
    func apply(
        _ action: OrderEditFeature.Action.View,
        state: inout OrderEditFeature.State
    ) -> Effect<OrderEditFeature.Action> {
        switch action {
        case .dateComponentsChanged(let value):
            updateDate(value, state: &state)
            return .none

        case .cancelTapped:
            return cancel(state: &state)

        case .saveTapped:
            return save(state: &state)

        case .task:
            if state.original == nil, state.focusedField == nil {
                state.focusedField = .customerName
            }
            return .none

        case .addItemTapped:
            addItem(state: &state)
            return .none

        case .itemsDeleted(let offsets):
            state.draft.items.remove(atOffsets: offsets)
            return .none
        }
    }
}

// MARK: - Private Method

private extension OrderEditOperations {

    /// 更新日期選擇結果，重選同分鐘或初始分鐘時保留原本秒數
    ///
    /// - Parameters:
    ///   - newValue: 日期選擇器送出的值
    ///   - state: 要更新日期的父層狀態
    func updateDate(_ newValue: Date, state: inout OrderEditFeature.State) {
        // 固定使用西曆與 UTC 時區，避免裝置設定改變日期比對結果
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: newValue
        )
        let initialComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: state.initialDraft.date
        )
        // 選回開啟時的年月日時分就恢復開啟時的值，轉走再轉回不算修改
        if components == initialComponents {
            state.draft.date = state.initialDraft.date
            return
        }
        let draftComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: state.draft.date
        )
        // 同分鐘重選時保留草稿秒數，避免未編輯就變成已修改
        guard components != draftComponents else {
            return
        }
        components.second = calendar.component(.second, from: now())
        state.draft.date = calendar.date(from: components) ?? newValue
    }

    /// 取消編輯，草稿有變更時先呈現捨棄確認
    ///
    /// - Parameter state: 要判斷修改狀態並清除焦點的父層狀態
    /// - Returns: 關閉表單的效果；有未儲存變更時只更新彈窗
    func cancel(state: inout OrderEditFeature.State) -> Effect<OrderEditFeature.Action> {
        if state.isDirty {
            state.discardConfirmation = AlertState {
                TextState("orders.list.label.discardChanges")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("orders.list.label.discardChanges")
                }
                ButtonState(role: .cancel) {
                    TextState("orders.list.label.keepEditing")
                }
            } message: {
                TextState("orders.edit.message.orderHasUnsaved")
            }
            return .none
        }

        state.focusedField = nil
        return .run { _ in
            await dismiss()
        }
    }

    /// 必填完整時先請父層儲存，再關閉表單
    ///
    /// - Parameter state: 要驗證並清除焦點的父層狀態
    /// - Returns: 存檔請求與關閉效果；必填未齊時不產生效果
    func save(state: inout OrderEditFeature.State) -> Effect<OrderEditFeature.Action> {
        guard state.canSave else {
            return .none
        }
        state.focusedField = nil
        return .run { send in
            await send(.delegate(.saveRequested))
            await dismiss()
        }
    }

    /// 以注入的識別碼新增空白商品明細
    ///
    /// - Parameter state: 要加入商品明細的父層狀態
    func addItem(state: inout OrderEditFeature.State) {
        state.draft.items.append(
            LedgerOrderItem(
                id: makeItemID(),
                name: "",
                quantity: 1,
                unitPrice: 0
            )
        )
    }
}
