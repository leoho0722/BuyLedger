//
//  OptionPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 訂單編輯表單裡用於「單選一個字串選項、或新增一個」的通用 sheet。
///
/// 取代原本的 `Menu`：iOS Menu 因為是 `UIMenu` 的二次包裝，UIKit 端會把 Button action 排到 menu collapse 動畫結束後才派發給 SwiftUI，造成「選完選項 → 約 300ms 後 label 才更新」的可見延遲。改用 sheet 後，使用者點選時 binding 立即 commit，sheet 收合與 form label 更新解耦，視覺上不再卡頓。
///
/// 透過字串參數讓「商品類別」、「付款方式」等選單共用同一份元件，避免重複實作。
struct OptionPickerSheet: View {

    // MARK: - View Properties

    /// Sheet 的標題（顯示在 navigation bar）。
    let title: String

    /// 「新增」按鈕顯示的標題。
    let addButtonTitle: String

    /// 沒有任何選項時 ``ContentUnavailableView`` 的標題。
    let emptyTitle: String

    /// 沒有任何選項時 ``ContentUnavailableView`` 的描述。
    let emptyDescription: String

    /// 「新增」alert 的標題。
    let addAlertTitle: String

    /// 「新增」alert 內 TextField 的 placeholder。
    let addFieldPlaceholder: String

    /// 「新增」alert 的說明訊息。
    let addAlertMessage: String

    /// 目前可選的選項清單。
    let options: [String]

    /// 目前已選中的選項；用來在列表中顯示勾選。
    let selected: String

    /// 使用者選擇既有選項時的 callback。
    let onSelect: (String) -> Void

    /// 使用者透過「新增」alert 確認新增一個選項時的 callback。
    let onAdd: (String) -> Void

    /// 由 sheet 環境注入的 dismiss action。
    @Environment(\.dismiss) private var dismiss

    /// 是否顯示「新增」alert。
    @State private var showsAddAlert = false

    /// 新增 alert 的輸入草稿。
    @State private var draft = ""

    // MARK: - View Body

    /// 選項選擇 sheet 的內容。
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        draft = ""
                        showsAddAlert = true
                    } label: {
                        Label(addButtonTitle, systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    if options.isEmpty {
                        ContentUnavailableView(
                            emptyTitle,
                            systemImage: "tray",
                            description: Text(emptyDescription)
                        )
                    } else {
                        ForEach(options, id: \.self) { option in
                            Button {
                                onSelect(option)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(option)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if option == selected {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(title)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert(addAlertTitle, isPresented: $showsAddAlert) {
                TextField(addFieldPlaceholder, text: $draft)
#if !os(macOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
#endif

                Button("新增") {
                    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onAdd(trimmed)
                        draft = ""
                        dismiss()
                    }
                }
                .disabled(
                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                Button("取消", role: .cancel) {
                    draft = ""
                }
            } message: {
                Text(addAlertMessage)
            }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 480)
#endif
    }
}

// MARK: - Preview

#Preview("有選項") {
    OptionPickerSheet(
        title: "選擇商品類別",
        addButtonTitle: "新增類別",
        emptyTitle: "尚無類別",
        emptyDescription: "透過上方「新增類別」加入第一個類別。",
        addAlertTitle: "新增商品類別",
        addFieldPlaceholder: "類別名稱",
        addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
        options: ["3C", "美妝", "精品", "食品"],
        selected: "美妝",
        onSelect: { _ in },
        onAdd: { _ in }
    )
}

#Preview("尚無選項") {
    OptionPickerSheet(
        title: "選擇付款方式",
        addButtonTitle: "新增付款方式",
        emptyTitle: "尚無付款方式",
        emptyDescription: "透過上方「新增付款方式」加入第一個項目。",
        addAlertTitle: "新增付款方式",
        addFieldPlaceholder: "付款方式名稱",
        addAlertMessage: "輸入新的付款方式名稱，加入後會立即套用至此訂單。",
        options: [],
        selected: "",
        onSelect: { _ in },
        onAdd: { _ in }
    )
}
