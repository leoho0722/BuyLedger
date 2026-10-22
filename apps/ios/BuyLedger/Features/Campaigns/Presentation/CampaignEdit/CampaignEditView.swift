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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 表單的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<CampaignEditFeature>

    /// 鍵盤焦點，鏡像表單狀態中的 `focusedField`
    @FocusState private var focusedField: CampaignEditFeature.State.Field?

    // MARK: - Body

    /// 組合表單區段、工具列與捨棄確認
    var body: some View {
        NavigationStack {
            Form {
                campaignInfoSection

                CampaignEditNotesSection(notes: $store.draft.notes, focusedField: $focusedField)
            }
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.root)
            .scrollDismissesKeyboard(.interactively)
            .bind($store.focusedField, to: $focusedField)
            .navigationTitle(Text(LocalizedStringKey(store.navigationTitleKey)))
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
        Section("campaigns.detail.label.campaignInformation") {
            TextField("orders.detail.label.campaignName", text: $store.draftName)
                .textContentType(nil)
                .focused($focusedField, equals: .name)
                .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.nameField)

            if let nameConflictMessage = store.nameConflictMessage {
                Text(LocalizedStringKey(nameConflictMessage))
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blRed)
            }

            // 沿用訂單編輯頁的做法：`DatePicker` 明確指定 `locale`，避免退回開發語言而顯示英文
            DatePicker(
                "campaigns.detail.label.openingDate",
                selection: $store.draft.openDate,
                displayedComponents: .date
            )
            .environment(\.locale, locale)
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.openDatePicker)

            DatePicker(
                "campaigns.detail.label.closeDate",
                selection: $store.draft.closeDate,
                displayedComponents: .date
            )
            .environment(\.locale, locale)
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.closeDatePicker)

            Picker("orders.list.label.status", selection: $store.draft.status) {
                ForEach(CampaignStatus.allCases) {
                    Text(LocalizedStringKey($0.title))
                        .tag($0)
                }
            }

            Toggle("campaigns.detail.label.orderReminder", isOn: $store.draft.wantsReminder)
                .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.reminderToggle)

            if store.draft.wantsReminder {
                DatePicker(
                    "campaigns.detail.label.reminderTime",
                    selection: $store.draft.reminderTimestamp,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .environment(\.locale, locale)
                .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.reminderDatePicker)
            }
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
            .accessibilityLabel(Text("common.action.cancel"))
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
            .accessibilityLabel(Text("orders.edit.button.save"))
            .accessibilityIdentifier(BLAccessibilityID.CampaignEdit.saveButton)
            .disabled(!store.canSave)
        }
    }
}

// MARK: - Preview

#Preview("campaigns.list.label.addCampaign") {
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
