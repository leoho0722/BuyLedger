//
//  LookupManagementView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import SwiftUI

/// 訂單來源 / 商品類別 / 付款方式主檔的獨立管理畫面
///
/// 以 ``LookupManagementFeature`` 驅動：點「新增」彈出 alert (訂單來源 / 商品類別) 或 sheet (付款方式含 `isCardless` / `isBankTransfer` toggle、對帳狀態為 name-only sheet)。
/// iOS / iPadOS 以系統 `List` 呈現，列可左滑刪除或編輯／重新命名。
/// 付款方式列操作為「編輯」(開 ``PaymentMethodEditorSheet`` 帶入原資料)，其餘 kind 為「重新命名」alert。文案、空狀態、icon 來自 ``LookupKind``
struct LookupManagementView: View {

    // MARK: - View Properties

    /// 主檔管理 store
    @Bindable var store: StoreOf<LookupManagementFeature>

    /// 依主檔類型回傳可由 String Catalog 翻譯的重新命名標題
    private var renameSheetTitle: LocalizedStringKey {
        switch store.state.kind {
        case .orderSource:
            "重新命名訂單來源"
        case .category:
            "重新命名商品類別"
        case .paymentMethod:
            "重新命名付款方式"
        case .reconciliationStatus:
            "重新命名對帳狀態"
        }
    }

    // MARK: - View Body

