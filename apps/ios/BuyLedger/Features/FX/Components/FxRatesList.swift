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

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 要顯示的來源幣別清單
    let currencies: [CurrencyCode]

    /// 最新匯率快照時間；無快照時為 `nil`
    let snapshotDate: Date?

    /// 依幣別取得一單位對應 TWD 匯率的 closure
    let rate: (CurrencyCode) -> Decimal?

    // MARK: - Body

    /// 即時匯率列表內容
    var body: some View {
        BLCard(padding: 0) {
            LazyVStack(spacing: 0) {
                HStack {
                    Text("即時匯率 (對 TWD)")
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(palette.label)

                    Spacer()
                }
                .padding(.horizontal, BLSpacing.large)
                .padding(.top, BLSpacing.large)
                .padding(.bottom, BLSpacing.small)

                ForEach(Array(currencies.enumerated()), id: \.element) { index, currency in
                    rateRow(currency: currency)

                    if index < currencies.count - 1 {
                        Divider()
                            .padding(.leading, BLSpacing.large)
                    }
                }
            }
        }
    }
}

// MARK: - Private Views

private extension FxRatesList {

    /// 顯示單一幣別的匯率列
    ///
    /// - Parameter currency: 要顯示的幣別
    /// - Returns: 匯率列 view
    @ViewBuilder
    func rateRow(currency: CurrencyCode) -> some View {
        HStack(spacing: BLSpacing.medium) {
            VStack(alignment: .leading) {
                Text("1 \(currency.rawValue)")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)

                Text(LocalizedStringKey(rateSourceSubtitle))
                    .blTextStyle(.caption)
                    .foregroundStyle(palette.secondaryLabel)
            }

            Spacer()

            Text(FxFormatters.rate(rate(currency), locale: locale))
                .blTextStyle(.title3)
                .monospacedDigit()
                .foregroundStyle(palette.label)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
    }
}

// MARK: - Private Method

private extension FxRatesList {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 匯率列副標：顯示來源與時間；無 snapshot 時顯示「尚未連線」
    var rateSourceSubtitle: String {
        guard snapshotDate != nil else {
            return "尚未連線"
        }
        return "ExchangeRate-API · \(FxFormatters.snapshotTimestamp(snapshotDate, locale: locale))"
    }
}

// MARK: - Preview

#Preview("有匯率資料") {
    FxRatesList(
        currencies: [.usd, .jpy, .krw],
        snapshotDate: Date(timeIntervalSince1970: 1_777_000_000),
        rate: { currency in
            switch currency {
            case .usd:
                32.5

            case .jpy:
                0.21

            default:
                0.024
            }
        }
    )
    .padding()
}

#Preview("尚無匯率資料") {
    FxRatesList(
        currencies: [.usd, .jpy],
        snapshotDate: nil,
        rate: { _ in nil }
    )
    .padding()
}
