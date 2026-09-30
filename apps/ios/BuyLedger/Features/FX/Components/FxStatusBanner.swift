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

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 是否正在載入匯率
    let isLoading: Bool

    /// 匯率載入失敗訊息
    let errorMessage: LocalizedStringResource?

    /// 最新匯率快照時間
    let snapshotDate: Date?

    /// 使用者點擊重試時執行的動作
    let onRetry: () -> Void

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
        let palette = BLPalette()

        return HStack(spacing: BLSpacing.small) {
            ProgressView()
                .controlSize(.small)

            Text("正在更新匯率…")
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
        let palette = BLPalette()

        return HStack(alignment: .top, spacing: BLSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(palette.orange)

            Text(message)
                .blTextStyle(.footnote)
                .foregroundStyle(palette.label)

            Spacer()

            Button("重試", action: onRetry)
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(palette.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 已連線的狀態內容
    var connectedContent: some View {
        let palette = BLPalette()

        return HStack(spacing: BLSpacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(palette.green)

            Text(
                "已連線到 ExchangeRate-API · \(FxFormatters.snapshotTimestamp(snapshotDate, locale: locale))"
            )
                .blTextStyle(.footnote)
                .foregroundStyle(palette.secondaryLabel)

            Spacer()
        }
        .padding(.horizontal, BLSpacing.medium)
        .padding(.vertical, BLSpacing.small)
        .background(palette.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }
}

// MARK: - Preview

#Preview("載入中") {
    FxStatusBanner(
        isLoading: true,
        errorMessage: nil,
        snapshotDate: nil,
        onRetry: {}
    )
    .padding()
}

#Preview("已連線") {
    FxStatusBanner(
        isLoading: false,
        errorMessage: nil,
        snapshotDate: Date(timeIntervalSince1970: 1_777_000_000),
        onRetry: {}
    )
    .padding()
}

#Preview("載入失敗") {
    FxStatusBanner(
        isLoading: false,
        errorMessage: "匯率暫時無法取得，請稍後再試。",
        snapshotDate: nil,
        onRetry: {}
    )
    .padding()
}
