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
    var showsDate: Bool = true
    
    /// 右欄呈現變體，預設為訂單頁的「狀態膠囊 + 實際收款 + 損益」
    var trailing: Trailing = .statusAndProfit
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 目前的動態字級；無障礙字級下改變列的結構
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // MARK: - View Body
    
    /// 訂單列的畫面內容
    var body: some View {
        HStack(spacing: BLSpacing.medium) {
            // 姓名就在同一列，頭像屬重複資訊；標為裝飾避免被朗讀兩次
            BLAvatar(
                name: order.customer.name,
                initials: order.customer.initials,
                size: BLListMetrics.avatarSize,
                isDecorative: true
            )
            
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                // 名稱完整顯示，長字串需要換行
                // fixedSize 讓文字使用可用寬度並向下延伸
                Text(order.customer.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                
                if showsDate {
                    Text(OrderFormatters.shortDate(order.date, locale: locale))
                        .blTextStyle(.caption)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
                
                Text(order.itemSummary)
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !categoriesTagText.isEmpty {
                    BLTagPill(categoriesTagText, systemImage: "tag")
                }
                
                // 無障礙字級時將右欄移到左欄下方。
                if dynamicTypeSize.isAccessibilitySize {
                    trailingColumn
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 一般字級時將右欄放在同一列。
            if !dynamicTypeSize.isAccessibilitySize {
                trailingColumn
            }
        }
        .padding(.vertical, BLSpacing.extraSmall)
        // 將複合列合併為單一朗讀單位。
        .accessibilityElement(children: .combine)
        // 合併列的關鍵數值放在 accessibilityValue，讓 UI 測試讀取
        .accessibilityValue(accessibilityValueText)
    }
}

// MARK: - Nested Types

extension OrderRowView {
    
    /// 右欄呈現變體
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
        let palette = BLPalette()
        
        switch trailing {
        case .statusAndProfit:
            let summary = order.summary
            
            VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                BLStatusPill(order.status.title, tone: order.status.tone)
                
                // 金額已放入 accessibilityValue，避免重複朗讀。
                Text(OrderFormatters.twd(summary.revenue, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .monospacedDigit()
                    .accessibilityHidden(true)
                
                Text(
                    """
                    \(summary.profit >= 0 ? "+" : "")\
                    \(OrderFormatters.twd(summary.profit, locale: locale))
                    """
                )
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .foregroundStyle(summary.profit >= 0 ? palette.green : palette.red)
                .monospacedDigit()
                .accessibilityHidden(true)
            }
            
        case .chargedAmount:
            VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                // 金額已放入 accessibilityValue，避免重複朗讀。
                Text(OrderFormatters.twd(order.chargedAmount, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .monospacedDigit()
                    .accessibilityHidden(true)
                
                Text("客戶實付")
                    .blTextStyle(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Internal Method

extension OrderRowView {
    
    /// 類別 tag 顯示文字；沒有有效類別時為空字串
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
    
    /// 類別 tag 顯示文字；沒有有效類別時為空字串
    var categoriesTagText: String {
        Self.categoriesTagText(for: order.categories)
    }
    
    /// 合併列朗讀的關鍵數值
    var accessibilityValueText: String {
        switch trailing {
        case .statusAndProfit:
            let summary = order.summary
            let revenue = OrderFormatters.twd(summary.revenue, locale: locale)
            let profitSign = summary.profit >= 0 ? "+" : ""
            let profit = "\(profitSign)\(OrderFormatters.twd(summary.profit, locale: locale))"
            return "\(revenue) \(profit)"
            
        case .chargedAmount:
            return OrderFormatters.twd(order.chargedAmount, locale: locale)
        }
    }
}

// MARK: - Preview

#Preview("訂單列") {
    List {
        OrderRowView(order: LedgerOrder.sampleOrders[0])
        
        OrderRowView(order: LedgerOrder.sampleOrders[0], trailing: .chargedAmount)
    }
}
