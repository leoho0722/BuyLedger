//
//  SettingsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 設定頁畫面。
///
/// 對應設計稿 iPhone 設定 / 更多頁的 sections：外觀、通知、預設幣別、匯出資料、關於。
struct SettingsView: View {

    // MARK: - View Properties

    /// 設定 store。
    @Bindable var store: StoreOf<SettingsFeature>

    // MARK: - View Body

    /// 設定頁畫面內容。
    var body: some View {
        Form {
            Section("外觀") {
                Picker("介面模式", selection: $store.appearance) {
                    ForEach(AppearancePreference.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }

            Section("通知") {
                Toggle("接收訂單提醒", isOn: $store.notificationsEnabled)
            }

            Section("預設幣別") {
                Picker("新訂單預設", selection: $store.defaultCurrency) {
                    ForEach(CurrencyCode.allCases) { code in
                        Text("\(code.flag) \(code.rawValue)").tag(code)
                    }
                }
            }

            Section("資料") {
                Button("匯出 CSV") { }
                    .disabled(true)

                Text("匯出與雲端同步功能尚未實作。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("關於") {
                LabeledContent("版本", value: appVersion)
                LabeledContent("作者", value: "Leo Ho")
            }
        }
        .navigationTitle("設定")
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - Private Method

private extension SettingsView {

    /// 從 bundle info 讀出版本號。
    var appVersion: String {
        let dictionary = Bundle.main.infoDictionary
        let short = dictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = dictionary?["CFBundleVersion"] as? String ?? "—"

        return "\(short) (\(build))"
    }
}

// MARK: - Preview

#Preview("設定") {
    NavigationStack {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}
