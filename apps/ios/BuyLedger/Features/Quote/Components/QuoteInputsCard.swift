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

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 來源幣別 ISO 代碼
    let currencyCode: String

    /// 來源幣別下的商品本金
    @Binding var itemPrice: Decimal

    /// 來源幣別下的當地運費
    @Binding var domesticShipping: Decimal

    /// 國際運費 (TWD)
    @Binding var internationalShippingTWD: Decimal

    /// 刷卡手續費 %
    @Binding var cardFeePercent: Decimal

    /// 金流手續費 %
    @Binding var paymentFeePercent: Decimal

    /// 平台手續費 %
    @Binding var platformFeePercent: Decimal

    /// 目標毛利 %
    @Binding var targetMarginPercent: Decimal

    /// 數值欄位的鍵盤焦點，由宿主畫面持有
    var focus: FocusState<Bool>.Binding

    /// 使用者點擊來源幣別列時呼叫
    let onCurrencyPickerTapped: () -> Void

    // MARK: - Body

    /// 輸入卡內容
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("商品資訊")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                currencyPicker

                numberField(
                    "商品定價",
                    $itemPrice,
                    currencyCode,
                    allowsDecimalEntry: true,
                    identifier: BLAccessibilityID.Quote.principalField
                )
                numberField("當地運費", $domesticShipping, currencyCode, allowsDecimalEntry: true)
                numberField("國際運費", $internationalShippingTWD, "TWD/件")
                numberField("刷卡手續費", $cardFeePercent, "%", fractionDigits: 1)
                numberField("金流手續費", $paymentFeePercent, "%", fractionDigits: 1)
                numberField("平台手續費", $platformFeePercent, "%", fractionDigits: 1)
                numberField("目標毛利", $targetMarginPercent, "%")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension QuoteInputsCard {

    /// 來源幣別選擇按鈕
    var currencyPicker: some View {
        Button(action: onCurrencyPickerTapped) {
            HStack(spacing: BLSpacing.small) {
                Text("來源幣別")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)

                Spacer()

                Text(
                    CurrencyDisplayName.text(
                        code: currencyCode,
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
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Quote.currencyPickerButton)
        .accessibilityValue(currencyCode)
    }

    /// 數值輸入列，支援直接輸入精確數值
    ///
    /// - Parameters:
    ///   - label: 欄位名稱
    ///   - value: 雙向繫結的值；寫入時自動 clamp 成非負數
    ///   - unit: 顯示在輸入框右側的單位字串
    ///   - fractionDigits: 顯示的小數位數
    ///   - allowsDecimalEntry: 是否允許輸入小數
    ///   - identifier: UI 測試定位用的識別碼
    /// - Returns: 數值輸入列 view
    func numberField(
        _ label: String,
        _ value: Binding<Decimal>,
        _ unit: String,
        fractionDigits: Int = 0,
        allowsDecimalEntry: Bool = false,
        identifier: String? = nil
    ) -> some View {
        HStack(spacing: BLSpacing.small) {
            Text(LocalizedStringKey(label))
                .blTextStyle(.subhead)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(palette.secondaryLabel)

            TextField(
                "0",
                value: value,
                format: .number.precision(
                    allowsDecimalEntry ? .fractionLength(0...2) : .fractionLength(fractionDigits)
                )
                .grouping(.never)
            )
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: 120)
            .keyboardType(allowsDecimalEntry || fractionDigits > 0 ? .decimalPad : .numberPad)
            .focused(focus)
            .accessibilityIdentifier(identifier ?? "")

            Text(LocalizedStringKey(unit))
                .blTextStyle(.footnote)
                .lineLimit(1)
                .frame(minWidth: 60, alignment: .leading)
                .foregroundStyle(palette.secondaryLabel)
        }
    }
}

// MARK: - Private Method

private extension QuoteInputsCard {

    /// 畫面色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("輸入卡") {
    @Previewable @FocusState var isFocused: Bool

    QuoteInputsCard(
        currencyCode: "KRW",
        itemPrice: .constant(100_000),
        domesticShipping: .constant(5_000),
        internationalShippingTWD: .constant(180),
        cardFeePercent: .constant(2.5),
        paymentFeePercent: .constant(1),
        platformFeePercent: .constant(1),
        targetMarginPercent: .constant(25),
        focus: $isFocused,
        onCurrencyPickerTapped: {}
    )
    .padding()
}
