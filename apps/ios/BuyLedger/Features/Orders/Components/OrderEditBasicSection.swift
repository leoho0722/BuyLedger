//
//  OrderEditBasicSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 訂單的客戶、來源、類別與日期區段
struct OrderEditBasicSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditFeature>

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<OrderEditFeature.State.Field?>.Binding

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Section {
            fields
        } header: {
            sectionHeader
        } footer: {
            sectionFooter
        }
    }
}

// MARK: - Private Views

private extension OrderEditBasicSection {

    /// 客戶名稱、來源、類別與訂購日期
    @ViewBuilder
    var fields: some View {
        TextField("orders.list.label.customerName", text: $store.draft.customerName)
            .textContentType(.name)
            .focused(focusedField, equals: .customerName)
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.customerField)

        orderSourcePickerRow

        categoryPickerRow

        orderDateRow
    }

    /// 基本資料的區段標題
    var sectionHeader: some View {
        Text("orders.edit.label.basicInformation")
    }

    /// 訂購時間與必填欄位說明
    var sectionFooter: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(
                AppLanguage.format(
                    "orders.edit.label.orderDateTimestamp",
                    OrderFormatters.fullTimestamp(
                        store.draft.date,
                        calendar: store.calendar,
                        locale: locale
                    ),
                    locale: locale
                )
            )
            .blTextStyle(.footnote)
            .foregroundStyle(.blSecondaryLabel)
            .monospacedDigit()

            if !store.canSave {
                Text("orders.edit.message.customerNameOrder")
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blSecondaryLabel)
            }
        }
    }

    /// 訂單來源的選擇器入口，保留原有選取值與提示文字
    var orderSourcePickerRow: some View {
        OrderEditSelectionRow(
            title: "orders.detail.label.orderSource",
            identifier: BLAccessibilityID.OrderEdit.sourceRow,
            action: {
                pickerStore.send(.view(.orderSourcePickerTapped))
            }
        ) {
            Group {
                if store.draft.orderSource.isEmpty {
                    Text("orders.edit.label.selectSource")
                } else {
                    Text(verbatim: store.draft.orderSource)
                }
            }
        }
    }

    /// 商品類別的選擇器入口，保留原有選取值與提示文字
    var categoryPickerRow: some View {
        OrderEditSelectionRow(
            title: "orders.list.label.itemCategory",
            identifier: BLAccessibilityID.OrderEdit.categoryRow,
            action: {
                pickerStore.send(.view(.categoryPickerTapped))
            }
        ) {
            Group {
                if store.draft.categories.isEmpty {
                    Text("orders.edit.label.selectCategories")
                } else {
                    Text(
                        verbatim: OrderEditDraftOperations.categoriesDisplayText(draft: store.draft)
                    )
                }
            }
            .multilineTextAlignment(.trailing)
        }
    }

    /// 以系統精簡日期選擇器編輯日期與時分
    var orderDateRow: some View {
        DatePicker(
            "orders.edit.label.orderDate",
            selection: refreshingSecondsBinding,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .environment(\.locale, locale)
    }
}

// MARK: - Private Method

private extension OrderEditBasicSection {

    /// 只負責選項清單、選擇器路由與選取請求的子 store
    var pickerStore: StoreOf<OrderEditPickersFeature> {
        store.scope(state: \.pickers, action: \.pickers)
    }

    /// 日期寫回交由 reducer 補上目前時間
    var refreshingSecondsBinding: Binding<Date> {
        Binding {
            store.draft.date
        } set: {
            store.send(.view(.dateComponentsChanged($0)))
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditBasicSection(
                store: Store(
                    initialState: OrderEditFeature.State(
                        id: id,
                        currentDate: Date(timeIntervalSince1970: 0)
                    )
                ) {
                    OrderEditFeature()
                },
                focusedField: $focusedField
            )
        }
    }
}
