//
//  CampaignEditView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 新增或編輯開團的表單。
struct CampaignEditView: View {

    // MARK: - View Properties

    /// 表單 store。
    @Bindable var store: StoreOf<CampaignEditFeature>

    /// TCA 注入的 locale；作為 ``deviceLocale`` 取不到偏好語言時的 fallback。
    @Dependency(\.locale) private var locale

    // MARK: - View Body

    /// 表單的畫面內容。
    var body: some View {
        NavigationStack {
            Form {
                Section("開團資訊") {
                    TextField("開團名稱", text: $store.draftName)

                    DatePicker(
                        "開團日期",
                        selection: $store.draftOpenDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, deviceLocale)

                    DatePicker(
                        "結單日期",
                        selection: $store.draftCloseDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, deviceLocale)

                    Picker("狀態", selection: $store.draftStatus) {
                        ForEach(CampaignStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                }

                Section("備註") {
                    TextField("選填", text: $store.draftNotes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(store.original == nil ? "新增開團" : "編輯開團")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        store.send(.cancelTapped)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        store.send(.saveTapped)
                    }
                    .disabled(store.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Private Method

private extension CampaignEditView {

    /// 使用者在系統「語言與地區」實際偏好的 locale；與「新增/編輯訂單頁」的 DatePicker 一致。未提供偏好語言時退回注入的 `@Dependency(\.locale)`。選用 `preferredLanguages` 的原因見 ``Locale/preferred(fallback:)``。
    var deviceLocale: Locale {
        Locale.preferred(fallback: locale)
    }
}

// MARK: - Preview

#Preview("新增開團") {
    CampaignEditView(
        store: Store(initialState: CampaignEditFeature.State()) {
            CampaignEditFeature()
        }
    )
}
