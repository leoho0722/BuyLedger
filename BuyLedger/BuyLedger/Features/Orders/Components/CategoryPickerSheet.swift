//
//  CategoryPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 訂單編輯表單裡的「商品類別」選擇器，以 sheet 形式呈現。
///
/// 取代原本的 `Menu`：iOS Menu 因為是 `UIMenu` 的二次包裝，UIKit 端會把 Button action 排到 menu collapse 動畫結束後才派發給 SwiftUI，造成「選完類別 → 約 300ms 後 label 才更新」的可見延遲。改用 sheet 後，使用者點選類別時 binding 立即 commit，sheet 收合與 form label 更新解耦，視覺上不再卡頓。
struct CategoryPickerSheet: View {

    // MARK: - View Properties

    /// 目前可選的類別清單。
    let categories: [String]

    /// 目前已選中的類別；用來在列表中顯示勾選。
    let selected: String

    /// 使用者選擇既有類別時的 callback。
    let onSelect: (String) -> Void

    /// 使用者透過「新增類別」alert 確認新增類別時的 callback。
    let onAddCategory: (String) -> Void

    /// 由 sheet 環境注入的 dismiss action。
    @Environment(\.dismiss) private var dismiss

    /// 是否顯示「新增類別」alert。
    @State private var showsAddAlert = false

    /// 新增類別 alert 的輸入草稿。
    @State private var newCategoryDraft = ""

    // MARK: - View Body

    /// 類別選擇 sheet 的內容。
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        newCategoryDraft = ""
                        showsAddAlert = true
                    } label: {
                        Label("新增類別", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    if categories.isEmpty {
                        ContentUnavailableView(
                            "尚無類別",
                            systemImage: "tray",
                            description: Text("透過上方「新增類別」加入第一個類別。")
                        )
                    } else {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                onSelect(category)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(category)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if category == selected {
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
            .navigationTitle("選擇商品類別")
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
            .alert("新增商品類別", isPresented: $showsAddAlert) {
                TextField("類別名稱", text: $newCategoryDraft)
#if !os(macOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
#endif

                Button("新增") {
                    let trimmed = newCategoryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onAddCategory(trimmed)
                        newCategoryDraft = ""
                        dismiss()
                    }
                }
                .disabled(
                    newCategoryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                Button("取消", role: .cancel) {
                    newCategoryDraft = ""
                }
            } message: {
                Text("輸入新的商品類別名稱，加入後會立即套用至此訂單。")
            }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 480)
#endif
    }
}

// MARK: - Preview

#Preview("有類別") {
    CategoryPickerSheet(
        categories: ["3C", "美妝", "精品", "食品"],
        selected: "美妝",
        onSelect: { _ in },
        onAddCategory: { _ in }
    )
}

#Preview("尚無類別") {
    CategoryPickerSheet(
        categories: [],
        selected: "",
        onSelect: { _ in },
        onAddCategory: { _ in }
    )
}
