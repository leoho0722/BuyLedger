//
//  OrderEditCampaignSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 訂單歸團與收款狀態區段
struct OrderEditCampaignSection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditFeature>

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Section("orders.edit.label.campaignsPayments") {
            fields
        }
    }
}

// MARK: - Private Views

private extension OrderEditCampaignSection {

    /// 單選或多選開團入口與系統分段收款選單
    @ViewBuilder
    var fields: some View {
        if store.isMergeContext {
            // 合併情境由選擇列推入開團多選畫面
            campaignPickerRow
        } else {
            Picker("orders.detail.title.campaigns", selection: campaignSelectionBinding) {
                Text("orders.detail.label.unassigned")
                    .tag("")

                ForEach(pickerStore.options.campaigns, id: \.self) {
                    Text($0)
                        .tag($0)
                }
            }
        }

        Picker("orders.edit.label.paymentStatus", selection: $store.draft.paymentReceiptStatus) {
            ForEach(PaymentReceiptStatus.allCases) {
                Text(LocalizedStringKey($0.title))
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
    }

    /// 開團的選擇器入口，保留原有選取值與提示文字
    var campaignPickerRow: some View {
        OrderEditSelectionRow(
            title: "orders.detail.title.campaigns",
            identifier: BLAccessibilityID.OrderEdit.campaignRow
        ) {
            pickerStore.send(.view(.campaignPickerTapped))
        } value: {
            Text(store.campaignsDisplayText)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Private Method

private extension OrderEditCampaignSection {

    /// 只負責選項清單、選擇器路由與選取請求的子 store
    var pickerStore: StoreOf<OrderEditPickersFeature> {
        store.scope(state: \.pickers, action: \.pickers)
    }

    /// 單選開團的綁定，空字串代表未歸團
    var campaignSelectionBinding: Binding<String> {
        Binding {
            store.draft.campaignNames.first ?? ""
        } set: {
            pickerStore.send(.view(.campaignSelected($0)))
        }
    }
}

// MARK: - Preview

#Preview {
    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditCampaignSection(
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
