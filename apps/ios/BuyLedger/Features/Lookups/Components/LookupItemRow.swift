//
//  LookupItemRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import SwiftUI

/// 顯示主檔名稱與付款方式分類
struct LookupItemRow: View {

    // MARK: - Properties

    /// 付款方式分類；`nil` 表示此主檔沒有分類
    let classification: PaymentMethodFlags?

    /// 主檔項目名稱
    let name: String

    // MARK: - Body

    /// 顯示名稱，付款方式另顯示已啟用的分類
    var body: some View {
        if let classification {
            classifiedRow(classification)
        } else {
            Text(name)
        }
    }
}

// MARK: - Private Views

private extension LookupItemRow {

    /// 顯示名稱與已啟用的付款方式分類
    ///
    /// - Parameter classification: 付款方式分類旗標
    /// - Returns: 合併成單一無障礙元素的付款方式列
    func classifiedRow(_ classification: PaymentMethodFlags) -> some View {
        HStack(spacing: BLSpacing.small) {
            Text(name)

            Spacer()

            if classification.isCardless {
                classificationBadge("無卡")
            }

            if classification.isBankTransfer {
                classificationBadge("銀行匯款")
            }

            if classification.isCashOnDelivery {
                classificationBadge("貨到付款")
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// 付款方式分類的膠囊徽章
    ///
    /// - Parameter title: 徽章文字
    /// - Returns: 分類徽章
    func classificationBadge(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .padding(.horizontal, BLSpacing.small)
            .padding(.vertical, 2)
            .font(BLTypographyStyle.caption.font.weight(.semibold))
            .foregroundStyle(.tint)
            .background(
                Capsule()
                    .fill(BLPalette().accent.opacity(0.12))
            )
    }
}

// MARK: - Preview

#Preview("一般主檔項目") {
    LookupItemRow(classification: nil, name: "服飾")
}

#Preview("含三種分類的付款方式") {
    LookupItemRow(
        classification: PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        ),
        name: "綜合付款方式"
    )
}
