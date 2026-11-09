//
//  OrdersListLoadFailureRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/9.
//

import SwiftUI

/// 訂單清單載入失敗時的清單列，顯示失敗訊息與重試鍵，供 compact 與 regular 版面共用
struct OrdersListLoadFailureRow: View {

    // MARK: - Properties

    /// 內容的水平內距，由呼叫端依所在欄位決定
    let horizontalInset: CGFloat

    /// 描述載入失敗原因的訊息
    let message: LocalizedStringResource

    /// 使用者點擊重試時執行的動作
    let onRetry: () -> Void

    // MARK: - Body

    /// 由上而下是失敗訊息與重試鍵
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            failureMessage

            retryButton
        }
        .padding(.top, BLSpacing.large)
        .padding(.horizontal, horizontalInset)
    }
}

// MARK: - Private Views

private extension OrdersListLoadFailureRow {

    /// 紅色的載入失敗訊息
    var failureMessage: some View {
        Text(message)
            .blTextStyle(.footnote)
            .foregroundStyle(.blRed)
            .accessibilityIdentifier(BLAccessibilityID.Orders.listLoadFailure)
    }

    /// 重試鍵，標籤的最小尺寸取 `BLHitTarget.minimum`，文字維持與失敗訊息左對齊
    var retryButton: some View {
        Button {
            onRetry()
        } label: {
            Text("common.action.button.retry")
                .frame(
                    minWidth: BLHitTarget.minimum,
                    minHeight: BLHitTarget.minimum,
                    alignment: .leading
                )
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(.blAccent)
                .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier(BLAccessibilityID.Orders.listLoadFailureRetryButton)
    }
}

// MARK: - Preview

#Preview("訂單清單載入失敗") {
    OrdersListLoadFailureRow(
        horizontalInset: BLSpacing.large,
        message: "orders.general.message.ordersLoadedTry"
    ) {
    }
}
