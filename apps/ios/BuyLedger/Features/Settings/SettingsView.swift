//
//  SettingsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 設定頁畫面
///
/// 對應設計稿 iPhone 設定 / 更多頁的 sections：外觀、通知、預設幣別、關於。資料匯出 / CloudKit 同步 section 暫時以 `#if false` 隱藏，待實作完成後再開啟
struct SettingsView: View {

    // MARK: - View Properties

    /// 設定 store
    @Bindable var store: StoreOf<SettingsFeature>


    // MARK: - View Body

    /// 設定頁畫面內容
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

            Section {
                Toggle("啟用 AI 總結", isOn: $store.useAiSummary)
#if DEBUG
                Button {
                    store.showsModelSheet = true
                } label: {
                    HStack {
                        Text("模型")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(store.aiSummaryModel)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
#endif
            } header: {
                Text("AI 商品明細總結")
            } footer: {
                Text("在訂單列表點「AI 總結」(sparkles) 即可彙整目前篩選的商品明細。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("預設幣別") {
                Button {
                    store.showsCurrencySheet = true
                } label: {
                    HStack {
                        Text("新訂單預設")
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
            }

            Section {
                TextField(
                    "目標金額",
                    value: $store.monthlyProfitGoalTwd,
                    format: .number.precision(.fractionLength(0))
                )
                .keyboardType(.numberPad)
            } header: {
                Text("月度淨獲利目標 (TWD)")
            } footer: {
                Text("Dashboard hero 卡的進度條依此值計算；設為 0 代表不顯示進度條。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

#if false
            Section("資料") {
                Button("匯出 CSV") { }
                    .disabled(true)

                Text("匯出與雲端同步功能尚未實作。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
#endif

            Section("關於") {
                LabeledContent("版本", value: appVersion)
                LabeledContent("作者", value: "Leo Ho")
            }
        }
        .navigationTitle("設定")
        .sheet(isPresented: $store.showsCurrencySheet) {
            OptionPickerSheet(
                title: "選擇預設幣別",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "尚無幣別",
                emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                options: store.availableCurrencies.map(\.rawValue),
                selected: store.defaultCurrency.rawValue,
                displayName: { code in
                    let locale = Locale.preferred()
                    let name = locale.localizedString(forCurrencyCode: code) ?? ""
                    return name.isEmpty ? code : "\(code) · \(name)"
                },
                searchKeywords: { code in
                    Locale.preferred()
                        .localizedString(forCurrencyCode: code) ?? ""
                },
                onSelect: { code in
                    store.defaultCurrency = CurrencyCode(rawValue: code)
                }
            )
        }
#if DEBUG
        .sheet(isPresented: $store.showsModelSheet) {
            OptionPickerSheet(
                title: "選擇 AI 模型",
                allowsAdd: true,
                searchable: false,
                addButtonTitle: "自訂模型",
                emptyTitle: "尚無模型",
                emptyDescription: "輸入自訂模型名稱以開始使用。",
                addAlertTitle: "自訂 AI 模型",
                addFieldPlaceholder: "模型名稱 (例如 gpt-oss:120b)",
                addAlertMessage: "輸入 Ollama Cloud 上可用的模型名稱。",
                options: AISummaryModelCatalog.candidates,
                selected: store.aiSummaryModel,
                onSelect: { model in
                    store.aiSummaryModel = model
                },
                onAdd: { model in
                    store.aiSummaryModel = model
                }
            )
        }
#endif
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - Private Method

private extension SettingsView {

    /// 把幣別 ISO code 轉成「TWD · 新台幣」顯示文字
    /// - Parameter currency: 幣別
    /// - Returns: 顯示字串
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        let locale = Locale.preferred()
        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : "\(currency.rawValue) · \(name)"
    }

    /// 從 bundle info 讀出版本號
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
