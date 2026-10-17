//
//  OrderEditPickerOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation

/// 更新選擇器路由與選項清單，並將草稿選取請求交給父層
enum OrderEditPickerOperations {

}

// MARK: - Internal Method

extension OrderEditPickerOperations {

    /// 依選擇器畫面事件更新路由或轉送選取請求
    ///
    /// - Parameters:
    ///   - action: 選擇器畫面送出的事件
    ///   - state: 只包含選項清單與路由的子層狀態
    /// - Returns: 要交給父層的選取或主檔新增請求
    static func apply(
        _ action: OrderEditPickersFeature.Action.View,
        state: inout OrderEditPickersFeature.State
    ) -> Effect<OrderEditPickersFeature.Action> {
        switch action {
        case .addOrderSourceTapped(let name):
            return add(name: name, kind: .orderSource, flags: .none)

        case .addCategoryTapped(let name):
            return add(name: name, kind: .category, flags: .none)

        case .categorySelected(let name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return .none
            }
            return .send(.delegate(.categorySelected(trimmed)))

        case .categoryToggled(let value):
            return .send(.delegate(.categoryToggled(value)))

        case .campaignSelected(let name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return .send(.delegate(.campaignSelected(trimmed)))

        case .campaignToggled(let value):
            return .send(.delegate(.campaignToggled(value)))

        case .addPaymentMethodTapped(let name, let flags):
            return add(name: name, kind: .paymentMethod, flags: flags)

        case .addReconciliationStatusTapped(let name):
            return add(name: name, kind: .reconciliationStatus, flags: .none)

        case .orderSourcePickerTapped:
            state.pickerRoute = .orderSource
            return .none

        case .categoryPickerTapped:
            state.pickerRoute = .category
            return .none

        case .campaignPickerTapped:
            state.pickerRoute = .campaign
            return .none

        case .currencyPickerTapped:
            state.pickerRoute = .currency
            return .none

        case .paymentMethodPickerTapped:
            state.pickerRoute = .paymentMethod
            return .none

        case .reconciliationStatusPickerTapped:
            state.pickerRoute = .reconciliationStatus
            return .none

        case .orderSourceSelected(let value):
            return .send(.delegate(.orderSourceSelected(value)))

        case .paymentMethodSelected(let value):
            return .send(.delegate(.paymentMethodSelected(value)))

        case .reconciliationStatusSelected(let value):
            return .send(.delegate(.reconciliationStatusSelected(value)))

        case .currencySelected(let value):
            return .send(.delegate(.currencySelected(value)))
        }
    }
}

// MARK: - Private Method

private extension OrderEditPickerOperations {

    /// 將非空名稱整理後請父層寫入主檔，清單與草稿保持原值
    ///
    /// - Parameters:
    ///   - name: 尚未去除前後空白的名稱
    ///   - kind: 要加入的主檔種類
    ///   - flags: 付款方式分類旗標
    /// - Returns: 帶整理後名稱的新增請求；空名稱不產生效果
    static func add(
        name: String,
        kind: LookupKind,
        flags: PaymentMethodFlags
    ) -> Effect<OrderEditPickersFeature.Action> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .none
        }
        return .send(.delegate(.addOptionRequested(kind: kind, name: trimmed, flags: flags)))
    }
}
