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

    /// TCA 注入的 locale；作為 ``deviceLocale`` 取不到偏好語言時的 fallback
    @Dependency(\.locale) private var locale

    // MARK: - View Body

    /// 表單的畫面內容
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

                    HStack {
                        Text("訂購提醒")

                        Spacer(minLength: 0)

                        Button(role: store.wantsReminder ? .destructive : nil) {
                            store.send(store.wantsReminder ? .removeReminderTapped : .reminderPickerRequested)
                        } label: {
                            Label(
                                store.wantsReminder ? "移除提醒" : "新增提醒",
                                systemImage: store.wantsReminder ? "bell.slash" : "bell"
                            )
                            // 強制 icon 與文字貼合：Form row 的自動 label style 會把 icon/title 撐到兩端
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(store.wantsReminder ? Color.red : Color.blue)
                        }
                        .buttonStyle(.borderless)
                    }
                    .sheet(isPresented: $store.isReminderPickerPresented) {
                        reminderPickerSheet
                    }

                    if store.wantsReminder {
                        Button {
                            store.send(.reminderPickerRequested)
                        } label: {
                            LabeledContent(
                                "提醒時間",
                                value: CampaignFormatters.reminderTimestamp(store.reminderTimestamp)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("備註") {
                    TextField("選填", text: $store.draftNotes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(store.original == nil ? "新增開團" : "編輯開團")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - ViewBuilder

private extension CampaignEditView {

    /// 訂購提醒的日期＋時間選擇 sheet：以 graphical `DatePicker` 讓使用者自選日期與提示時間，按「加入提醒／完成」提交、「取消」不提交；高度取螢幕 70% (`.fraction(0.7)`)
    @ViewBuilder
    var reminderPickerSheet: some View {
        NavigationStack {
            DatePicker(
                "提醒時間",
                selection: $store.draftReminderTimestamp,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .environment(\.locale, deviceLocale)
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("訂購提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        store.send(.reminderPickerCancelled)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(store.wantsReminder ? "完成" : "加入提醒") {
                        store.send(.reminderPickerConfirmed)
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.7)])
    }
}

// MARK: - Private Method

private extension CampaignEditView {

    /// 使用者在系統「語言與地區」實際偏好的 locale；與「新增/編輯訂單頁」的 DatePicker 一致。未提供偏好語言時退回注入的 `@Dependency(\.locale)`。選用 `preferredLanguages` 的原因見 ``Locale/preferred(fallback:)``
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
