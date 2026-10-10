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
        TextField("客戶名稱", text: $store.draft.customerName)
            .textContentType(.name)
            .focused(focusedField, equals: .customerName)
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.customerField)

        orderSourcePickerRow

        categoryPickerRow

        orderDateRow
    }

    /// 基本資料的區段標題
    var sectionHeader: some View {
        Text("基本資料")
    }

    /// 訂購時間與必填欄位說明
    var sectionFooter: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(
                """
                訂購日期：\
                \(OrderFormatters.fullTimestamp(
                    store.draft.date,
                    calendar: store.calendar,
                    locale: locale
                )
                )
                """
            )
            .blTextStyle(.footnote)
            .foregroundStyle(Color.blSecondaryLabel)
            .monospacedDigit()

            if !store.canSave {
                Text("客戶名稱、訂單來源與商品類別皆為必填欄位。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
        }
    }

    /// 訂單來源的選擇器入口，保留原有選取值與提示文字
    var orderSourcePickerRow: some View {
        OrderEditSelectionRow(
            title: "訂單來源",
            identifier: BLAccessibilityID.OrderEdit.sourceRow,
            action: {
                pickerStore.send(.view(.orderSourcePickerTapped))
            }
        ) {
            Group {
                if store.draft.orderSource.isEmpty {
                    Text("選擇來源")
                } else {
                    Text(verbatim: store.draft.orderSource)
                }
            }
        }
    }

    /// 商品類別的選擇器入口，保留原有選取值與提示文字
    var categoryPickerRow: some View {
        OrderEditSelectionRow(
            title: "商品類別",
            identifier: BLAccessibilityID.OrderEdit.categoryRow,
            action: {
                pickerStore.send(.view(.categoryPickerTapped))
            }
        ) {
            Group {
                if store.draft.categories.isEmpty {
                    Text("選擇類別")
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
            "訂購日期",
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
