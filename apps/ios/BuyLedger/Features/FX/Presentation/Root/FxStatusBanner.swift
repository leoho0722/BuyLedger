//
//  FxStatusBanner.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 匯率工具的載入、錯誤與連線狀態橫幅
struct FxStatusBanner: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 匯率載入失敗訊息
    let errorMessage: LocalizedStringResource?

    /// 是否正在載入匯率
    let isLoading: Bool

    /// 使用者點擊重試時執行的動作
    let onRetry: () -> Void

    /// 最新匯率快照時間
    let snapshotDate: Date?

    // MARK: - Body

    /// 狀態橫幅內容
    @ViewBuilder
    var body: some View {
        if isLoading {
            loadingContent
        } else if let errorMessage {
            failureContent(message: errorMessage)
        } else if snapshotDate != nil {
            connectedContent
        }
    }
}

// MARK: - Private Views

private extension FxStatusBanner {

    /// 載入中的狀態內容
    var loadingContent: some View {
        HStack(spacing: BLSpacing.small) {
            ProgressView()
                .controlSize(.small)

            Text("fx.rates.label.updatingExchangeRates")
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

            Button("common.action.button.retry", action: onRetry)
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(.blOrange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 已連線的狀態內容
    var connectedContent: some View {
        HStack(spacing: BLSpacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.blGreen)

            Text(
                AppLanguage.format(
                    "fx.rates.message.connectedTimestamp",
                    FxFormatters.snapshotTimestamp(snapshotDate, locale: locale),
                    locale: locale
                )
            )
            .blTextStyle(.footnote)
            .foregroundStyle(.blSecondaryLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(.blGreen.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }
}

// MARK: - Preview

#Preview("common.action.label.loading") {
    FxStatusBanner(
        errorMessage: nil,
        isLoading: true,
        onRetry: {
        },
        snapshotDate: nil
    )
    .padding()
}

#Preview("已連線") {
    FxStatusBanner(
        errorMessage: nil,
        isLoading: false,
        onRetry: {
        },
        snapshotDate: Date(timeIntervalSince1970: 1_777_000_000)
    )
    .padding()
}

#Preview("載入失敗") {
    FxStatusBanner(
        errorMessage: "匯率暫時無法取得，請稍後再試。",
        isLoading: false,
        onRetry: {
        },
        snapshotDate: nil
    )
    .padding()
}
