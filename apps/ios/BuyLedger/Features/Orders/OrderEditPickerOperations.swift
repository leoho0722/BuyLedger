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

    /// 將已落盤的選項加入清單，保留付款方式旗標
    ///
    /// - Parameters:
    ///   - plan: 已成功落盤的主檔項目
    ///   - state: 要加入選項的子層狀態
    static func applyAddition(
        _ plan: OrderOptionWritePlan,
        state: inout OrderEditPickersFeature.State
    ) {
        let trimmed = plan.name
        let flags = plan.flags
        switch plan.kind {
        case .orderSource:
            append(trimmed, to: &state.availableOrderSources)

        case .category:
            append(trimmed, to: &state.availableCategories)

        case .paymentMethod:
            if let index = state.availablePaymentMethods.firstIndex(where: { $0.name == trimmed }) {
                state.availablePaymentMethods[index] = PaymentMethodInfo(
                    name: trimmed,
                    flags: flags
                )
            } else {
                var updated = state.availablePaymentMethods
                updated.append(PaymentMethodInfo(name: trimmed, flags: flags))
                state.availablePaymentMethods = updated.sorted { lhs, rhs in
                    lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
            }

        case .reconciliationStatus:
            append(trimmed, to: &state.availableReconciliationStatuses)
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

    /// 清單尚無同名項目時加入名稱，並沿用自然排序
    ///
    /// - Parameters:
    ///   - name: 已整理的非空名稱
    ///   - options: 要補入新名稱的可選清單
    static func append(_ name: String, to options: inout [String]) {
        if !options.contains(name) {
            var updated = options
            updated.append(name)
            options = updated.sorted { lhs, rhs in
                lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
        }
    }
}
