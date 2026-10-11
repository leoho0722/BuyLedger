//
//  OrderEditItemsSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 可新增、編輯與刪除商品明細的區段
struct OrderEditItemsSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditFeature>

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<OrderEditFeature.State.Field?>.Binding

    // MARK: - Body

    /// 商品明細區段，內容為可編輯的商品列與新增商品按鈕，標題與頁尾分別顯示幣別與提示
    var body: some View {
        Section {
            itemRows
        } header: {
            sectionHeader
        } footer: {
            sectionFooter
        }
    }
}

// MARK: - Private Views

private extension OrderEditItemsSection {

    /// 商品編輯列、左滑刪除與新增商品入口
    @ViewBuilder
    var itemRows: some View {
        ForEach($store.draft.items) { $item in
            itemEditorRow(item: $item)
        }
        .onDelete {
            store.send(.view(.itemsDeleted($0)))
        }

        Button {
            store.send(.view(.addItemTapped))
        } label: {
            Label("orders.edit.label.addItem", systemImage: "plus.circle.fill")
        }
    }

    /// 商品明細標題與系統清單編輯入口
    var sectionHeader: some View {
        HStack {
            Text(AppLanguage.format("orders.edit.label.itemDetailsCurrency", store.draft.currency.rawValue, locale: locale))

            Spacer()

            // 保留左滑刪除，也提供不依賴手勢的系統清單編輯模式入口
            // 與下方可見的「新增商品」形成對稱
            if !store.draft.items.isEmpty {
                EditButton()
                    .blTextStyle(.footnote)
                    .textCase(nil)
            }
        }
    }

    /// 空明細提示與成本幣別說明
    @ViewBuilder
    var sectionFooter: some View {
        if store.draft.items.isEmpty {
            Text("orders.edit.message.thereItemsYet")
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        } else {
            Text("orders.edit.message.itemPricesRecorded")
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }

    /// 顯示商品名稱、數量與單價的編輯列
    ///
    /// - Parameter item: 單筆商品的雙向綁定
    /// - Returns: 商品名稱輸入框，加上數量步進器與單價輸入的編輯列
    @ViewBuilder
    func itemEditorRow(item: Binding<LedgerOrderItem>) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            // 關閉內容類型，避免系統提供不相關建議
            TextField("orders.list.label.itemName", text: item.name, axis: .vertical)
                .lineLimit(1...3)
                .font(BLTypographyStyle.body.font.weight(.medium))
                .textContentType(nil)
                .focused(focusedField, equals: .itemName(item.id))

            HStack(spacing: BLSpacing.medium) {
                Stepper(value: item.quantity, in: 1...999) {
                    Text(AppLanguage.format("orders.detail.label.quantity", item.quantity.wrappedValue, locale: locale))
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("orders.edit.label.unitPrice")
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)

                    TextField(
                        "",
                        value: item.unitPrice,
                        format: .number.precision(.fractionLength(0)).grouping(.never)
                    )
                    .frame(maxWidth: 120)
                    .frame(minHeight: BLHitTarget.minimum)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .labelsHidden()
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .itemUnitPrice(item.id))
                    .contentShape(.rect)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditItemsSection(
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
