//
//  LookupManagementView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import SwiftUI

/// 訂單來源 / 商品類別 / 付款方式主檔的獨立管理畫面
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
    var body: some View {
        listContent
            .accessibilityIdentifier(BLAccessibilityID.LookupManagement.root)
            .navigationTitle(Text(LocalizedStringKey(store.state.kind.title)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        // icon-only 只留 +，完整標題留作無障礙標籤、新增流程標題仍顯示於 sheet
                        Label(
                            LocalizedStringKey(store.state.kind.addButtonTitle), systemImage: "plus"
                        )
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(item: $store.scope(state: \.destination, action: \.destination)) {
                destinationStore in
                destinationSheet(store: destinationStore)
            }
            .alert($store.scope(state: \.deletionConfirmation, action: \.deletionConfirmation))
            .alert(
                $store.scope(state: \.retroactiveConfirmation, action: \.retroactiveConfirmation)
            )
            .alert($store.scope(state: \.writeFailureAlert, action: \.writeFailureAlert))
            .task {
                await store.send(.task).finish()
            }
    }
}

// MARK: - ViewBuilder

private extension LookupManagementView {
    
    /// 依 destination 型別分派要呈現的表單
    /// - Parameter store: 已 scope 到 destination 的 store
    /// - Returns: 對應的表單 view
    @ViewBuilder
    func destinationSheet(
        store destinationStore: StoreOf<LookupManagementFeature.Destination>
    ) -> some View {
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
            ) { name, flags in
                addStore.send(.saveButtonTapped(name: name, flags: flags))
            }
            
        case let .editPaymentMethod(editStore):
            PaymentMethodEditorSheet(
                title: "編輯付款方式",
                message: "修改名稱與分類；變更名稱會一併更新引用此付款方式的訂單。",
                namePlaceholder: store.state.kind.addFieldPlaceholder,
                submitTitle: "儲存",
                initialName: editStore.originalName,
                initialFlags: editStore.flags
            ) { name, flags in
                editStore.send(.saveButtonTapped(name: name, flags: flags))
            }
        }
    }
    
    /// 顯示主檔項目；付款方式額外顯示分類徽章
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
    
    /// 付款方式分類徽章
    /// - Parameter title: 徽章文字
    /// - Returns: 膠囊徽章 view
    @ViewBuilder
    func classificationBadge(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .font(BLTypographyStyle.caption.font.weight(.semibold))
            .foregroundStyle(.tint)
            .padding(.horizontal, BLSpacing.small)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(BLPalette().accent.opacity(0.12))
            )
    }
    
    /// 建立項目的編輯或重新命名按鈕
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
            .accessibilityIdentifier(BLAccessibilityID.LookupManagement.editButton(item))
        } else {
            Button {
                store.send(.renameButtonTapped(name: item))
            } label: {
                Label("重新命名", systemImage: "pencil")
            }
            .accessibilityIdentifier(BLAccessibilityID.LookupManagement.renameButton(item))
        }
    }
    
    /// 主檔 section header 與列表
    @ViewBuilder
    var listContent: some View {
        let palette = BLPalette()
        
        List {
            if let errorMessage = store.errorMessage {
                Section {
                    Text(LocalizedStringKey(errorMessage))
                        .foregroundStyle(palette.red)
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
                            .accessibilityIdentifier(BLAccessibilityID.LookupManagement.row(item))
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
                                    .tint(palette.orange)
                            }
                    }
                }
            } header: {
                Text("目前已建立 \(store.items.count) 項")
            } footer: {
                if store.state.kind == .paymentMethod {
                    Text(
                        """
                        「無卡」標籤代表此付款方式會在訂單編輯顯示「無卡折抵金額」與「無卡補款金額」欄位；\
                        「銀行匯款」標籤代表會顯示「對帳狀態」欄位；「貨到付款」標籤代表收款金額已含預估運費，\
                        獲利會自動扣除三種運費。需要修改名稱或分類時，對該列選「編輯」即可。
                        """
                    )
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
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
