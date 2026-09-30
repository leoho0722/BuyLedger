//
//  SettingsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 設定頁畫面
struct SettingsView: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 月度目標欄位的鍵盤焦點
    @FocusState private var isGoalFieldFocused: Bool

    /// 設定狀態、持久化事件與畫面操作來源
    @Bindable var store: StoreOf<SettingsFeature>

    // MARK: - Body

    /// 只組合設定頁的六個區段與整頁修飾器
    var body: some View {
        Form {
            languageSection
            aiSummarySection
            defaultCurrencySection
            monthlyGoalSection
            appLockSection
            aboutSection
        }
        .accessibilityIdentifier(BLAccessibilityID.Settings.root)
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isGoalFieldFocused, to: $isGoalFieldFocused)
        .task {
            await store.send(.view(.task)).finish()
        }
        .rootNavigationTitle("設定", language: store.language)
        .toolbar {
            keyboardToolbar
        }
        .alert(
            $store.scope(state: \.appLock.enableFailureAlert, action: \.appLock.enableFailureAlert)
        )
    }
}

// MARK: - Private Views

private extension SettingsView {

    /// App 語言選擇區段
    var languageSection: some View {
        Section("語言") {
            Picker("App 語言", selection: $store.language) {
                ForEach(AppLanguage.allCases) { language in
                    // menu 會重建選項，identifier 可能無法傳到 item
                    Text(language.title)
                        .accessibilityIdentifier(
                            BLAccessibilityID.Settings.languageOption(language.rawValue)
                        )
                        .tag(language)
                }
            }
            .accessibilityIdentifier(BLAccessibilityID.Settings.languagePicker)
        }
    }

    /// AI 商品明細總結設定區段
    var aiSummarySection: some View {
        Section {
            Toggle("啟用 AI 總結", isOn: $store.isAISummaryEnabled)
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
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }

    /// 預設幣別設定區段
    var defaultCurrencySection: some View {
        Section("預設幣別") {
            NavigationLink {
                currencyPicker
            } label: {
                LabeledContent(
                    "新訂單預設",
                    value: CurrencyDisplayName.text(
                        code: store.defaultCurrency.rawValue,
                        language: AppLanguage(locale: locale)
                    )
                )
            }
            .accessibilityIdentifier(BLAccessibilityID.Settings.defaultCurrencyRow)
        }
    }

    /// 月度淨獲利目標設定區段
    var monthlyGoalSection: some View {
        Section {
            TextField(
                "目標金額",
                value: $store.monthlyProfitGoalTWD,
                format: .number.precision(.fractionLength(0)).grouping(.never)
            )
            .accessibilityIdentifier(BLAccessibilityID.Settings.monthlyGoalField)
            .keyboardType(.numberPad)
            .focused($isGoalFieldFocused)
        } header: {
            Text("月度淨獲利目標 (TWD)")
        } footer: {
            Text("Dashboard hero 卡的進度條依此值計算；設為 0 代表不顯示進度條。")
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }

    /// App 鎖定設定區段
    var appLockSection: some View {
        Section {
            Toggle(store.appLock.unlockButtonTitleKey, isOn: appLockToggleBinding)
                .accessibilityIdentifier(BLAccessibilityID.Settings.appLockToggle)
        } header: {
            Text("App 鎖定")
        } footer: {
            Text(store.appLock.protectionDescriptionKey)
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }

    /// App 版本與作者資訊區段
    var aboutSection: some View {
        Section("關於") {
            LabeledContent("版本", value: store.appVersion)
                .accessibilityIdentifier(BLAccessibilityID.Settings.versionRow)
            LabeledContent("作者", value: "Leo Ho")
        }
    }

    /// 預設幣別選擇器
    @ViewBuilder
    var currencyPicker: some View {
        let locale = locale
        let language = AppLanguage(locale: locale)

        OptionPickerSheet(
            title: "選擇預設幣別",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "尚無幣別",
            emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
            options: store.availableCurrencies.map(\.rawValue),
            selected: store.defaultCurrency.rawValue,
            displayName: { code in
                CurrencyDisplayName.text(code: code, language: language)
            },
            searchKeywords: { code in
                CurrencyDisplayName.searchKeywords(code: code, locale: locale)
            },
            onSelect: { code in
                store.send(.view(.defaultCurrencySelected(code)))
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
                store.send(.view(.aiSummaryModelSelected(model)))
            },
            onAdd: { model in
                store.send(.view(.aiSummaryModelSelected(model)))
            },
            isEmbedded: true
        )
    }
#endif

    /// 數字鍵盤的完成按鈕
    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()

            Button {
                store.isGoalFieldFocused = false
            } label: {
                Image(systemName: "checkmark")
            }
            .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
            .accessibilityLabel(Text("完成"))
        }
    }
}

// MARK: - Private Method

private extension SettingsView {

    /// App 鎖定開關的自訂 binding
    var appLockToggleBinding: Binding<Bool> {
        Binding(
            get: { store.appLock.isBiometricUnlockEnabled },
            set: { store.send(.appLock(.enableToggled($0))) }
        )
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
