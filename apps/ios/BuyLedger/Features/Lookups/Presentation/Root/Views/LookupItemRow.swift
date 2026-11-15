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

    /// App 語言的 `locale`，用來解析分類名稱與串接清單
    @Environment(\.locale) private var locale

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
            plainRow
        }
    }
}

// MARK: - Private Views

private extension LookupItemRow {

    /// 顯示名稱與已啟用的付款方式分類
    ///
    /// - Parameter classification: 付款方式分類旗標
    /// - Returns: 合併成單一無障礙元素的付款方式列，已啟用的分類名稱放在其 `accessibilityValue`
    @ViewBuilder
    func classifiedRow(_ classification: PaymentMethodFlags) -> some View {
        let classificationNames = enabledClassificationNames(classification)

        HStack(spacing: BLSpacing.small) {
            Text(name)

            Spacer()

            if classification.isCardless {
                classificationBadge("orders.detail.label.cardless")
            }

            if classification.isBankTransfer {
                classificationBadge("orders.edit.label.bankTransfer")
            }

            if classification.isCashOnDelivery {
                classificationBadge("orders.list.label.cashDelivery")
            }
        }
        .accessibilityElement(children: .combine)
        // 分類名稱放在 `accessibilityValue`，UI 測試從 `element.value` 讀取
        .accessibilityValue(classificationNames, isEnabled: !classificationNames.isEmpty)
    }

    /// 組出付款方式分類的膠囊徽章，無障礙隱藏，分類名稱由列的 `accessibilityValue` 帶出
    ///
    /// - Parameter title: 徽章文字
    /// - Returns: 分類徽章
    func classificationBadge(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .padding(.horizontal, BLSpacing.small)
            .padding(.vertical, 2)
            .font(BLTypographyStyle.caption.font.weight(.semibold))
            .foregroundStyle(.blAccent)
            .background(Capsule().fill(.blAccent.opacity(0.12)))
            .accessibilityHidden(true)
    }

    /// 只顯示名稱的主檔項目列
    var plainRow: some View {
        Text(name)
    }
}

// MARK: - Private Method

private extension LookupItemRow {

    /// 依 App 語言解析已啟用的付款方式分類名稱，以清單格式串接
    ///
    /// - Parameter classification: 付款方式分類旗標
    /// - Returns: 串接後的分類名稱；沒有任何分類啟用時為空字串
    func enabledClassificationNames(_ classification: PaymentMethodFlags) -> String {
        var titles: [LocalizedStringResource] = []
        if classification.isCardless {
            titles.append("orders.detail.label.cardless")
        }
        if classification.isBankTransfer {
            titles.append("orders.edit.label.bankTransfer")
        }
        if classification.isCashOnDelivery {
            titles.append("orders.list.label.cashDelivery")
        }
        guard !titles.isEmpty else {
            return ""
        }
        let names = titles.map { AppLanguage.resolve($0, locale: locale) }
        return names.formatted(.list(type: .and).locale(locale))
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
