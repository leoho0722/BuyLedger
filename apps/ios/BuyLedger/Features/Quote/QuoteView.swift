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

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 數值欄位的鍵盤焦點
    /// 實際狀態由 ``QuoteFeature/State/isAmountFieldFocused`` 持有
    @FocusState private var isAmountFieldFocused: Bool

    /// hero 建議售價字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroPriceSize: CGFloat = 40

    /// 報價試算 store
    @Bindable var store: StoreOf<QuoteFeature>

    // MARK: - Body

    /// 報價試算畫面內容
    var body: some View {
        ScrollView {
            content
                .padding(BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(BLAccessibilityID.Quote.root)
        .background(palette.background)
        .navigationTitle(Text("報價試算"))
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
                rateUnavailableReason: store.rateSource.rateUnavailableReason,
                isTargetMarginBelowOneHundredPercent: store.isTargetMarginBelowOneHundredPercent,
                onRetry: { store.send(.view(.retryTapped)) }
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Quote.statusBanner)

            QuoteInputsCard(
                currencyCode: store.rateSource.fromCurrency.rawValue,
                itemPrice: $store.itemPrice,
                domesticShipping: $store.domesticShipping,
                internationalShippingTWD: $store.internationalShippingTWD,
                cardFeePercent: $store.cardFeePercent,
                paymentFeePercent: $store.paymentFeePercent,
                platformFeePercent: $store.platformFeePercent,
                targetMarginPercent: $store.targetMarginPercent,
                focus: $isAmountFieldFocused,
                onCurrencyPickerTapped: { store.send(.view(.currencyPickerTapped)) }
            )

            suggestedHero

            QuoteBreakdownCard(
                hasUsableRate: store.rateSource.hasUsableRate,
                itemTWD: store.itemTWD,
                domesticTWD: store.domesticTWD,
                internationalShippingTWD: store.internationalShippingTWD,
                cardFeeTWD: store.cardFeeTWD,
                paymentFeeTWD: store.paymentFeeTWD,
                platformFeeTWD: store.platformFeeTWD,
                costTWD: store.costTWD
            )
        }
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
            options: store.rateSource.availableCurrencies.map(\.rawValue),
            selected: store.rateSource.fromCurrency.rawValue,
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

    /// 建議售價 hero 卡
    @ViewBuilder
    var suggestedHero: some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("建議售價")
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .textCase(.uppercase)

            Text(heroPriceText)
                .font(.system(size: heroPriceSize, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            switch store.heroMessage {
            case .rateUnavailable:
                Text("尚無可用匯率資料，暫時無法試算。")
                    .blTextStyle(.footnote)
            case let .estimate(profitTWD, marginPercent):
                Text(
                    """
                    預估獲利 \(BLFormatters.twd(profitTWD, locale: locale)) · \
                    \(BLFormatters.percent(scaled: marginPercent, locale: locale))
                    """
                )
                    .blTextStyle(.footnote)
            case .marginTooHigh:
                Text("目標毛利需低於 100% 才能計算建議售價。")
                    .blTextStyle(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.large)
        .foregroundStyle(.white)
        .blHeroCardBackground()
        .blCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityValue(heroPriceText)
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
            .accessibilityLabel(Text("完成"))
            .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
        }
    }
}

// MARK: - Private Method

private extension QuoteView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// Hero 建議售價顯示文字；無法計算時顯示破折號
    var heroPriceText: String {
        guard let displayedSuggestedTWD = store.displayedSuggestedTWD else {
            return "—"
        }
        return BLFormatters.twd(displayedSuggestedTWD, locale: locale)
    }
}

// MARK: - Preview

/// 預覽用的報價試算畫面容器
@MainActor private func quotePreview(state: QuoteFeature.State) -> some View {
    NavigationStack {
        QuoteView(store: Store(initialState: state) { QuoteFeature() })
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
