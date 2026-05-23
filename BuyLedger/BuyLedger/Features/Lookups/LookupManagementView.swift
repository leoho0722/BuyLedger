//
//  LookupManagementView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import SwiftUI

/// 訂單來源 / 商品類別 / 付款方式主檔的獨立管理畫面。
///
/// 以 ``LookupManagementFeature`` 驅動：點「新增」彈出 alert (訂單來源 / 商品類別) 或 sheet (付款方式，含 `isCardless` toggle)。macOS 採 `ScrollView` + `BLCard` 卡片版面 (對齊 ``CustomersView``)，以右鍵 contextMenu 重新命名或刪除；iOS / iPadOS 維持系統 `List`，列可左滑刪除或重新命名。文案、空狀態、icon 來自 ``LookupKind``。
struct LookupManagementView: View {

    // MARK: - View Properties

    /// 主檔管理 store。
    @Bindable var store: StoreOf<LookupManagementFeature>

    /// 目前系統深淺色外觀；macOS 卡片版面用來取得色盤。
    @Environment(\.colorScheme) private var colorScheme

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
    ///
    /// 內容區依平台分流 (見 ``content``)，但 toolbar、新增 / 重新命名 alert、付款方式新增 sheet 與 `task` 載入由兩個平台分支共用，確保操作與業務邏輯一致。
    var body: some View {
        content
            .navigationTitle(store.state.kind.title)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        switch store.state.kind {
                        case .orderSource, .category:
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

    /// 依平台選擇內容呈現：macOS 走 Design System 卡片版面，iOS / iPadOS 維持系統 List。
    @ViewBuilder
    var content: some View {
#if os(macOS)
        macContent
#else
        listContent
#endif
    }

    /// 列項顯示：訂單來源 / 商品類別 kind 純文字；付款方式 kind 在右側顯示「無卡」徽章 (僅作標示，不能直接切換；要修改 `isCardless` 需刪除後重新新增)。
    /// - Parameter item: 要顯示的主檔項目名稱。
    /// - Returns: 列項 view。
    @ViewBuilder
    func itemRow(for item: String) -> some View {
        switch store.state.kind {
        case .orderSource, .category:
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

#if !os(macOS)

// MARK: - ViewBuilder (iOS / iPadOS List 版本)

private extension LookupManagementView {

    /// iOS / iPadOS 維持的系統 List 版本：section header 顯示計數、列可左滑刪除或重新命名、付款方式顯示 footer 說明。
    var listContent: some View {
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
    }
}

#endif

#if os(macOS)

// MARK: - ViewBuilder (macOS 卡片版面)

private extension LookupManagementView {

    /// macOS 的 Design System 卡片版本：對齊 ``CustomersView`` 的 `ScrollView` + `palette.background` + `BLCard` 呈現。
    var macContent: some View {
        let palette = BLTheme.palette(for: colorScheme)

        return ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(palette.red)
                }

                if store.items.isEmpty {
                    macEmptyState(palette: palette)
                } else {
                    macItemList(palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.background)
    }

    /// macOS 空狀態：對齊 ``CustomersView`` 的置中 `ContentUnavailableView`。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 空狀態 view。
    func macEmptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            store.state.kind.emptyTitle,
            systemImage: "tray",
            description: Text(store.state.kind.emptyDescription)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, BLSpacing.section)
        .background(palette.background)
    }

    /// macOS 卡片列表：計數 header + 單一 `BLCard` 內含列 (列間帶 leading inset 的 `Divider`)，付款方式於卡片下方顯示無卡說明。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 卡片列表 view。
    func macItemList(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("全部\(store.state.kind.entryTitle)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
                    .textCase(.uppercase)

                Spacer()

                Text("\(store.items.count) 項")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }

            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(store.items.enumerated()), id: \.element) { index, item in
                        macRow(for: item, palette: palette)
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

                        if index < store.items.count - 1 {
                            Divider()
                                .padding(.leading, BLSpacing.large)
                        }
                    }
                }
            }

            if store.state.kind == .paymentMethod {
                // 與 iOS List footer 相同的無卡說明；兩個平台分支獨立呈現，因此各保留一份字串。
                Text("「無卡」標籤代表此付款方式會在訂單編輯顯示「無卡折抵金額」與「無卡補款金額」欄位。要更換此設定請刪除後重新新增。")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
    }

    /// macOS 卡片中的單一列：沿用 ``itemRow(for:)`` 內容，補上卡片列內距與整列點擊範圍。
    /// - Parameters:
    ///   - item: 要顯示的主檔項目名稱。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 卡片列 view。
    func macRow(for item: String, palette: BLPalette) -> some View {
        itemRow(for: item)
            .font(.subheadline)
            .foregroundStyle(palette.label)
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}

#endif

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
