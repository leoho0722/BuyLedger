//
//  QuoteStatusBanner.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 報價試算的載入與提示狀態橫幅
struct QuoteStatusBanner: View {

    // MARK: - Properties

    /// 是否正在載入匯率
    let isLoading: Bool

    /// 目標毛利是否低於 100%
    let isTargetMarginBelowOneHundredPercent: Bool

    /// 使用者點擊重試時執行的動作
    let onRetry: () -> Void

    /// 匯率不可用時顯示的原因
    let rateUnavailableReason: LocalizedStringResource?

    // MARK: - Body

    /// 狀態橫幅內容
    @ViewBuilder
    var body: some View {
        if isLoading {
            loadingContent
        } else if let rateUnavailableReason {
            failureContent(message: rateUnavailableReason)
        } else if !isTargetMarginBelowOneHundredPercent {
            marginWarningContent
        }
    }
}

// MARK: - Private Views

private extension QuoteStatusBanner {

    /// 載入中的狀態內容
    var loadingContent: some View {
        HStack(spacing: BLSpacing.small) {
            ProgressView()
                .controlSize(.small)

            Text("quote.calculator.label.loadingExchangeRates")
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(.blFillTertiary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 組出載入失敗的狀態內容
    ///
    /// - Parameter message: 要顯示的失敗訊息
    /// - Returns: 失敗狀態內容
    func failureContent(message: LocalizedStringResource) -> some View {
        HStack(alignment: .top, spacing: BLSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.blOrange)

            Text(message)
                .blTextStyle(.footnote)
                .foregroundStyle(.blLabel)

            Spacer()

            Button {
                onRetry()
            } label: {
                Text("common.action.button.retry")
                    .frame(minHeight: BLHitTarget.minimum)
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .contentShape(.rect)
            }
            .accessibilityIdentifier(BLAccessibilityID.Quote.retryButton)
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(.blOrange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 目標毛利過高的提示內容
    var marginWarningContent: some View {
        HStack(spacing: BLSpacing.small) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blSecondaryLabel)

            Text("quote.calculator.message.targetMarginMust")
                .blTextStyle(.footnote)
                .foregroundStyle(.blSecondaryLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(.blFillQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }
}

// MARK: - Preview

#Preview("common.action.label.loading") {
    QuoteStatusBanner(
        isLoading: true,
        isTargetMarginBelowOneHundredPercent: true,
        onRetry: {
        },
        rateUnavailableReason: nil
    )
    .padding()
}

#Preview("匯率不可用") {
    QuoteStatusBanner(
        isLoading: false,
        isTargetMarginBelowOneHundredPercent: true,
        onRetry: {
        },
        rateUnavailableReason: "quote.calculator.message.exchangeRateAvailable"
    )
    .padding()
}

#Preview("目標毛利達 100%") {
    QuoteStatusBanner(
        isLoading: false,
        isTargetMarginBelowOneHundredPercent: false,
        onRetry: {
        },
        rateUnavailableReason: nil
    )
    .padding()
}
