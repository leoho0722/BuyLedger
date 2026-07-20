//
//  CampaignEditView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 新增或編輯開團的表單
struct CampaignEditView: View {

    // MARK: - View Properties

    /// 表單 store
    @Bindable var store: StoreOf<CampaignEditFeature>

    /// 鍵盤焦點；實際狀態由 ``CampaignEditFeature/State/focusedField`` 持有
    @FocusState private var focusedField: CampaignEditFeature.State.Field?

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    // MARK: - View Body

    /// 表單的畫面內容
    var body: some View {
        NavigationStack {
            Form {
                Section("開團資訊") {
                    TextField("開團名稱", text: $store.draftName)
                        .textContentType(.none)
                        .focused($focusedField, equals: .name)

                    DatePicker(
                        "開團日期",
                        selection: $store.draftOpenDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, locale)

                    DatePicker(
                        "結單日期",
                        selection: $store.draftCloseDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, locale)

                    Picker("狀態", selection: $store.draftStatus) {
                        ForEach(CampaignStatus.allCases) { status in
                            Text(LocalizedStringKey(status.title)).tag(status)
                        }
                    }

                    Toggle("訂購提醒", isOn: $store.wantsReminder)

                    if store.wantsReminder {
                        // 提醒時間以原生 inline DatePicker 編輯 (同上方開團／結單日期列)，點擊跳系統月曆／時間浮層
                        DatePicker(
                            "提醒時間",
                            selection: $store.reminderTimestamp,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .environment(\.locale, locale)
                    }
                }

                Section("備註") {
                    TextField("選填", text: $store.draftNotes, axis: .vertical)
                        .textContentType(.none)
                        .focused($focusedField, equals: .notes)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(Text(LocalizedStringKey(store.original == nil ? "新增開團" : "編輯開團")))
            .scrollDismissesKeyboard(.interactively)
            .bind($store.focusedField, to: $focusedField)
            .dismissKeyboardOnBackgroundTap(focus: $focusedField)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.cancelTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("取消"))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        store.send(.saveTapped)
                    }
                    .disabled(store.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
        .interactiveDismissDisabled(store.isDirty)
        .alert($store.scope(state: \.discardConfirmation, action: \.discardConfirmation))
    }
}

// MARK: - Preview

#Preview("新增開團") {
    CampaignEditView(
        store: Store(
            initialState: CampaignEditFeature.State(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                currentDate: Date(timeIntervalSince1970: 0),
                reminderTimestamp: Date(timeIntervalSince1970: 0)
            )
        ) {
            CampaignEditFeature()
        }
    )
}
