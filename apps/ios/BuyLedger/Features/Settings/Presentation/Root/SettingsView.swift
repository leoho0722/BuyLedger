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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 設定狀態、持久化事件與畫面操作來源
    @Bindable var store: StoreOf<SettingsFeature>

    /// 月度目標欄位的鍵盤焦點
    @FocusState private var isGoalFieldFocused: Bool

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
        .rootNavigationTitle("orders.edit.title.settings", language: store.language)
        .toolbar {
            keyboardToolbar
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

// MARK: - Private Views

private extension SettingsView {

    /// App 語言選擇區段
    var languageSection: some View {
        Section("orders.list.label.language") {
            Picker("orders.detail.label.appLanguage", selection: $store.language) {
                ForEach(AppLanguage.allCases) {
                    // menu 會重建選項，identifier 可能無法傳到 item
                    Text(verbatim: $0.title)
                        .accessibilityIdentifier(
                            BLAccessibilityID.Settings.languageOption($0.rawValue)
                        )
                        .tag($0)
                }
            }
            .accessibilityIdentifier(BLAccessibilityID.Settings.languagePicker)
        }
    }

    /// AI 商品明細總結設定區段
    var aiSummarySection: some View {
        Section {
            Toggle("settings.preference.label.enableAiSummary", isOn: $store.isAISummaryEnabled)
                .accessibilityIdentifier(BLAccessibilityID.Settings.aiSummaryToggle)

#if DEBUG
            NavigationLink {
                modelPicker
            } label: {
                LabeledContent("orders.general.label.model", value: store.aiSummaryModel)
            }
            .accessibilityIdentifier(BLAccessibilityID.Settings.aiSummaryModelRow)
#endif
        } header: {
            Text("orders.general.label.aiItemSummary")
        } footer: {
            Text("settings.preference.message.tapAiSummary")
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)
        }
    }

    /// 預設幣別設定區段
    var defaultCurrencySection: some View {
        Section("orders.edit.label.defaultCurrency") {
            NavigationLink {
                currencyPicker
            } label: {
                LabeledContent(
                    "orders.general.label.newOrderDefault",
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
                "dashboard.overview.label.goalAmount",
                value: $store.monthlyProfitGoalTWD,
                format: .number.precision(.fractionLength(0)).grouping(.never)
            )
            .accessibilityIdentifier(BLAccessibilityID.Settings.monthlyGoalField)
            .keyboardType(.numberPad)
            .focused($isGoalFieldFocused)
        } header: {
            Text("settings.preference.label.monthlyNetProfit")
        } footer: {
            Text("settings.preference.message.dashboardHeroProgress")
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)
        }
    }

    /// App 鎖定設定區段
    var appLockSection: some View {
        Section {
            Toggle(
                AppLockFormatters.unlockTitle(for: store.biometryType),
                isOn: appLockToggleBinding
            )
            .accessibilityIdentifier(BLAccessibilityID.Settings.appLockToggle)
        } header: {
            Text("settings.preference.label.appLock")
        } footer: {
            Text(AppLockFormatters.protectionDescription(for: store.biometryType))
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)
        }
    }

    /// App 版本與作者資訊區段
    var aboutSection: some View {
        Section("settings.preference.label.about") {
            LabeledContent("settings.preference.label.version", value: store.appVersion)
                .accessibilityIdentifier(BLAccessibilityID.Settings.versionRow)

            LabeledContent("settings.preference.label.author", value: "Leo Ho")
        }
    }

    /// 預設幣別選擇器
    @ViewBuilder
    var currencyPicker: some View {
        OptionPickerSheet(
            title: "settings.preference.label.selectDefaultCurrency",
            options: store.availableCurrencies.map(\.rawValue),
            selection: .single(
                selected: store.defaultCurrency.rawValue,
                onSelect: {
                    store.send(.view(.defaultCurrencySelected($0)))
                }
            ),
            emptyState: .init(
                title: "orders.edit.label.currenciesAvailable",
                description: "orders.edit.message.internetConnectionRequired"
            ),
            labeling: CurrencyDisplayName.optionLabeling(locale: locale),
            isSearchEnabled: true,
            isEmbedded: true
        )
    }

#if DEBUG
    /// AI 總結模型選擇器 (僅 DEBUG 建置提供)
    @ViewBuilder
    var modelPicker: some View {
        OptionPickerSheet(
            title: "settings.preference.label.selectAiModel",
            options: AISummaryModelCatalog.candidates,
            selection: .single(
                selected: store.aiSummaryModel,
                onSelect: {
                    store.send(.view(.aiSummaryModelSelected($0)))
                }
            ),
            addition: .prompt(
                .init(
                    buttonTitle: "settings.preference.label.customModel",
                    title: "settings.preference.label.customAiModel",
                    message: "settings.preference.message.enterModelName",
                    placeholder: "settings.preference.message.modelNameFor"
                )
            ) {
                store.send(.view(.aiSummaryModelSelected($0)))
            },
            emptyState: .init(
                title: "settings.preference.label.modelsAvailable",
                description: "settings.preference.message.enterCustomModel"
            ),
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
            .accessibilityLabel(Text("common.action.button.done"))
        }
    }
}

// MARK: - Private Method

private extension SettingsView {

    /// App 鎖定開關的自訂 binding
    var appLockToggleBinding: Binding<Bool> {
        Binding {
            store.isBiometricUnlockEnabled
        } set: {
            store.send(.view(.appLockToggled($0)))
        }
    }
}

// MARK: - Preview

#Preview("orders.edit.title.settings") {
    NavigationStack {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}
