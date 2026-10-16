//
//  QuoteView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 報價試算工具畫面
struct QuoteView: View {

    // MARK: - Properties

    /// Dynamic Type 尺寸，無障礙字級時解除 hero 數字的單行限制
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// hero 建議售價字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroPriceSize: CGFloat = 40

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<QuoteFeature>

    /// 數值欄位的鍵盤焦點
    ///
    /// - Note: 實際狀態由 ``QuoteFeature/State/isAmountFieldFocused`` 持有
    @FocusState private var isAmountFieldFocused: Bool

    // MARK: - Body

    /// 報價試算畫面內容
    var body: some View {
        ScrollView {
            content
                .padding(BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.blBackground)
        .accessibilityIdentifier(BLAccessibilityID.Quote.root)
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isAmountFieldFocused, to: $isAmountFieldFocused)
        .task {
            await store.send(.view(.task)).finish()
        }
        .navigationTitle(Text("settings.more.label.quoteCalculator"))
        .toolbar {
            keyboardToolbar
        }
        .sheet(
            isPresented: Binding(
                $store.scope(state: \.rateSource.$destination, action: \.rateSource.destination)
                    .currencyPicker
            )
        ) {
            currencyPickerSheet
        }
    }
}

// MARK: - Private Views

private extension QuoteView {

    /// 報價試算畫面主要內容
    var content: some View {
        VStack(alignment: .leading, spacing: BLSpacing.large) {
            QuoteStatusBanner(
                isLoading: store.rateSource.isLoading,
                isTargetMarginBelowOneHundredPercent: store.isTargetMarginBelowOneHundredPercent,
                onRetry: {
                    store.send(.view(.retryTapped))
                },
                rateUnavailableReason: store.rateSource.rateUnavailableReason
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Quote.statusBanner)

            QuoteInputsCard(
                cardFeePercent: $store.cardFeePercent,
                domesticShipping: $store.domesticShipping,
                internationalShippingTWD: $store.internationalShippingTWD,
                itemPrice: $store.itemPrice,
                paymentFeePercent: $store.paymentFeePercent,
                platformFeePercent: $store.platformFeePercent,
                targetMarginPercent: $store.targetMarginPercent,
                currencyCode: store.rateSource.fromCurrency.rawValue,
                focus: $isAmountFieldFocused,
                onCurrencyPickerTapped: {
                    store.send(.view(.currencyPickerTapped))
                }
            )

            suggestedHero

            QuoteBreakdownCard(
                cardFeeTWD: store.cardFeeTWD,
                costTWD: store.costTWD,
                domesticTWD: store.domesticTWD,
                hasUsableRate: store.rateSource.hasUsableRate,
                internationalShippingTWD: store.internationalShippingTWD,
                itemTWD: store.itemTWD,
                paymentFeeTWD: store.paymentFeeTWD,
                platformFeeTWD: store.platformFeeTWD
            )
        }
    }

    /// 幣別選擇 sheet 內容
    var currencyPickerSheet: some View {
        let locale = locale
        let language = AppLanguage(locale: locale)

        return OptionPickerSheet(
            title: "fx.rates.label.selectSourceCurrency",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "orders.edit.label.currenciesAvailable",
            emptyDescription: "orders.edit.message.internetConnectionRequired",
            options: store.rateSource.availableCurrencyCodes,
            selected: store.rateSource.fromCurrency.rawValue,
            displayName: {
                CurrencyDisplayName.text(code: $0, language: language)
            },
            searchKeywords: {
                CurrencyDisplayName.searchKeywords(code: $0, locale: locale)
            },
            onSelect: {
                store.send(.view(.currencySelected($0)))
            }
        )
    }

    /// 建議售價 hero 卡
    @ViewBuilder
    var suggestedHero: some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("quote.calculator.label.suggestedPrice")
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .textCase(.uppercase)

            Text(BLFormatters.twd(store.displayedSuggestedTWD, locale: locale))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.7)
                .font(.system(size: heroPriceSize, weight: .bold))
                .monospacedDigit()

            switch store.heroMessage {
            case .rateUnavailable:
                Text("quote.calculator.message.exchangeRateAvailable")
                    .blTextStyle(.footnote)

            case .estimate(let profitTWD, let marginPercent):
                Text(
                    AppLanguage.format(
                        "quote.calculator.label.estimatedProfit",
                        BLFormatters.twd(profitTWD, locale: locale),
                        BLFormatters.percent(scaled: marginPercent, locale: locale),
                        locale: locale
                    )
                )
                .blTextStyle(.footnote)

            case .marginTooHigh:
                Text("quote.calculator.message.targetMarginMust")
                    .blTextStyle(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.large)
        .foregroundStyle(.white)
        .blHeroCardBackground()
        .blCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityValue(BLFormatters.twd(store.displayedSuggestedTWD, locale: locale))
        .accessibilityIdentifier(BLAccessibilityID.Quote.suggestedPriceValue)
    }

    /// 數字鍵盤的完成按鈕
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

// MARK: - Preview

/// 組出預覽用的報價試算畫面容器
///
/// - Parameter state: 預覽使用的報價試算狀態
/// - Returns: 包在導覽堆疊內的報價試算畫面
@MainActor private func quotePreview(state: QuoteFeature.State) -> some View {
    NavigationStack {
        QuoteView(
            store: Store(initialState: state) {
                QuoteFeature()
            }
        )
    }
}

#Preview("報價試算可試算") {
    quotePreview(
        state: QuoteFeature.State(
            rateSource: QuoteRateFeature.State(
                fromCurrency: .krw,
                snapshot: FxRateSnapshot.fallback
            ),
            itemPrice: 1_000,
            targetMarginPercent: 25
        )
    )
}

#Preview("報價試算匯率不可用") {
    let unavailableSnapshot = FxRateSnapshot(
        date: Date(timeIntervalSince1970: 0),
        base: .twd,
        rates: [.twd: 1]
    )

    return quotePreview(
        state: QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw, snapshot: unavailableSnapshot)
        )
    )
}

#Preview("報價試算毛利 100%") {
    quotePreview(
        state: QuoteFeature.State(
            rateSource: QuoteRateFeature.State(
                fromCurrency: .krw,
                snapshot: FxRateSnapshot.fallback
            ),
            itemPrice: 1_000,
            targetMarginPercent: 100
        )
    )
}
