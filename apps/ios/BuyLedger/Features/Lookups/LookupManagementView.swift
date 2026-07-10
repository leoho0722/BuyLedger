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

    /// 是否顯示「新增類別」alert (僅商品類別 kind 使用)
    @State private var showsAddCategoryAlert = false

    /// 是否顯示「新增付款方式」sheet (僅付款方式 kind 使用；alert 在實機驗證會 silently 丟掉 Toggle，所以付款方式入口改走 sheet)
    @State private var showsAddPaymentMethodSheet = false

    /// 是否顯示「新增對帳狀態」medium sheet (僅對帳狀態 kind 使用；比照付款方式以 sheet 收集名稱)
    @State private var showsAddVerificationStatusSheet = false

    /// 新增 alert 的名稱輸入草稿 (商品類別)
    @State private var draft = ""

    /// 目前正在重新命名的項目；`nil` 表示未進行 rename
    @State private var renameTarget: String?

    /// 重新命名 alert 的輸入草稿
    @State private var renameDraft = ""

    /// 目前正在編輯的付款方式名稱；`nil` 表示未開啟編輯 sheet (僅付款方式 kind 使用)
    @State private var editTarget: String?

    // MARK: - View Body

    /// 主檔管理畫面內容
    ///
    /// 內容區依平台分流 (見 ``content``)，但 toolbar、新增 / 重新命名 alert、付款方式新增 sheet 與 `task` 載入由兩個平台分支共用，確保操作與業務邏輯一致
    var body: some View {
        content
            .navigationTitle(store.state.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        switch store.state.kind {
                        case .orderSource, .category:
                            draft = ""
                            showsAddCategoryAlert = true
                        case .paymentMethod:
                            showsAddPaymentMethodSheet = true
                        case .verificationStatus:
                            showsAddVerificationStatusSheet = true
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("新增") {
                    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        store.send(.addConfirmed(name: trimmed, isCardless: false, isBankTransfer: false, isCashOnDelivery: false))
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
                    onSubmit: { name, isCardless, isBankTransfer, isCashOnDelivery in
                        store.send(.addConfirmed(name: name, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery))
                    }
                )
            }
            .sheet(isPresented: $showsAddVerificationStatusSheet) {
                LookupItemEditorSheet(
                    title: store.state.kind.addAlertTitle,
                    message: store.state.kind.addAlertMessage,
                    namePlaceholder: store.state.kind.addFieldPlaceholder,
                    submitTitle: "新增",
                    onSubmit: { name in
                        store.send(.addConfirmed(name: name, isCardless: false, isBankTransfer: false, isCashOnDelivery: false))
                    }
                )
            }
            .sheet(
                isPresented: Binding(
                    get: { editTarget != nil },
                    set: { if !$0 { editTarget = nil } }
                )
            ) {
                if let target = editTarget {
                    PaymentMethodEditorSheet(
                        title: "編輯付款方式",
                        message: "修改名稱與分類；變更名稱會一併更新引用此付款方式的訂單。",
                        namePlaceholder: store.state.kind.addFieldPlaceholder,
                        submitTitle: "儲存",
                        initialName: target,
                        initialIsCardless: store.paymentMethodIsCardless[target] ?? false,
                        initialIsBankTransfer: store.paymentMethodIsBankTransfer[target] ?? false,
                        initialIsCashOnDelivery: store.paymentMethodIsCashOnDelivery[target] ?? false,
                        onSubmit: { name, isCardless, isBankTransfer, isCashOnDelivery in
                            store.send(
                                .editConfirmed(
                                    originalName: target,
                                    name: name,
                                    isCardless: isCardless,
                                    isBankTransfer: isBankTransfer,
                                    isCashOnDelivery: isCashOnDelivery
                                )
                            )
                        }
                    )
                }
            }
            .task {
                await store.send(.task).finish()
            }
    }
}

// MARK: - ViewBuilder

private extension LookupManagementView {

    /// 內容區呈現
    @ViewBuilder
    var content: some View {
        listContent
    }

    /// 列項顯示：訂單來源 / 商品類別 / 對帳狀態 kind 純文字；付款方式 kind 在右側顯示「無卡」「銀行匯款」與「貨到付款」徽章 (僅作標示，不能直接切換；要修改旗標需對該列選「編輯」)
    /// - Parameter item: 要顯示的主檔項目名稱
    /// - Returns: 列項 view
    @ViewBuilder
    func itemRow(for item: String) -> some View {
        switch store.state.kind {
        case .orderSource, .category, .verificationStatus:
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
        Text(title)
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
                editTarget = item
            } label: {
                Label("編輯", systemImage: "pencil")
            }
        } else {
            Button {
                renameTarget = item
                renameDraft = item
            } label: {
                Label("重新命名", systemImage: "pencil")
            }
        }
    }
}

// MARK: - ViewBuilder (iOS / iPadOS List 版本)

private extension LookupManagementView {

    /// iOS / iPadOS 維持的系統 List 版本：section header 顯示計數、列可左滑刪除或重新命名、付款方式顯示 footer 說明
    @ViewBuilder
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
                                renameOrEditButton(for: item)

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
