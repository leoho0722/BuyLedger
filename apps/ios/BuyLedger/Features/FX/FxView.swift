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

    /// Dynamic Type 尺寸，無障礙字級時解除幣別名稱的單行限制
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 金額輸入欄與換算結果的字級，隨 Dynamic Type 縮放 (以 `.title` 為基準)
    @ScaledMetric(relativeTo: .title) private var heroAmountSize: CGFloat = 32

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<FxFeature>

    /// 金額欄位的鍵盤焦點
    ///
    /// - Note: 實際狀態由 ``FxFeature/State/isAmountFieldFocused`` 持有
    @FocusState private var isAmountFieldFocused: Bool

    // MARK: - Body

    /// FX 畫面內容
    var body: some View {
        ScrollView {
            content
                .padding(BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.blBackground)
        .accessibilityIdentifier(BLAccessibilityID.Fx.root)
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isAmountFieldFocused, to: $isAmountFieldFocused)
        .task {
            await store.send(.view(.task)).finish()
        }
        .navigationTitle(Text("settings.more.label.exchangeRates"))
        .toolbar {
            keyboardToolbar
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
                errorMessage: store.errorMessage,
                isLoading: store.isLoading,
                onRetry: {
                    store.send(.view(.retryTapped))
                },
                snapshotDate: store.snapshot?.date
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Fx.statusBanner)

            converterCard

            quickAmountRow

            FxRatesList(
                currencies: store.ratesListCurrencies,
                rate: {
                    store.state.displayRate(for: $0)
                },
                snapshotDate: store.snapshot?.date
            )
        }
    }

    /// 換算卡片：幣別選擇、金額輸入與 TWD 結果
    @ViewBuilder
    var converterCard: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("orders.list.label.from")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)
                    .textCase(.uppercase)

                currencyPicker

                Text("orders.detail.label.amount")
                    .padding(.top, BLSpacing.small)
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)
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
                Text("fx.rates.label.sourceCurrency")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)

                Spacer()

                Text(
                    CurrencyDisplayName.text(
                        code: store.fromCurrency.rawValue,
                        language: AppLanguage(locale: locale)
                    )
                )
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(.blLabel)

                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.blTertiaryLabel)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, BLSpacing.small)
            .padding(.horizontal, BLSpacing.medium)
            .background(.blFillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Fx.currencyPickerButton)
    }

    /// 幣別選擇 sheet 內容
    var currencyPickerSheet: some View {
        OptionPickerSheet(
            title: "fx.rates.label.selectSourceCurrency",
            options: store.availableCurrencyCodes,
            selection: .single(
                selected: store.fromCurrency.rawValue,
                onSelect: {
                    store.send(.view(.currencySelected($0)))
                }
            ),
            emptyState: .init(
                title: "orders.edit.label.currenciesAvailable",
                description: "orders.edit.message.internetConnectionRequired"
            ),
            labeling: CurrencyDisplayName.optionLabeling(locale: locale),
            isSearchEnabled: true
        )
    }

    /// 金額輸入欄
    @ViewBuilder
    var amountField: some View {
        TextField(
            "fx.rates.action.enterAmount",
            value: $store.amount,
            format: .number.precision(.fractionLength(0...2)).grouping(.never)
        )
        .padding(.vertical, BLSpacing.medium)
        .padding(.horizontal, BLSpacing.medium)
        .font(.system(size: heroAmountSize, weight: .bold))
        .monospacedDigit()
        .background(.blFillQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
        .keyboardType(.decimalPad)
        .focused($isAmountFieldFocused)
        .accessibilityIdentifier(BLAccessibilityID.Fx.amountField)
    }

    /// 換算結果區塊
    @ViewBuilder
    var conversionResult: some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("fx.rates.label.twd")
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .foregroundStyle(.blAccent)

            Text(BLFormatters.twd(store.convertedTWD, locale: locale))
                .font(.system(size: heroAmountSize, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.blAccent)

            Text(
                FxFormatters.conversionLabel(
                    from: store.fromCurrency,
                    rate: store.rate,
                    locale: locale
                )
            )
            .blTextStyle(.caption)
            .foregroundStyle(.blSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(.blAccent.opacity(0.12))
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
                                ? .blAccent.opacity(0.18)
                                : .blFillTertiary
                        )
                        .foregroundStyle(store.amount == value ? .blAccent : .blLabel)
                        .clipShape(
                            RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
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
            .accessibilityLabel(Text("common.action.button.done"))
            .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
        }
    }
}

// MARK: - Private Method

private extension FxView {

    /// 預設金額按鈕使用的金額
    var presetAmounts: [Decimal] {
        [10_000, 50_000, 100_000, 500_000]
    }
}

// MARK: - Preview

#Preview("匯率工具初始") {
    NavigationStack {
        FxView(
            store: Store(initialState: FxFeature.State()) {
                FxFeature()
            }
        )
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
                initialState: FxFeature.State(errorMessage: "fx.rates.message.exchangeRatesLoaded")
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
