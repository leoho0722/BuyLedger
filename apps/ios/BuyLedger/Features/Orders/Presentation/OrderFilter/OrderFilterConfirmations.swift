//
//  OrderFilterConfirmations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/19.
//

import ComposableArchitecture
import Foundation

/// 提供篩選面板與類別選擇器共用的捨棄確認
enum OrderFilterConfirmations {

}

// MARK: - Internal Method

extension OrderFilterConfirmations {

    /// 建立捨棄未套用篩選或繼續編輯的確認
    ///
    /// - Parameter discard: 確認捨棄時送出的事件
    /// - Returns: 包含捨棄與繼續編輯按鈕的確認內容
    static func discardChanges<Action>(discard: Action) -> AlertState<Action> {
        AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("orders.list.message.filtersHaveApplied")
        }
    }
}
