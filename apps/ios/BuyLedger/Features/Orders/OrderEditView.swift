//
//  OrderEditView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 編輯或新增訂單的表單畫面
struct OrderEditView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditFeature>

    /// 鍵盤焦點的 `SwiftUI` 鏡像，由子區段共用綁定
    @FocusState private var focusedField: OrderEditFeature.State.Field?

    // MARK: - Body

    /// 組合十個表單區段、導覽與畫面層級的互動
    var body: some View {
        NavigationStack(path: pickerPath) {
            Form {
                formSections
            }
            .formStyle(.grouped)
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.root)
            .scrollDismissesKeyboard(.interactively)
            .bind($store.focusedField, to: $focusedField)
            // 不等待完成：關閉表單的 effect 會掛在這次送出底下，推入選擇器取消 `.task` 時會一起被取消
            .task {
                store.send(.view(.task))
            }
            .navigationTitle(Text(LocalizedStringKey(store.navigationTitleKey)))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                editorToolbar
            }
            .navigationDestination(for: OrderEditPickersFeature.State.PickerRoute.self) {
                OrderEditPickerDestination(store: store, route: $0)
            }
        }
        // 有未儲存變更時阻擋下滑關閉，取消鍵交由 reducer 呈現捨棄確認
        .interactiveDismissDisabled(store.isDirty)
        .alert($store.scope(state: \.discardConfirmation, action: \.discardConfirmation))
    }
}

// MARK: - Private Views

private extension OrderEditView {

    /// 保留既有視覺順序的十個表單區段
    @ViewBuilder
    var formSections: some View {
        OrderEditBasicSection(store: store, focusedField: $focusedField)

        OrderEditStatusSection(store: store)

        OrderEditPaymentSection(store: store, focusedField: $focusedField)

        OrderEditCampaignSection(store: store)

        OrderEditCostSection(store: store, focusedField: $focusedField)

        OrderEditFeesSection(store: store, focusedField: $focusedField)

        OrderEditItemsSection(store: store, focusedField: $focusedField)

        OrderEditNotesSection(notes: $store.draft.notes, focusedField: $focusedField)

        OrderEditPhotosSection(store: store.scope(state: \.photos, action: \.photos))

        OrderEditOriginalSection(original: store.original)
    }

    /// 取消、儲存與數字鍵盤完成鍵
    @ToolbarContentBuilder
    var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                store.send(.view(.cancelTapped))
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text("common.action.cancel"))
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.cancelButton)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                store.send(.view(.saveTapped))
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(Text("orders.edit.button.save"))
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.saveButton)
            .keyboardShortcut(.defaultAction)
            .disabled(!store.canSave)
        }

        // 數字欄位的焦點判斷由 Feature 提供，完成鍵透過 store 綁定清除焦點
        if store.isNumericFieldFocused {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button {
                    store.focusedField = nil
                } label: {
                    Image(systemName: "checkmark")
                }
                .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
                .accessibilityLabel(Text("common.action.button.done"))
            }
        }
    }
}

// MARK: - Private Method

private extension OrderEditView {

    /// 只負責選項清單、選擇器路由與選取請求的子 store
    var pickerStore: StoreOf<OrderEditPickersFeature> {
        store.scope(state: \.pickers, action: \.pickers)
    }

    /// 訂單編輯表單的選擇器導覽路徑
    var pickerPath: Binding<[OrderEditPickersFeature.State.PickerRoute]> {
        @Bindable var bindablePickers = pickerStore
        return Binding {
            bindablePickers.pickerRoute.map {
                [$0]
            } ?? []
        } set: {
            $bindablePickers.pickerRoute.wrappedValue = $0.last
        }
    }
}

// MARK: - Preview

#Preview("orders.list.label.newOrder") {
    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        OrderEditView(
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

#Preview("orders.detail.label.editOrder") {
    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        OrderEditView(
            store: Store(
                initialState: OrderEditFeature.State(
                    original: LedgerOrder.sampleOrders[0],
                    id: id,
                    currentDate: Date(timeIntervalSince1970: 0)
                )
            ) {
                OrderEditFeature()
            }
        )
    }
}
