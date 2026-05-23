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
/// 以 ``LookupManagementFeature`` 驅動：點「新增」彈出 alert 收集名稱、列點 swipe 刪除。文案、空狀態、icon 來自 ``LookupKind``。
struct LookupManagementView: View {

    // MARK: - View Properties

    /// 主檔管理 store。
    @Bindable var store: StoreOf<LookupManagementFeature>

    /// 是否顯示「新增」alert。
    @State private var showsAddAlert = false

    /// 新增 alert 的輸入草稿。
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
                        Text(item)
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
            }
        }
        .navigationTitle(store.state.kind.title)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draft = ""
                    showsAddAlert = true
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
        .alert(store.state.kind.addAlertTitle, isPresented: $showsAddAlert) {
            TextField(store.state.kind.addFieldPlaceholder, text: $draft)
#if !os(macOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
#endif

            Button("新增") {
                let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    store.send(.addConfirmed(trimmed))
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
        .task {
            await store.send(.task).finish()
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
