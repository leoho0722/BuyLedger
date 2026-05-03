//
//  OrderEditView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 編輯或新增訂單的表單畫面。
///
/// 對應 ``OrderEditFeature``：以 sheet 形式呈現，包含取消與儲存按鈕。本切片表單只展示骨架欄位，實際資料寫入會在後續切片補上。
struct OrderEditView: View {
    
    // MARK: - View Properties
    
    /// 訂單編輯 store。
    @Bindable var store: StoreOf<OrderEditFeature>
    
    // MARK: - View Body
    
    /// 編輯表單的畫面內容。
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("客戶名稱", text: $store.draftCustomerName)
                    
                    TextField("商品類別", text: $store.draftCategory)
                } header: {
                    Text("基本資料")
                } footer: {
                    if !canSave {
                        Text("客戶名稱為必填欄位。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("狀態與幣別") {
                    Picker("狀態", selection: $store.draftStatus) {
                        ForEach(OrderStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    
                    Picker("幣別", selection: $store.draftCurrency) {
                        ForEach(CurrencyCode.allCases) { code in
                            Text("\(code.flag) \(code.rawValue)").tag(code)
                        }
                    }
                }
                
                Section("收款金額") {
                    decimalField(
                        title: "客戶實付（NT$）",
                        value: $store.draftChargedAmount
                    )
                }
                
                Section("成本（NT$）") {
                    decimalField(title: "商品成本", value: $store.draftItemCost)
                    decimalField(title: "國內運費", value: $store.draftDomesticShipping)
                    decimalField(title: "國際集運", value: $store.draftInternationalShipping)
                }
                
                Section {
                    percentField(title: "刷卡手續費 %", value: $store.draftCardFeeRate)
                    percentField(title: "平台手續費 %", value: $store.draftPlatformFeeRate)
                } header: {
                    Text("手續費（%）")
                } footer: {
                    Text("輸入百分比例如 1.5 表示 1.5%；超出 0%–100% 範圍會自動限制。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                itemsSection
                
                if let original = store.original {
                    Section("原始訂單") {
                        LabeledContent("單號", value: original.id)
                            .monospacedDigit()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(store.original == nil ? "新訂單" : "編輯訂單")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        store.send(.cancelTapped)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        store.send(.saveTapped)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 540, minHeight: 520)
#endif
    }
}

// MARK: - ViewBuilder

private extension OrderEditView {
    
    /// 商品明細區段：可逐項編輯名稱／數量／單價，亦可新增與刪除。
    var itemsSection: some View {
        Section {
            ForEach($store.draftItems) { $item in
                itemEditorRow(item: $item)
            }
            .onDelete { offsets in
                store.draftItems.remove(atOffsets: offsets)
            }
            
            Button {
                store.draftItems.append(
                    LedgerOrderItem(name: "", quantity: 1, unitPrice: 0)
                )
            } label: {
                Label("新增商品", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("商品明細（\(store.draftCurrency.rawValue)）")
        } footer: {
            if store.draftItems.isEmpty {
                Text("還沒有任何商品；點擊「新增商品」開始填寫。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("商品單價以原始幣別記錄，總成本與獲利仍以上方「成本」欄位的 NT$ 數值為準。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// 單筆商品的編輯列：商品名稱（多行）+ 數量 Stepper + 單價 TextField。
    /// - Parameter item: 雙向繫結的單筆商品。
    /// - Returns: 商品列 view。
    func itemEditorRow(item: Binding<LedgerOrderItem>) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            TextField("商品名稱", text: item.name, axis: .vertical)
                .font(.body.weight(.medium))
                .lineLimit(1...3)
            
            HStack(spacing: BLSpacing.medium) {
                Stepper(value: item.quantity, in: 1...999) {
                    Text("數量 \(item.quantity.wrappedValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
#if os(macOS)
                .controlSize(.small)
#endif
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("單價")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    TextField(
                        "",
                        value: item.unitPrice,
                        format: .number.precision(.fractionLength(0))
                    )
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(maxWidth: 120)
#if !os(macOS)
                    .keyboardType(.numberPad)
#endif
                }
            }
        }
    }
    
    /// 整數金額輸入欄。
    ///
    /// 把 `TextField` 的 placeholder 留空，避免在 macOS `.formStyle(.grouped)` 下 `LabeledContent` 與 `TextField` 同時顯示標題造成的重複文字。
    /// - Parameters:
    ///   - title: 欄位標題。
    ///   - value: 雙向繫結的值。
    /// - Returns: `LabeledContent` + `TextField` 組合 view。
    func decimalField(title: String, value: Binding<Decimal>) -> some View {
        LabeledContent(title) {
            TextField(
                "",
                value: value,
                format: .number.precision(.fractionLength(0))
            )
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
#if !os(macOS)
            .keyboardType(.numberPad)
#endif
        }
    }
    
    /// 百分比輸入欄。
    ///
    /// 介面顯示 0–100 的百分比數字，內部以 0–1 的 ``Decimal`` 儲存以對應 ``LedgerOrder/cardFeeRate`` 等欄位的單位。`TextField` 的 placeholder 同樣留空，由 `LabeledContent` 提供唯一的標題。
    /// - Parameters:
    ///   - title: 欄位標題。
    ///   - value: 雙向繫結的 0–1 比例值。
    /// - Returns: `LabeledContent` + `TextField` 組合 view。
    func percentField(title: String, value: Binding<Decimal>) -> some View {
        let proxy = Binding<Double>(
            get: { NSDecimalNumber(decimal: value.wrappedValue).doubleValue * 100 },
            set: { newValue in
                value.wrappedValue = Decimal(newValue / 100)
            }
        )
        
        return LabeledContent(title) {
            HStack(spacing: 4) {
                TextField(
                    "",
                    value: proxy,
                    format: .number.precision(.fractionLength(2))
                )
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
#if !os(macOS)
                .keyboardType(.decimalPad)
#endif
                
                Text("%")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Private Method

private extension OrderEditView {
    
    /// 是否允許按下儲存。
    ///
    /// 客戶名稱必須含有非空白字元才視為合法。即使儲存路徑保有 trim+fallback 的防禦邏輯，前端仍以 disable 按鈕的方式給使用者明確回饋。
    var canSave: Bool {
        !store.draftCustomerName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
}

// MARK: - ViewBuilder

private extension OrderEditView {}

// MARK: - Preview

#Preview("新訂單") {
    OrderEditView(
        store: Store(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
    )
}

#Preview("編輯訂單") {
    OrderEditView(
        store: Store(
            initialState: OrderEditFeature.State(original: LedgerOrder.sampleOrders[0])
        ) {
            OrderEditFeature()
        }
    )
}
