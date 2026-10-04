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

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 鍵盤焦點，鏡像表單狀態中的 `focusedField`
    @FocusState private var focusedField: CampaignEditFeature.State.Field?

    /// 表單的狀態與事件來源，由開團容器開啟表單時建立
    @Bindable var store: StoreOf<CampaignEditFeature>

    // MARK: - Body

    /// 組合表單區段、工具列與捨棄確認
    var body: some View {
        NavigationStack {
            Form {
                campaignInfoSection

                notesSection
            }
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.root)
            .scrollDismissesKeyboard(.interactively)
            .bind($store.focusedField, to: $focusedField)
            .navigationTitle(Text(LocalizedStringKey(store.original == nil ? "新增開團" : "編輯開團")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbarItem

                saveToolbarItem
            }
        }
        // 有未儲存變更時阻擋下滑關閉，取消鍵改以彈窗確認
        .interactiveDismissDisabled(store.isDirty)
        .alert($store.scope(state: \.discardConfirmation, action: \.discardConfirmation))
    }
}

// MARK: - Private Views

private extension CampaignEditView {

    /// 開團名稱、日期、狀態與訂購提醒的輸入欄位
    var campaignInfoSection: some View {
        Section("開團資訊") {
            TextField("開團名稱", text: $store.draftName)
                .textContentType(nil)
                .focused($focusedField, equals: .name)
                .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.nameField)

            if let nameConflictMessage = store.nameConflictMessage {
                Text(LocalizedStringKey(nameConflictMessage))
                    .blTextStyle(.footnote)
                    .foregroundStyle(BLPalette().red)
            }

            // 沿用訂單編輯頁的做法：DatePicker 明確指定 locale，避免退回開發語言而顯示英文
            DatePicker("開團日期", selection: $store.draft.openDate, displayedComponents: .date)
                .environment(\.locale, locale)

            DatePicker("結單日期", selection: $store.draft.closeDate, displayedComponents: .date)
                .environment(\.locale, locale)

            Picker("狀態", selection: $store.draft.status) {
                ForEach(CampaignStatus.allCases) {
                    Text(LocalizedStringKey($0.title))
                        .tag($0)
                }
            }

            Toggle("訂購提醒", isOn: $store.draft.wantsReminder)
                .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.reminderToggle)

            if store.draft.wantsReminder {
                DatePicker(
                    "提醒時間",
                    selection: $store.draft.reminderTimestamp,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .environment(\.locale, locale)
            }
        }
    }

    /// 備註欄，可輸入多行
    var notesSection: some View {
        Section("備註") {
            TextField("選填", text: $store.draft.notes, axis: .vertical)
                .lineLimit(2...5)
                .textContentType(nil)
                .focused($focusedField, equals: .notes)
        }
    }

    /// 送出取消意圖，是否顯示捨棄確認由表單決定
    var cancelToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                store.send(.view(.cancelButtonTapped))
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text("取消"))
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.cancelButton)
        }
    }

    /// 名稱有效時可送出儲存意圖，重名由父層以最新清單驗證
    var saveToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                store.send(.view(.saveButtonTapped))
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(Text("儲存"))
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.saveButton)
            .disabled(!store.canSave)
        }
    }
}

// MARK: - Preview

#Preview("新增開團") {
    CampaignEditView(
        store: Store(
            initialState: CampaignEditFeature.State(
                id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                currentDate: Date(timeIntervalSince1970: 0),
                reminderTimestamp: Date(timeIntervalSince1970: 0)
            )
        ) {
            CampaignEditFeature()
        }
    )
}
