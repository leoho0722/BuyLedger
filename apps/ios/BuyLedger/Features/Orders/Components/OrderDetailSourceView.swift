//
//  OrderDetailSourceView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 詳情的訂單來源、商品類別與開團卡片
struct OrderDetailSourceView: View {

    // MARK: - Properties

    /// 開團名稱的顯示文字，沒有有效開團時為 `nil`，畫面改顯示未歸團
    let campaignNamesText: String?

    /// 商品類別的顯示文字，沒有有效類別時為空狀態符號
    let categoriesText: String

    /// 訂單來源的顯示文字，空白時為空狀態符號
    let orderSourceText: String

    // MARK: - Body

    /// 畫面骨架，內容由下方的具名區段組成
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                infoPair(title: "orders.detail.label.orderSource") {
                    orderSource
                }

                infoPair(title: "orders.list.label.itemCategory") {
                    categories
                }

                infoPair(title: "orders.detail.title.campaigns") {
                    campaigns
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension OrderDetailSourceView {

    /// 訂單來源的顯示文字
    var orderSource: some View {
        Text(orderSourceText)
    }

    /// 商品類別的顯示文字
    var categories: some View {
        Text(categoriesText)
    }

    /// 開團的顯示文字，沒有有效開團時顯示未歸團
    @ViewBuilder
    var campaigns: some View {
        if let campaignNamesText {
            Text(campaignNamesText)
        } else {
            // 未歸團有翻譯，需以字面值交給 `Text` 查表，經 `String` 變數傳入會原樣顯示
            Text("orders.detail.label.unassigned")
        }
    }

    /// 顯示來源卡片中的欄位標題與內容
    ///
    /// - Parameters:
    ///   - title: 欄位的本地化標題
    ///   - content: 要顯示的欄位內容
    /// - Returns: 標題與內容的直排區段
    func infoPair<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(title)
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .textCase(.uppercase)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(palette.label)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Private Method

private extension OrderDetailSourceView {

    /// 來源卡片使用的目前外觀色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("詳情的訂單來源、商品類別與開團卡片") {
    let detail = OrderDetailFeature.State(
        orderID: LedgerOrder.sampleOrders[0].id,
        orders: SharedReader(value: LedgerOrder.sampleOrders)
    )

    OrderDetailSourceView(
        campaignNamesText: detail.campaignNamesText,
        categoriesText: detail.categoriesText,
        orderSourceText: detail.orderSourceText
    )
}
