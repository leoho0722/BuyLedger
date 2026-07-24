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
/// 對應設計稿 iPhone 設定 / 更多頁的 sections：外觀、預設幣別、關於。資料匯出 / CloudKit 同步 section 暫時以 `#if false` 隱藏，待實作完成後再開啟
struct SettingsView: View {

    // MARK: - View Properties

    /// 設定 store
    @Bindable var store: StoreOf<SettingsFeature>

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 月度目標欄位的鍵盤焦點；實際狀態由 ``SettingsFeature/State/isGoalFieldFocused`` 持有
    @FocusState private var isGoalFieldFocused: Bool

    // MARK: - View Body

    /// 設定頁畫面內容
    var body: some View {
        Form {
            Section("語言") {
                Picker("App 語言", selection: $store.language) {
                    ForEach(AppLanguage.allCases) { language in
                        // Picker 以 menu 呈現時選項由 UIKit 重建，此 identifier 可能傳不到 menu item，待實測確認
                        Text(language.title)
                            .accessibilityIdentifier(BLAccessibilityID.Settings.languageOption(language.rawValue))
                            .tag(language)
                    }
                }
                .accessibilityIdentifier(BLAccessibilityID.Settings.languagePicker)
            }

            Section {
                Toggle("啟用 AI 總結", isOn: $store.useAiSummary)
                    .accessibilityIdentifier(BLAccessibilityID.Settings.aiSummaryToggle)
#if DEBUG
                NavigationLink {
                    modelPicker
                } label: {
                    LabeledContent("模型", value: store.aiSummaryModel)
                }
                .accessibilityIdentifier(BLAccessibilityID.Settings.aiSummaryModelRow)
#endif
            } header: {
                Text("AI 商品明細總結")
            } footer: {
                Text("在訂單列表點「AI 總結」(sparkles) 即可彙整目前篩選的商品明細。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("預設幣別") {
                NavigationLink {
                    currencyPicker
                } label: {
                    LabeledContent("新訂單預設", value: currencyDisplayText(for: store.defaultCurrency))
                }
                .accessibilityIdentifier(BLAccessibilityID.Settings.defaultCurrencyRow)
            }

            Section {
                TextField(
                    "目標金額",
                    value: $store.monthlyProfitGoalTwd,
                    format: .number.precision(.fractionLength(0))
                )
                .accessibilityIdentifier(BLAccessibilityID.Settings.monthlyGoalField)
                .keyboardType(.numberPad)
                .focused($isGoalFieldFocused)
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
                    .accessibilityIdentifier(BLAccessibilityID.Settings.versionRow)
                LabeledContent("作者", value: "Leo Ho")
            }
        }
        .accessibilityIdentifier(BLAccessibilityID.Settings.root)
        .rootNavigationTitle("設定", language: store.language)
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isGoalFieldFocused, to: $isGoalFieldFocused)
        .toolbar {
            // 此畫面唯一的輸入為數字鍵盤，沒有 return 鍵可收
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button {
                    store.send(.binding(.set(\.isGoalFieldFocused, false)))
                } label: {
                    Image(systemName: "checkmark")
                }
                .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
                .accessibilityLabel(Text("完成"))
            }
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension SettingsView {

    /// 預設幣別選擇器
    ///
    /// 以 push 呈現 (`isEmbedded`)，由 Settings 所在的導覽堆疊提供標題列與 Back
    @ViewBuilder
    var currencyPicker: some View {
        let locale = locale

        OptionPickerSheet(
            title: "選擇預設幣別",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "尚無幣別",
            emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
            options: store.availableCurrencies.map(\.rawValue),
            selected: store.defaultCurrency.rawValue,
            displayName: { code in
                let name = locale.localizedString(forCurrencyCode: code) ?? ""
                return name.isEmpty ? code : "\(code) · \(name)"
            },
            searchKeywords: { code in
                locale.localizedString(forCurrencyCode: code) ?? ""
            },
            onSelect: { code in
                store.send(.defaultCurrencySelected(code))
            },
            isEmbedded: true
        )
    }

#if DEBUG
    /// AI 總結模型選擇器 (僅 DEBUG 建置提供)
    @ViewBuilder
    var modelPicker: some View {
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
                store.send(.aiSummaryModelSelected(model))
            },
            onAdd: { model in
                store.send(.aiSummaryModelSelected(model))
            },
            isEmbedded: true
        )
    }
#endif
}

// MARK: - Private Method

private extension SettingsView {

    /// 依 App 選定 locale 產生幣別顯示文字
    /// 中文顯示名稱 (如「新台幣」)、其他語言顯示 ISO code (如「TWD」)
    /// - Parameter currency: 幣別
    /// - Returns: 顯示字串
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        guard locale.language.languageCode?.identifier == "zh" else {
            return currency.rawValue
        }

        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : name
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
