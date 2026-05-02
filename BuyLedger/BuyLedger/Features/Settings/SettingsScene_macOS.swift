//
//  SettingsScene_macOS.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

#if os(macOS)

import ComposableArchitecture
import SwiftUI

/// macOS 偏好設定視窗的內容視圖。
///
/// 對應 macOS 標準 `Settings { ... }` scene 的呈現：以 ``TabView`` 將設定分群，每個分頁採用 ``Form`` + `.formStyle(.grouped)`，並固定視窗最小尺寸以符合 System Settings 風格。
struct SettingsScene_macOS: View {

    // MARK: - View Properties

    /// 設定 store。
    @Bindable var store: StoreOf<SettingsFeature>

    // MARK: - View Body

    /// 偏好設定視窗的畫面內容。
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("一般", systemImage: "gearshape")
                }

            notificationsTab
                .tabItem {
                    Label("通知", systemImage: "bell.badge")
                }

            defaultsTab
                .tabItem {
                    Label("預設值", systemImage: "tray.full")
                }

            dataTab
                .tabItem {
                    Label("資料", systemImage: "externaldrive")
                }

            aboutTab
                .tabItem {
                    Label("關於", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 520, minHeight: 340)
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension SettingsScene_macOS {

    /// 一般偏好分頁：外觀模式。
    var generalTab: some View {
        Form {
            Section {
                Picker("介面模式", selection: $store.appearance) {
                    ForEach(AppearancePreference.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("外觀")
            } footer: {
                Text("選擇「自動」會跟隨 macOS 系統的淺色 / 深色設定。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// 通知分頁：是否接收提醒。
    var notificationsTab: some View {
        Form {
            Section {
                Toggle("接收訂單提醒", isOn: $store.notificationsEnabled)
            } header: {
                Text("提醒")
            } footer: {
                Text("關閉後將不再從 macOS 系統通知中心收到訂單狀態變更。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// 預設值分頁：建立新訂單時帶入的幣別等預設。
    var defaultsTab: some View {
        Form {
            Section {
                Picker("新訂單預設幣別", selection: $store.defaultCurrency) {
                    ForEach(CurrencyCode.allCases) { code in
                        Text("\(code.flag) \(code.rawValue)").tag(code)
                    }
                }
            } header: {
                Text("新訂單")
            } footer: {
                Text("此設定會套用到所有新建立的訂單；既有訂單不受影響。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// 資料分頁：CSV 匯出與雲端同步占位。
    var dataTab: some View {
        Form {
            Section {
                LabeledContent("匯出格式") {
                    Text("CSV").foregroundStyle(.secondary)
                }

                Button {
                    // 尚未實作。
                } label: {
                    Label("匯出全部訂單…", systemImage: "square.and.arrow.up")
                }
                .disabled(true)
            } header: {
                Text("資料匯出")
            } footer: {
                Text("匯出與雲端同步功能尚未實作。後續會接 SwiftData + CloudKit 同步。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// 關於分頁：版本與作者。
    var aboutTab: some View {
        Form {
            Section {
                LabeledContent("版本", value: appVersion)
                LabeledContent("作者", value: "Leo Ho")
                LabeledContent("Bundle ID") {
                    Text(Bundle.main.bundleIdentifier ?? "—")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } header: {
                Text("BuyLedger")
            } footer: {
                Text("© 2026 Leo Ho. 為個人代購業務而生的本地優先帳本。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Private Method

private extension SettingsScene_macOS {

    /// 從 bundle info 讀出 `1.0 (1)` 形式的版本字串。
    var appVersion: String {
        let dictionary = Bundle.main.infoDictionary
        let short = dictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = dictionary?["CFBundleVersion"] as? String ?? "—"

        return "\(short) (\(build))"
    }
}

// MARK: - Preview

#Preview("macOS 偏好設定") {
    SettingsScene_macOS(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}

#endif
