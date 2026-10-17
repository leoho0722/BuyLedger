//
//  QuoteInputsCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 報價試算的輸入卡：來源幣別選擇與各項數值輸入欄
struct QuoteInputsCard: View {

    // MARK: - Properties

    /// Dynamic Type 尺寸，無障礙字級時解除幣別名稱與單位的單行限制
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 數值輸入框的寬度，隨 Dynamic Type 縮放
    @ScaledMetric private var inputFieldWidth: CGFloat = 120

    /// 單位欄位的最小寬度，隨 Dynamic Type 縮放
    @ScaledMetric private var unitMinWidth: CGFloat = 60

    /// 刷卡手續費 %
    @Binding var cardFeePercent: Decimal

    /// 來源幣別下的當地運費
    @Binding var domesticShipping: Decimal

    /// 國際運費 (TWD)
    @Binding var internationalShippingTWD: Decimal

    /// 來源幣別下的商品本金
    @Binding var itemPrice: Decimal

    /// 金流手續費 %
    @Binding var paymentFeePercent: Decimal

    /// 平台手續費 %
    @Binding var platformFeePercent: Decimal

    /// 目標毛利 %
    @Binding var targetMarginPercent: Decimal

    /// 來源幣別 ISO 代碼
    let currencyCode: String

    /// 數值欄位的鍵盤焦點，由宿主畫面持有
    var focus: FocusState<Bool>.Binding

    /// 使用者點擊來源幣別列時呼叫
    let onCurrencyPickerTapped: () -> Void

    // MARK: - Body

    /// 輸入卡內容
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                sectionTitle

                currencyPicker

                numberField(
                    "quote.calculator.label.itemPrice",
                    $itemPrice,
                    currencyCode,
                    isDecimalEntryAllowed: true,
                    identifier: BLAccessibilityID.Quote.principalField
                )

                numberField(
                    "quote.calculator.label.localShipping",
                    $domesticShipping,
                    currencyCode,
                    isDecimalEntryAllowed: true
                )

                numberField(
                    "orders.detail.label.internationalShipping",
                    $internationalShippingTWD,
                    "quote.calculator.label.twdItem"
                )

                numberField(
                    "orders.detail.label.cardFee",
                    $cardFeePercent,
                    "%",
                    fractionDigits: 1
                )

                numberField(
                    "orders.detail.label.paymentProcessingFee",
                    $paymentFeePercent,
                    "%",
                    fractionDigits: 1
                )

                numberField(
                    "orders.detail.label.platformFee",
                    $platformFeePercent,
                    "%",
                    fractionDigits: 1
                )

                numberField("quote.calculator.label.targetMargin", $targetMarginPercent, "%")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension QuoteInputsCard {

    /// 輸入卡頂端的區塊標題
    var sectionTitle: some View {
        Text("quote.calculator.label.itemInformation")
            .font(BLTypographyStyle.caption.font.weight(.semibold))
            .foregroundStyle(.blSecondaryLabel)
            .textCase(.uppercase)
    }

    /// 來源幣別選擇按鈕
    var currencyPicker: some View {
        Button(action: onCurrencyPickerTapped) {
            HStack(spacing: BLSpacing.small) {
                Text("fx.rates.label.sourceCurrency")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)

                Spacer()

                Text(
                    CurrencyDisplayName.text(
                        code: currencyCode,
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
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Quote.currencyPickerButton)
        .accessibilityValue(currencyCode)
    }

    /// 組出數值輸入列，支援直接輸入精確數值
    ///
    /// - Parameters:
    ///   - label: 欄位名稱
    ///   - value: 雙向繫結的值；寫入時自動 clamp 成非負數
    ///   - unit: 顯示在輸入框右側的單位字串
    ///   - fractionDigits: 顯示的小數位數
    ///   - isDecimalEntryAllowed: 是否允許輸入小數
    ///   - identifier: UI 測試定位用的識別碼
    /// - Returns: 數值輸入列 view
    func numberField(
        _ label: String,
        _ value: Binding<Decimal>,
        _ unit: String,
        fractionDigits: Int = 0,
        isDecimalEntryAllowed: Bool = false,
        identifier: String? = nil
    ) -> some View {
        HStack(spacing: BLSpacing.small) {
            Text(LocalizedStringKey(label))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blTextStyle(.subhead)
                .foregroundStyle(.blSecondaryLabel)

            TextField(
                LocalizedStringKey(label),
                value: value,
                format: .number.precision(
                    isDecimalEntryAllowed ? .fractionLength(0...2) : .fractionLength(fractionDigits)
                )
                    .grouping(.never),
                prompt: Text(verbatim: "0")
            )
            .frame(width: inputFieldWidth)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .keyboardType(isDecimalEntryAllowed || fractionDigits > 0 ? .decimalPad : .numberPad)
            .focused(focus)
            .accessibilityIdentifier(identifier ?? "")

            Text(LocalizedStringKey(unit))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .frame(minWidth: unitMinWidth, alignment: .leading)
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)
        }
    }
}

// MARK: - Preview

#Preview("輸入卡") {
    @Previewable @FocusState var isFocused: Bool

    QuoteInputsCard(
        cardFeePercent: .constant(2.5),
        domesticShipping: .constant(5_000),
        internationalShippingTWD: .constant(180),
        itemPrice: .constant(100_000),
        paymentFeePercent: .constant(1),
        platformFeePercent: .constant(1),
        targetMarginPercent: .constant(25),
        currencyCode: "KRW",
        focus: $isFocused,
        onCurrencyPickerTapped: {
        }
    )
    .padding()
}
