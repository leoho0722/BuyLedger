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

    /// 目前的動態字級，用來在輔助字級堆疊步進器與單價
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 非輔助字級時單價輸入欄的寬度，隨 Dynamic Type 縮放
    @ScaledMetric private var unitPriceWidth: CGFloat = 120

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
        ForEach($store.draft.items) {
            itemEditorRow(item: $0)
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

    /// 顯示商品名稱、數量與單價的編輯列
    ///
    /// - Parameter item: 單筆商品的雙向綁定
    /// - Returns: 商品名稱輸入框，加上數量步進器與單價輸入的編輯列
    @ViewBuilder
    func itemEditorRow(item: Binding<LedgerOrderItem>) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            // 關閉內容類型，避免系統提供不相關建議
            BLTextField(
                "orders.list.label.itemName",
                text: item.name,
                axis: .vertical,
                focus: focusedField,
                equals: .itemName(item.id)
            )
            .lineLimit(1...3)
            .font(BLTypographyStyle.body.font.weight(.medium))
            .textContentType(nil)
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.itemNameField)

            itemControlsLayout {
                Stepper(value: item.quantity, in: 1...999) {
                    Text(
                        store.state.itemQuantityDisplayText(
                            item.quantity.wrappedValue,
                            locale: locale
                        )
                    )
                        .blTextStyle(.footnote)
                        .foregroundStyle(.blSecondaryLabel)
                }

                Spacer()

                HStack(spacing: BLSpacing.extraSmall) {
                    Text("orders.edit.label.unitPrice")
                        .blTextStyle(.footnote)
                        .foregroundStyle(.blSecondaryLabel)

                    BLNumberField(
                        "",
                        value: item.unitPrice,
                        format: .number.precision(.fractionLength(0)).grouping(.never),
                        focus: focusedField,
                        equals: .itemUnitPrice(item.id)
                    )
                    .frame(
                        maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : unitPriceWidth
                    )
                    .frame(minHeight: BLHitTarget.minimum)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .labelsHidden()
                    .keyboardType(.numberPad)
                    .contentShape(.rect)
                    .accessibilityIdentifier(BLAccessibilityID.OrderEdit.itemUnitPriceField)
                }
            }
            // 輔助字級下採用理想高度，避免 Spacer 在垂直排列中撐出多餘空白
            .fixedSize(horizontal: false, vertical: dynamicTypeSize.isAccessibilitySize)
        }
    }

    /// 商品明細標題與系統清單編輯入口
    var sectionHeader: some View {
        HStack {
            Text(store.state.itemDetailsTitle(locale: locale))

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
                .foregroundStyle(.blSecondaryLabel)
        } else {
            Text("orders.edit.message.itemPricesRecorded")
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)
        }
    }
}

// MARK: - Private Method

private extension OrderEditItemsSection {

    /// 數量步進器與單價輸入依動態字級切換的自適應佈局
    var itemControlsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: BLSpacing.small))
            : AnyLayout(HStackLayout(alignment: .center, spacing: BLSpacing.medium))
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
