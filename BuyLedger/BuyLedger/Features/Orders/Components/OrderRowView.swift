//
//  OrderRowView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單列表中的單列摘要。
struct OrderRowView: View {

    // MARK: - View Properties

    /// 要顯示的訂單。
    let order: LedgerOrder

    /// 是否在列內顯示訂購日期。
    ///
    /// 訂單列表頁已改以「日期區段標題」分組呈現日期 (見 ``OrdersCompactView``)，列內毋須重複，故傳 `false`；
    /// Dashboard 近期訂單為不分組的精簡清單，仍需列內日期提供時間感，故維持預設 `true`。
    var showsDate: Bool = true

    // MARK: - View Body

    /// 訂單列的畫面內容。
    ///
    /// 採三欄結構，並把「會換行的文字」(名稱、商品明細、類別膠囊) 與「短而固定的資訊」(狀態膠囊、金額) 分開：
    /// - 左欄 (彈性寬)：名稱完整顯示、必要時換行；商品明細與類別膠囊同樣允許多行。
    /// - 右欄 (短/固定)：狀態膠囊與金額垂直堆疊、整體置中。
    ///
    /// 如此任何長字串都只會往下長高、不會把列撐得比可用寬度寬，避免外層垂直 ScrollView 內容溢出造成整頁左右邊距跑版。
    var body: some View {
        let summary = order.summary

        HStack(spacing: BLSpacing.medium) {
            BLAvatar(
                name: order.customer.name,
                initials: order.customer.initials,
                size: 40
            )

            VStack(alignment: .leading, spacing: BLSpacing.small) {
                // 名稱完整顯示、需要時換行 (含無空白長字串的字元級換行)，不截斷。
                // `fixedSize(horizontal: false, vertical: true)` 表示「接受容器給的寬度、改往下長高」。
                Text(order.customer.name)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                if showsDate {
                    Text(OrderFormatters.shortDate(order.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(order.itemSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !order.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    BLTagPill(order.category, systemImage: "tag")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 狀態膠囊與金額同欄、整體垂直置中 (外層 HStack 維持預設 .center)。
            VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                BLStatusPill(order.status.title, tone: order.status.tone)

                Text(OrderFormatters.twd(summary.revenue))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text("\(summary.profit >= 0 ? "+" : "")\(OrderFormatters.twd(summary.profit))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.profit >= 0 ? .green : .red)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, BLSpacing.extraSmall)
    }
}

// MARK: - ViewBuilder

private extension OrderRowView {}

// MARK: - Preview

#Preview("訂單列") {
    List {
        OrderRowView(order: LedgerOrder.sampleOrders[0])
    }
}
