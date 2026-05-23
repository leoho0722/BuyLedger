//
//  SettingsMacView.swift
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
struct SettingsMacView: View {

    // MARK: - View Properties

    /// 設定 store。
    @Bindable var store: StoreOf<SettingsFeature>

    /// 是否顯示「預設幣別」選擇 sheet。
    @State private var showsCurrencySheet = false

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

#if false
            dataTab
                .tabItem {
                    Label("資料", systemImage: "externaldrive")
                }
#endif

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

private extension SettingsMacView {

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

    /// 預設值分頁：建立新訂單時帶入的幣別等預設與月度損益目標。
    var defaultsTab: some View {
        Form {
            Section {
                Button {
                    showsCurrencySheet = true
                } label: {
                    HStack {
                        Text("新訂單預設幣別")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(currencyDisplayText(for: store.defaultCurrency))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showsCurrencySheet) {
                    OptionPickerSheet(
                        title: "選擇預設幣別",
                        allowsAdd: false,
                        searchable: true,
                        emptyTitle: "尚無幣別",
                        emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                        options: store.availableCurrencies.map(\.rawValue),
                        selected: store.defaultCurrency.rawValue,
                        displayName: { code in
                            let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                            let name = locale.localizedString(forCurrencyCode: code) ?? ""
                            return name.isEmpty ? code : "\(code) · \(name)"
                        },
                        searchKeywords: { code in
                            Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                                .localizedString(forCurrencyCode: code) ?? ""
                        },
                        onSelect: { code in
                            store.defaultCurrency = CurrencyCode(rawValue: code)
                        }
                    )
                }
            } header: {
                Text("新訂單")
            } footer: {
                Text("此設定會套用到所有新建立的訂單；既有訂單不受影響。")
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField(
                    "目標金額",
                    value: $store.monthlyProfitGoalTwd,
                    format: .number.precision(.fractionLength(0))
                )
            } header: {
                Text("月度淨獲利目標（TWD）")
            } footer: {
                Text("Dashboard hero 卡的進度條依此值計算；設為 0 代表不顯示進度條。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

#if false
    /// 資料分頁：CSV 匯出與雲端同步占位（暫時以 `#if false` 隱藏，待實作完成後再開啟）。
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
#endif

    /// 關於分頁：版本與作者。
    var aboutTab: some View {
        Form {
            Section {
                LabeledContent("版本", value: appVersion)
                LabeledContent("作者", value: "Leo Ho")
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

private extension SettingsMacView {

    /// 從 bundle info 讀出 `1.0 (1)` 形式的版本字串。
    var appVersion: String {
        let dictionary = Bundle.main.infoDictionary
        let short = dictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = dictionary?["CFBundleVersion"] as? String ?? "—"

        return "\(short) (\(build))"
    }

    /// 把幣別 ISO code 轉成「TWD · 新台幣」顯示文字。
    /// - Parameter currency: 幣別。
    /// - Returns: 顯示字串。
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : "\(currency.rawValue) · \(name)"
    }
}

// MARK: - Preview

#Preview("macOS 偏好設定") {
    SettingsMacView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}

#endif
