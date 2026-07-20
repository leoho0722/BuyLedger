//
//  LookupNameEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 主檔項目的單欄名稱表單 sheet
///
/// 取代原本以 `.alert` 承載輸入框的作法——alert 的職責是傳達需要立即決策的關鍵資訊，
/// 把輸入框與整段說明塞進去，在小螢幕大字級下會逼近需要捲動
///
/// 版面比照同目錄的 ``PaymentMethodEditorSheet``，同樣提供取消與儲存
struct LookupNameEditorSheet: View {

    // MARK: - View Properties

    /// Sheet 的標題 (顯示在 navigation bar)
    let title: LocalizedStringKey

    /// 表單下方的說明訊息；空字串時不顯示
    let message: String

    /// 名稱 TextField 的 placeholder
    let namePlaceholder: String

    /// 提交按鈕的文字
    let submitTitle: String

    /// 使用者按下提交時的 callback；caller 拿到已 trim 的名稱後負責寫入主檔
    let onSubmit: (_ name: String) -> Void

    /// 由 sheet 環境注入的 dismiss action
    @Environment(\.dismiss) private var dismiss

    /// 名稱輸入草稿
    @State private var draftName: String

    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @State private var showsDiscardConfirmation = false

    /// 表單開啟時的初始值快照；供 ``isDirty`` 判斷未儲存變更
    private let initialName: String

    // MARK: - Init

    /// 建立名稱表單 sheet
    /// - Parameters:
    ///   - title: navigation 標題
    ///   - message: 表單下方說明；空字串時不顯示
    ///   - namePlaceholder: 名稱 TextField placeholder
    ///   - submitTitle: 提交按鈕文字
    ///   - initialName: 名稱初始值；重新命名時帶入目前名稱，新增時留空
    ///   - onSubmit: 確認時的 callback，帶出已 trim 的名稱
    init(
        title: LocalizedStringKey,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        initialName: String = "",
        onSubmit: @escaping (_ name: String) -> Void
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self.onSubmit = onSubmit
        self._draftName = State(initialValue: initialName)
        self.initialName = initialName
    }

    // MARK: - View Body

    /// 名稱表單的畫面內容
    var body: some View {
        NavigationStack {
            formContent
        }
        // 單一欄位加一段說明，medium 已足夠；保留 large 供最大字級時展開
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
        .interactiveDismissDisabled(isDirty)
        .alert("捨棄變更", isPresented: $showsDiscardConfirmation) {
            Button("捨棄變更", role: .destructive) {
                dismiss()
            }

            Button("繼續編輯", role: .cancel) {}
        } message: {
            Text("這個項目有尚未儲存的變更，離開後將不會保留。")
        }
    }
}

// MARK: - ViewBuilder

private extension LookupNameEditorSheet {

    /// 表單內容：名稱欄位、說明與取消／儲存工具列
    @ViewBuilder
    var formContent: some View {
        Form {
            Section {
                TextField(LocalizedStringKey(namePlaceholder), text: $draftName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.none)
            } footer: {
                if !message.isEmpty {
                    Text(LocalizedStringKey(message))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if isDirty {
                        showsDiscardConfirmation = true
                    } else {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey(submitTitle)) {
                    onSubmit(trimmedName)
                    dismiss()
                }
                .disabled(!canSubmit)
            }
        }
    }
}

// MARK: - Private Method

private extension LookupNameEditorSheet {

    /// 去除首尾空白後的名稱
    var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 是否可提交：名稱非空且與初始值不同
    var canSubmit: Bool {
        !trimmedName.isEmpty && trimmedName != initialName
    }

    /// 是否有未儲存的變更
    var isDirty: Bool {
        trimmedName != initialName
    }
}

// MARK: - Preview

#Preview("主檔名稱表單") {
    LookupNameEditorSheet(
        title: "新增訂單來源",
        message: "輸入新的訂單來源名稱，加入後會立即套用。",
        namePlaceholder: "來源名稱",
        submitTitle: "新增"
    ) { _ in }
}