    /// 主檔管理畫面內容
    ///
    /// 以系統 `List` 呈現主檔項目，toolbar、新增 / 重新命名 alert、付款方式與對帳狀態新增 sheet 與 `task` 載入一併掛在其上
    var body: some View {
        listContent
            .navigationTitle(Text(LocalizedStringKey(store.state.kind.title)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        // icon-only 只留 +，完整標題留作無障礙標籤、新增流程標題仍顯示於 sheet
                        Label(LocalizedStringKey(store.state.kind.addButtonTitle), systemImage: "plus")
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(item: $store.scope(state: \.destination, action: \.destination)) { destinationStore in
                destinationSheet(store: destinationStore)
            }
            .alert($store.scope(state: \.deletionConfirmation, action: \.deletionConfirmation))
            .task {
                await store.send(.task).finish()
            }
    }
}

// MARK: - ViewBuilder

private extension LookupManagementView {

    /// 依 destination 型別分派要呈現的表單
    ///
    /// 單一呈現點：任一時刻只會有一張 sheet，互斥由型別系統保證，
    /// 而非靠多個並列的 sheet 修飾子與各自的布林彼此避讓
    /// - Parameter store: 已 scope 到 destination 的 store
    /// - Returns: 對應的表單 view
    @ViewBuilder
    func destinationSheet(store destinationStore: StoreOf<LookupManagementFeature.Destination>) -> some View {
        switch destinationStore.case {
        case let .rename(renameStore):
            LookupNameEditorSheet(
                title: renameSheetTitle,
                message: "改名後，引用此名稱的訂單也會一併更新。",
                namePlaceholder: store.state.kind.addFieldPlaceholder,
                submitTitle: "儲存",
                initialName: renameStore.originalName
            ) { name in
                renameStore.send(.draftChanged(name))
                renameStore.send(.saveButtonTapped)
            }

        case let .addNameOnly(addStore):
            LookupNameEditorSheet(
                title: LocalizedStringKey(store.state.kind.addAlertTitle),
                message: store.state.kind.addAlertMessage,
                namePlaceholder: store.state.kind.addFieldPlaceholder,
                submitTitle: "新增"
            ) { name in
                addStore.send(.saveButtonTapped(name: name))
            }

        case let .addPaymentMethod(addStore):
            PaymentMethodEditorSheet(
                title: store.state.kind.addAlertTitle,
                message: store.state.kind.addAlertMessage,
                namePlaceholder: store.state.kind.addFieldPlaceholder,
                submitTitle: "新增"
            ) { name, isCardless, isBankTransfer, isCashOnDelivery in
                addStore.send(
                    .saveButtonTapped(
                        name: name,
                        isCardless: isCardless,
                        isBankTransfer: isBankTransfer,
                        isCashOnDelivery: isCashOnDelivery
                    )
                )
            }

        case let .editPaymentMethod(editStore):
            PaymentMethodEditorSheet(
                title: "編輯付款方式",
                message: "修改名稱與分類；變更名稱會一併更新引用此付款方式的訂單。",
                namePlaceholder: store.state.kind.addFieldPlaceholder,
                submitTitle: "儲存",
                initialName: editStore.originalName,
                initialIsCardless: editStore.isCardless,
                initialIsBankTransfer: editStore.isBankTransfer,
                initialIsCashOnDelivery: editStore.isCashOnDelivery
            ) { name, isCardless, isBankTransfer, isCashOnDelivery in
                editStore.send(
                    .saveButtonTapped(
                        name: name,
                        isCardless: isCardless,
                        isBankTransfer: isBankTransfer,
                        isCashOnDelivery: isCashOnDelivery
                    )
                )
            }
        }
    }

    /// 列項顯示：訂單來源 / 商品類別 / 對帳狀態 kind 純文字；付款方式 kind 在右側顯示「無卡」「銀行匯款」與「貨到付款」徽章 (僅作標示，不能直接切換；要修改旗標需對該列選「編輯」)
    /// - Parameter item: 要顯示的主檔項目名稱
    /// - Returns: 列項 view
    @ViewBuilder
    func itemRow(for item: String) -> some View {
        switch store.state.kind {
        case .orderSource, .category, .reconciliationStatus:
            Text(item)
        case .paymentMethod:
            HStack(spacing: BLSpacing.small) {
                Text(item)

                Spacer()

                if store.paymentMethodIsCardless[item] == true {
                    classificationBadge("無卡")
                }

                if store.paymentMethodIsBankTransfer[item] == true {
                    classificationBadge("銀行匯款")
                }

                if store.paymentMethodIsCashOnDelivery[item] == true {
                    classificationBadge("貨到付款")
                }
            }
        }
    }

    /// 付款方式分類徽章 (例如「無卡」「銀行匯款」「貨到付款」)，沿用 tint 膠囊樣式
    /// - Parameter title: 徽章文字
    /// - Returns: 膠囊徽章 view
    @ViewBuilder
    func classificationBadge(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tint)
            .padding(.horizontal, BLSpacing.small)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.12))
            )
    }

    /// 列項的「編輯／重新命名」操作按鈕，依 kind 分流：付款方式開 ``PaymentMethodEditorSheet`` (帶入原名稱與旗標) 做編輯，其餘 kind 沿用重新命名 alert
    /// - Parameter item: 目標項目名稱
    /// - Returns: 對應的操作按鈕
    @ViewBuilder
    func renameOrEditButton(for item: String) -> some View {
        if store.state.kind == .paymentMethod {
            Button {
                store.send(.editButtonTapped(name: item))
            } label: {
                Label("編輯", systemImage: "pencil")
            }
        } else {
            Button {
                store.send(.renameButtonTapped(name: item))
            } label: {
                Label("重新命名", systemImage: "pencil")
            }
        }
    }

    /// section header 顯示計數、列可左滑刪除或重新命名、付款方式顯示 footer 說明
    @ViewBuilder
    var listContent: some View {
        List {
            if let errorMessage = store.errorMessage {
                Section {
                    Text(LocalizedStringKey(errorMessage))
                        .foregroundStyle(.red)
                }
            }

            Section {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey(store.state.kind.emptyTitle),
                        systemImage: "tray",
                        description: Text(LocalizedStringKey(store.state.kind.emptyDescription))
                    )
                } else {
                    ForEach(store.items, id: \.self) { item in
                        itemRow(for: item)
                            .contextMenu {
                                renameOrEditButton(for: item)

                                Button(role: .destructive) {
                                    store.send(.deleteButtonTapped(item))
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.send(.deleteButtonTapped(item))
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }

                                renameOrEditButton(for: item)
                                .tint(.orange)
                            }
                    }
                }
            } header: {
                Text("目前已建立 \(store.items.count) 項")
            } footer: {
                if store.state.kind == .paymentMethod {
                    Text("「無卡」標籤代表此付款方式會在訂單編輯顯示「無卡折抵金額」與「無卡補款金額」欄位；「銀行匯款」標籤代表會顯示「對帳狀態」欄位；「貨到付款」標籤代表收款金額已含預估運費，獲利會自動扣除三種運費。需要修改名稱或分類時，對該列選「編輯」即可。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("商品類別管理") {
    NavigationStack {
        LookupManagementView(
            store: Store(initialState: LookupManagementFeature.State(kind: .category)) {
                LookupManagementFeature()
            }
        )
    }
}

#Preview("付款方式管理") {
    NavigationStack {
        LookupManagementView(
            store: Store(initialState: LookupManagementFeature.State(kind: .paymentMethod)) {
                LookupManagementFeature()
            }
        )
    }
}
