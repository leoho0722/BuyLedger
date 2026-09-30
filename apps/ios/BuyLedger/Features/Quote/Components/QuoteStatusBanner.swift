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

    /// 匯率不可用時顯示的原因
    let rateUnavailableReason: LocalizedStringResource?

    /// 目標毛利是否低於 100%
    let isTargetMarginBelowOneHundredPercent: Bool

    /// 使用者點擊重試時執行的動作
    let onRetry: () -> Void

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

            Text("正在載入匯率…")
                .blTextStyle(.footnote)
                .foregroundStyle(palette.secondaryLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(palette.fillTertiary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 載入失敗的狀態內容
    ///
    /// - Parameter message: 要顯示的失敗訊息
    /// - Returns: 失敗狀態內容
    func failureContent(message: LocalizedStringResource) -> some View {
        HStack(alignment: .top, spacing: BLSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(palette.orange)

            Text(message)
                .blTextStyle(.footnote)
                .foregroundStyle(palette.label)

            Spacer()

            Button {
                onRetry()
            } label: {
                Text("重試")
                    .frame(minHeight: BLHitTarget.minimum)
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .contentShape(.rect)
            }
            .accessibilityIdentifier(BLAccessibilityID.Quote.retryButton)
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(palette.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 目標毛利過高的提示內容
    var marginWarningContent: some View {
        HStack(spacing: BLSpacing.small) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(palette.secondaryLabel)

            Text("目標毛利需低於 100% 才能計算建議售價。")
                .blTextStyle(.footnote)
                .foregroundStyle(palette.secondaryLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(palette.fillQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }
}

// MARK: - Private Method

private extension QuoteStatusBanner {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("載入中") {
    QuoteStatusBanner(
        isLoading: true,
        rateUnavailableReason: nil,
        isTargetMarginBelowOneHundredPercent: true,
        onRetry: {}
    )
    .padding()
}

#Preview("匯率不可用") {
    QuoteStatusBanner(
        isLoading: false,
        rateUnavailableReason: "尚無可用匯率資料，暫時無法試算。",
        isTargetMarginBelowOneHundredPercent: true,
        onRetry: {}
    )
    .padding()
}

#Preview("目標毛利達 100%") {
    QuoteStatusBanner(
        isLoading: false,
        rateUnavailableReason: nil,
        isTargetMarginBelowOneHundredPercent: false,
        onRetry: {}
    )
    .padding()
}
