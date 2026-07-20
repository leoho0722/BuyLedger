//
//  OrderRowView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單列表中的單列摘要
struct OrderRowView: View {

    // MARK: - View Properties

    /// 要顯示的訂單
    let order: LedgerOrder

    /// 是否在列內顯示訂購日期
    ///
    /// 訂單列表頁已改以「日期區段標題」分組呈現日期 (見 ``OrdersCompactView``)，列內毋須重複，故傳 `false`；
    /// Dashboard 近期訂單為不分組的精簡清單，仍需列內日期提供時間感，故維持預設 `true`
    var showsDate: Bool = true

    /// 右欄呈現變體，預設為訂單頁的「狀態膠囊 + 實際收款 + 損益」
    var trailing: Trailing = .statusAndProfit

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 目前的動態字級；無障礙字級下改變列的結構
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - View Body

    /// 訂單列的畫面內容
    ///
    /// 採三欄結構，並把「會換行的文字」(名稱、商品明細、類別膠囊) 與「短而固定的資訊」(狀態膠囊、金額) 分開：
    /// - 左欄 (彈性寬)：名稱完整顯示、必要時換行；商品明細與類別膠囊同樣允許多行
    /// - 右欄 (短/固定)：狀態膠囊與金額垂直堆疊、整體置中
    ///
    /// 如此任何長字串都只會往下長高、不會把列撐得比可用寬度寬，避免外層垂直 ScrollView 內容溢出造成整頁左右邊距跑版
    var body: some View {
        HStack(spacing: BLSpacing.medium) {
            // 姓名就在同一列，頭像屬重複資訊；標為裝飾避免被朗讀兩次
            BLAvatar(
                name: order.customer.name,
                initials: order.customer.initials,
                size: 40,
                isDecorative: true
            )

            VStack(alignment: .leading, spacing: BLSpacing.small) {
                // 名稱完整顯示、需要時換行 (含無空白長字串的字元級換行)，不截斷
                // `fixedSize(horizontal: false, vertical: true)` 表示「接受容器給的寬度、改往下長高」
                Text(order.customer.name)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                if showsDate {
                    Text(OrderFormatters.shortDate(order.date, locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(order.itemSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !categoriesTagText.isEmpty {
                    BLTagPill(categoriesTagText, systemImage: "tag")
                }

                // 無障礙字級下右欄會被擠到極窄；改置於左欄下方，讓狀態與金額有完整寬度可用
                if dynamicTypeSize.isAccessibilitySize {
                    trailingColumn
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右欄與金額同欄、整體垂直置中 (外層 HStack 維持預設 .center)，內容依 trailing 變體切換
            if !dynamicTypeSize.isAccessibilitySize {
                trailingColumn
            }
        }
        .padding(.vertical, BLSpacing.extraSmall)
        // 複合列合併為單一朗讀單位，否則輔助技術要逐一走過姓名、日期、明細、類別、狀態與兩個金額
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Nested Types

extension OrderRowView {

    /// 右欄呈現變體
    ///
    /// 預設 ``statusAndProfit`` 維持訂單列表與 Dashboard 的「狀態膠囊 + 實際收款 + 損益」
    ///
    /// ``chargedAmount`` 供合併候選列等需要客戶實付的情境使用——僅替換右欄，左欄 (頭像、名稱、日期、商品明細、類別 tag) 與預設變體完全一致
    enum Trailing {

        // MARK: - Cases

        /// 狀態膠囊、實際收款與損益 (訂單列表與 Dashboard 預設)
        case statusAndProfit

        /// 客戶實付金額與「客戶實付」標籤 (合併候選列)
        case chargedAmount
    }
}

// MARK: - ViewBuilder

private extension OrderRowView {

    /// 右欄內容，依 ``Trailing`` 變體切換
    @ViewBuilder
    var trailingColumn: some View {
        switch trailing {
        case .statusAndProfit:
            let summary = order.summary

            VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                BLStatusPill(order.status.title, tone: order.status.tone)

                Text(OrderFormatters.twd(summary.revenue, locale: locale))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text("\(summary.profit >= 0 ? "+" : "")\(OrderFormatters.twd(summary.profit, locale: locale))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.profit >= 0 ? .green : .red)
                    .monospacedDigit()
            }

        case .chargedAmount:
            VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                Text(OrderFormatters.twd(order.chargedAmount, locale: locale))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text("客戶實付")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Internal Method

extension OrderRowView {

    /// 第三行類別 tag 的顯示文字：以「、」串接全部非空白類別 (單一 capsule)；無有效類別時為空字串、不渲染第三行。開放 internal 供單元測試斷言 join/缺席邏輯
    /// - Parameter categories: 訂單的類別清單
    /// - Returns: tag 顯示文字
    static func categoriesTagText(for categories: [String]) -> String {
        categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "、")
    }
}

// MARK: - Private Method

private extension OrderRowView {

    /// 第三行類別 tag 的顯示文字 (instance 便利存取)
    var categoriesTagText: String {
        Self.categoriesTagText(for: order.categories)
    }
}

// MARK: - Preview

#Preview("訂單列") {
    List {
        OrderRowView(order: LedgerOrder.sampleOrders[0])

        OrderRowView(order: LedgerOrder.sampleOrders[0], trailing: .chargedAmount)
    }
}
