//
//  LookupManagementView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import SwiftUI

/// 商品類別 / 付款方式主檔的獨立管理畫面。
///
/// 以 ``LookupManagementFeature`` 驅動：點「新增」彈出 alert (商品類別) 或 sheet (付款方式，含 `isCardless` toggle)；列點 swipe 刪除或重新命名。文案、空狀態、icon 來自 ``LookupKind``。
struct LookupManagementView: View {

    // MARK: - View Properties

    /// 主檔管理 store。
    @Bindable var store: StoreOf<LookupManagementFeature>

    /// 是否顯示「新增類別」alert (僅商品類別 kind 使用)。
    @State private var showsAddCategoryAlert = false

    /// 是否顯示「新增付款方式」sheet (僅付款方式 kind 使用；alert 在實機驗證會 silently 丟掉 Toggle，所以付款方式入口改走 sheet)。
    @State private var showsAddPaymentMethodSheet = false

    /// 新增 alert 的名稱輸入草稿 (商品類別)。
    @State private var draft = ""

    /// 目前正在重新命名的項目；`nil` 表示未進行 rename。
    @State private var renameTarget: String?

    /// 重新命名 alert 的輸入草稿。
    @State private var renameDraft = ""

    // MARK: - View Body

    /// 主檔管理畫面內容。
    var body: some View {
        List {
            if let errorMessage = store.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        store.state.kind.emptyTitle,
                        systemImage: "tray",
                        description: Text(store.state.kind.emptyDescription)
                    )
                } else {
                    ForEach(store.items, id: \.self) { item in
                        itemRow(for: item)
                            .contextMenu {
                                Button {
                                    renameTarget = item
                                    renameDraft = item
                                } label: {
                                    Label("重新命名", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    store.send(.deleteRequested(item))
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.send(.deleteRequested(item))
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }

                                Button {
                                    renameTarget = item
                                    renameDraft = item
                                } label: {
                                    Label("重新命名", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                }
            } header: {
                Text("目前已建立 \(store.items.count) 項")
            } footer: {
                if store.state.kind == .paymentMethod {
                    Text("「無卡」標籤代表此付款方式會在訂單編輯顯示「無卡折抵金額」與「無卡補款金額」欄位。要更換此設定請刪除後重新新增。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(store.state.kind.title)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    switch store.state.kind {
                    case .category:
                        draft = ""
                        showsAddCategoryAlert = true
                    case .paymentMethod:
                        showsAddPaymentMethodSheet = true
                    }
                } label: {
                    Label(store.state.kind.addButtonTitle, systemImage: "plus")
                }
            }
        }
        .alert(
            "重新命名\(store.state.kind.entryTitle)",
            isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )
        ) {
            TextField(store.state.kind.addFieldPlaceholder, text: $renameDraft)
#if !os(macOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
#endif

            Button("儲存") {
                if let from = renameTarget {
                    let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, trimmed != from {
                        store.send(.renameRequested(from: from, to: trimmed))
                    }
                }
                renameTarget = nil
                renameDraft = ""
            }
            .disabled({
                let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty || trimmed == renameTarget
            }())

            Button("取消", role: .cancel) {
                renameTarget = nil
                renameDraft = ""
            }
        } message: {
            if let from = renameTarget {
                Text("把「\(from)」改成新名稱；引用此名稱的訂單也會一併更新。")
            } else {
                Text("")
            }
        }
        .alert(store.state.kind.addAlertTitle, isPresented: $showsAddCategoryAlert) {
            TextField(store.state.kind.addFieldPlaceholder, text: $draft)
#if !os(macOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
#endif

            Button("新增") {
                let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    store.send(.addConfirmed(name: trimmed, isCardless: false))
                }
                draft = ""
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("取消", role: .cancel) {
                draft = ""
            }
        } message: {
            Text(store.state.kind.addAlertMessage)
        }
        .sheet(isPresented: $showsAddPaymentMethodSheet) {
            PaymentMethodEditorSheet(
                title: store.state.kind.addAlertTitle,
                message: store.state.kind.addAlertMessage,
                namePlaceholder: store.state.kind.addFieldPlaceholder,
                submitTitle: "新增",
                onSubmit: { name, isCardless in
                    store.send(.addConfirmed(name: name, isCardless: isCardless))
                }
            )
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension LookupManagementView {

    /// 列項顯示：商品類別 kind 純文字；付款方式 kind 在右側顯示「無卡」徽章 (僅作標示，不能直接切換；要修改 `isCardless` 需刪除後重新新增)。
    /// - Parameter item: 要顯示的主檔項目名稱。
    /// - Returns: 列項 view。
    @ViewBuilder
    func itemRow(for item: String) -> some View {
        switch store.state.kind {
        case .category:
            Text(item)
        case .paymentMethod:
            HStack(spacing: BLSpacing.small) {
                Text(item)

                Spacer()

                if store.paymentMethodIsCardless[item] == true {
                    Text("無卡")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                        .padding(.horizontal, BLSpacing.small)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.12))
                        )
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
