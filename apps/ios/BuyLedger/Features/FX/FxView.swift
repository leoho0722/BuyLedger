//
//  FxView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 匯率工具畫面
struct FxView: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 金額欄位的鍵盤焦點
    /// 實際狀態由 ``FxFeature/State/isAmountFieldFocused`` 持有
    @FocusState private var isAmountFieldFocused: Bool

    /// 金額輸入欄與換算結果的字級，隨 Dynamic Type 縮放 (以 `.title` 為基準)
    @ScaledMetric(relativeTo: .title) private var heroAmountSize: CGFloat = 32

    /// FX 功能 store
    @Bindable var store: StoreOf<FxFeature>

    // MARK: - Body

    /// FX 畫面內容
    var body: some View {
        ScrollView {
            content
                .padding(BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(BLAccessibilityID.Fx.root)
        .background(palette.background)
        .navigationTitle(Text("匯率工具"))
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isAmountFieldFocused, to: $isAmountFieldFocused)
        .toolbar {
            keyboardToolbar
        }
        .task {
            await store.send(.view(.task)).finish()
        }
        .sheet(
            isPresented: Binding(
                $store.scope(state: \.$destination, action: \.destination).currencyPicker
            )
        ) {
            currencyPickerSheet
        }
    }
}

// MARK: - Private Views

private extension FxView {

    /// FX 畫面主要內容
    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: BLSpacing.large) {
            FxStatusBanner(
                isLoading: store.isLoading,
                errorMessage: store.errorMessage,
                snapshotDate: store.snapshot?.date,
                onRetry: { store.send(.view(.retryTapped)) }
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Fx.statusBanner)

            converterCard

            quickAmountRow

            FxRatesList(
                currencies: store.ratesListCurrencies,
                snapshotDate: store.snapshot?.date,
                rate: { currency in
                    store.state.displayRate(for: currency)
                }
            )
        }
    }

    /// 換算卡片：幣別選擇、金額輸入與 TWD 結果
    @ViewBuilder
    var converterCard: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("從")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                currencyPicker

                Text("金額")
                    .padding(.top, BLSpacing.small)
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                amountField

                Divider()
                    .padding(.vertical, BLSpacing.small)

                conversionResult
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 來源幣別選擇按鈕
    @ViewBuilder
    var currencyPicker: some View {
        Button {
            store.send(.view(.currencyPickerTapped))
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("來源幣別")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)

                Spacer()

                Text(
                    CurrencyDisplayName.text(
                        code: store.fromCurrency.rawValue,
                        language: AppLanguage(locale: locale)
                    )
                )
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, BLSpacing.small)
            .padding(.horizontal, BLSpacing.medium)
            .background(palette.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Fx.currencyPickerButton)
    }

    /// 幣別選擇 sheet 內容
    var currencyPickerSheet: some View {
        let locale = locale
        let language = AppLanguage(locale: locale)

        return OptionPickerSheet(
            title: "選擇來源幣別",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "尚無幣別",
            emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
            options: store.availableCurrencies.map(\.rawValue),
            selected: store.fromCurrency.rawValue,
            displayName: { code in
                CurrencyDisplayName.text(code: code, language: language)
            },
            searchKeywords: { code in
                CurrencyDisplayName.searchKeywords(code: code, locale: locale)
            },
            onSelect: { code in
                store.send(.view(.currencySelected(code)))
            }
        )
    }

    /// 金額輸入欄
    @ViewBuilder
    var amountField: some View {
        TextField(
            "輸入金額",
            value: $store.amount,
            format: .number.precision(.fractionLength(0...2)).grouping(.never)
        )
        .padding(.vertical, BLSpacing.medium)
        .padding(.horizontal, BLSpacing.medium)
        .font(.system(size: heroAmountSize, weight: .bold))
        .monospacedDigit()
        .background(palette.fillQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
        .keyboardType(.decimalPad)
        .focused($isAmountFieldFocused)
        .accessibilityIdentifier(BLAccessibilityID.Fx.amountField)
    }

    /// 換算結果區塊
    @ViewBuilder
    var conversionResult: some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("= 新台幣")
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .foregroundStyle(palette.accent)

            Text(BLFormatters.twd(store.convertedTWD, locale: locale))
                .font(.system(size: heroAmountSize, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(palette.accent)

            Text(
                "1 \(store.fromCurrency.rawValue) = \(FxFormatters.rate(store.rate, locale: locale)) TWD"
            )
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(palette.accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityValue(BLFormatters.twd(store.convertedTWD, locale: locale))
        .accessibilityIdentifier(BLAccessibilityID.Fx.convertedValue)
    }

    /// 快速金額按鈕列
    @ViewBuilder
    var quickAmountRow: some View {
        HStack(spacing: BLSpacing.small) {
            ForEach(presetAmounts, id: \.self) { value in
                Button {
                    store.send(.view(.quickAmountTapped(value)))
                } label: {
                    Text(FxFormatters.presetAmount(value, locale: locale))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BLSpacing.small)
                        .font(BLTypographyStyle.footnote.font.weight(.semibold))
                        .background(
                            store.amount == value
                                ? palette.accent.opacity(0.18)
                                : palette.fillTertiary
                        )
                        .foregroundStyle(store.amount == value ? palette.accent : palette.label)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: BLRadius.small,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 數字鍵盤的完成按鈕
    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()

            Button {
                store.isAmountFieldFocused = false
            } label: {
                Image(systemName: "checkmark")
            }
            .accessibilityLabel(Text("完成"))
            .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
        }
    }
}

// MARK: - Private Method

private extension FxView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 預設金額按鈕使用的金額
    var presetAmounts: [Decimal] {
        [10_000, 50_000, 100_000, 500_000]
    }
}

// MARK: - Preview

#Preview("匯率工具初始") {
    NavigationStack {
        FxView(store: Store(initialState: FxFeature.State()) { FxFeature() })
    }
}

#Preview("匯率工具載入中") {
    NavigationStack {
        FxView(
            store: Store(initialState: FxFeature.State(isLoading: true)) {
                FxFeature()
            }
        )
    }
}

#Preview("匯率工具錯誤") {
    NavigationStack {
        FxView(
            store: Store(
            initialState: FxFeature.State(
                errorMessage: "匯率載入失敗，請稍後再試。"
            )
            ) {
                FxFeature()
            }
        )
    }
}

#Preview("匯率工具已連線") {
    NavigationStack {
        FxView(
            store: Store(initialState: FxFeature.State(snapshot: FxRateSnapshot.fallback)) {
                FxFeature()
            }
        )
    }
}
