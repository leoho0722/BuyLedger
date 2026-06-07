//
//  BLAmountField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 強調金額輸入情境的標籤式欄位。
struct BLAmountField: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 欄位上方顯示的標題。
    let title: String

    /// 金額文字的雙向繫結。
    @Binding var amount: String

    // MARK: - View Body

    /// 金額輸入欄的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.accent)

            TextField("0", text: $amount)
                .textFieldStyle(.plain)
                .font(.title2.bold())
                .foregroundStyle(palette.label)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(palette.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: BLRadius.small,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: BLRadius.small,
                style: .continuous
            )
            .stroke(palette.accent, lineWidth: 1.5)
        }
    }
}

// MARK: - Preview

#Preview("金額輸入欄") {
    BLAmountField(title: "金額", amount: .constant("1,280"))
        .padding()
}
