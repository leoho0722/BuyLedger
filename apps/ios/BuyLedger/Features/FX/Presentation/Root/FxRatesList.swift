//
//  FxRatesList.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 匯率工具的即時匯率列表
struct FxRatesList: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 要顯示的來源幣別清單
    let currencies: [CurrencyCode]

    /// 依幣別取得一單位對應 TWD 匯率的 closure
    let rate: (CurrencyCode) -> Decimal?

    /// 最新匯率快照時間；無快照時為 `nil`
    let snapshotDate: Date?

    // MARK: - Body

    /// 即時匯率列表內容
    var body: some View {
        BLCard(padding: 0) {
            LazyVStack(spacing: 0) {
                header

                rows
            }
        }
    }
}

// MARK: - Private Views

private extension FxRatesList {

    /// 列表標題列，標示下方匯率皆以新台幣為基準
    var header: some View {
        HStack {
            Text("fx.rates.label.liveRatesTo")
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(.blLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.top, BLSpacing.large)
        .padding(.bottom, BLSpacing.small)
    }

    /// 依幣別逐列顯示匯率，列與列之間以分隔線隔開
    var rows: some View {
        ForEach(Array(currencies.enumerated()), id: \.element) { index, currency in
            rateRow(currency: currency)

            if index < currencies.count - 1 {
                Divider()
                    .padding(.leading, BLSpacing.large)
            }
        }
    }

    /// 顯示單一幣別的匯率列
    ///
    /// - Parameter currency: 要顯示的幣別
    /// - Returns: 匯率列 view
    @ViewBuilder
    func rateRow(currency: CurrencyCode) -> some View {
        HStack(spacing: BLSpacing.medium) {
            VStack(alignment: .leading) {
                Text(verbatim: FxFormatters.unitRateLabel(currency))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(.blLabel)

                Text(FxFormatters.rateSourceSubtitle(snapshotDate: snapshotDate, locale: locale))
                    .blTextStyle(.caption)
                    .foregroundStyle(.blSecondaryLabel)
            }

            Spacer()

            Text(FxFormatters.rate(rate(currency), locale: locale))
                .blTextStyle(.title3)
                .monospacedDigit()
                .foregroundStyle(.blLabel)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
        .accessibilityElement(children: .combine)
        .accessibilityValue(FxFormatters.rate(rate(currency), locale: locale))
    }
}

// MARK: - Preview

#Preview("有匯率資料") {
    FxRatesList(
        currencies: [.usd, .jpy, .krw],
        rate: { currency in
            switch currency {
            case .usd:
                32.5

            case .jpy:
                0.21

            default:
                0.024
            }
        },
        snapshotDate: Date(timeIntervalSince1970: 1_777_000_000)
    )
    .padding()
}

#Preview("尚無匯率資料") {
    FxRatesList(
        currencies: [.usd, .jpy],
        rate: { _ in
            nil
        },
        snapshotDate: nil
    )
    .padding()
}
