//
//  OrderEditStatusSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 訂單狀態、幣別、付款方式與對帳狀態區段
struct OrderEditStatusSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditFeature>

    // MARK: - Body

    /// 「狀態與幣別」區段，內容為狀態選單與幣別、付款方式，以及符合條件時顯示的對帳狀態選擇列
    var body: some View {
        Section("狀態與幣別") {
            fields
        }
    }
}

// MARK: - Private Views

private extension OrderEditStatusSection {

    /// 狀態選單與付款相關選擇列
    @ViewBuilder
    var fields: some View {
        Picker("狀態", selection: $store.draft.status) {
            ForEach(store.availableStatuses) {
                Text(LocalizedStringKey($0.title))
                    .tag($0)
            }
        }

        currencyPickerRow

        paymentMethodPickerRow

        if store.shouldShowReconciliationStatusRow {
            reconciliationStatusPickerRow
        }
    }

    /// 幣別的選擇器入口，顯示目前幣別的名稱
    var currencyPickerRow: some View {
        OrderEditSelectionRow(
            title: "幣別",
            identifier: BLAccessibilityID.OrderEdit.currencyRow,
            action: {
                pickerStore.send(.view(.currencyPickerTapped))
            }
        ) {
            Text(
                CurrencyDisplayName.text(
                    code: store.draft.currency.rawValue,
                    language: AppLanguage(locale: locale)
                )
            )
        }
    }

    /// 付款方式的選擇器入口，未選取時顯示提示文字
    var paymentMethodPickerRow: some View {
        OrderEditSelectionRow(
            title: "付款方式",
            identifier: BLAccessibilityID.OrderEdit.paymentRow,
            action: {
                pickerStore.send(.view(.paymentMethodPickerTapped))
            }
        ) {
            Group {
                if store.draft.paymentMethod.isEmpty {
                    Text("選擇付款方式")
                } else {
                    Text(verbatim: store.draft.paymentMethod)
                }
            }
        }
    }

    /// 對帳狀態的選擇器入口，未選取時顯示提示文字
    var reconciliationStatusPickerRow: some View {
        OrderEditSelectionRow(
            title: "對帳狀態",
            identifier: BLAccessibilityID.OrderEdit.reconciliationRow,
            action: {
                pickerStore.send(.view(.reconciliationStatusPickerTapped))
            }
        ) {
            Group {
                if store.draft.reconciliationStatus.isEmpty {
                    Text("選擇對帳狀態")
                } else {
                    Text(verbatim: store.draft.reconciliationStatus)
                }
            }
        }
    }
}

// MARK: - Private Method

private extension OrderEditStatusSection {

    /// 只負責選項清單、選擇器路由與選取請求的子 store
    var pickerStore: StoreOf<OrderEditPickersFeature> {
        store.scope(state: \.pickers, action: \.pickers)
    }
}

// MARK: - Preview

#Preview {
    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditStatusSection(
                store: Store(
                    initialState: OrderEditFeature.State(
                        id: id,
                        currentDate: Date(timeIntervalSince1970: 0)
                    )
                ) {
                    OrderEditFeature()
                }
            )
        }
    }
}
