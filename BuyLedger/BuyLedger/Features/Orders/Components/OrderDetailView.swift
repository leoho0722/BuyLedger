//
//  OrderDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單詳情與成本拆解畫面。
///
/// 透過 ``layout`` 參數在窄欄（iPhone push）與寬欄（iPad detail / macOS inspector）之間切換不同的版面結構。
struct OrderDetailView: View {
    
    // MARK: - View Properties
    
    /// 要顯示的訂單。
    let order: LedgerOrder
    
    /// 詳情頁的版面樣式。
    var layout: OrderDetailLayout = .compact
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - View Body
    
    /// 訂單詳情的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let summary = order.summary
        
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.large) {
                    header(palette: palette)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    switch layout {
                    case .compact:
                        profitCard(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        compactCostBreakdown(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        compactItemList
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    case .wide:
                        kpiThreeUp(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        wideBreakdownAndItems(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.large)
                .frame(
                    width: OrderDetailLayoutMetrics.contentWidth(for: proxy.size.width),
                    alignment: .topLeading
                )
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(palette.background)
        }
        .background(palette.background)
    }
}

// MARK: - Layout Constant

/// 訂單詳情頁可採用的版面樣式。
enum OrderDetailLayout {
    
    // MARK: - Cases
    
    /// 窄欄版面（iPhone push 詳情）。
    ///
    /// 採單欄序列：標頭 → 獲利摘要卡 → donut 成本拆解 → 商品明細。
    case compact
    
    /// 寬欄版面（iPad detail、macOS inspector）。
    ///
    /// 採設計稿的 3-up KPI 加上 2-col「成本拆解條 + 商品明細」並排。
    case wide
}

/// 訂單詳情頁使用的版面限制。
private enum OrderDetailLayoutMetrics {
    
    // MARK: - Static Properties
    
    /// 詳情內容在寬視窗與全螢幕下的最大可讀寬度。
    static let maximumContentWidth: CGFloat = 1_440
    
    // MARK: - Static Method
    
    /// 依照 detail 欄目前可用寬度回傳內容容器寬度。
    /// - Parameter availableWidth: detail 欄目前可用寬度。
    /// - Returns: 套用最大寬度上限後的內容容器寬度。
    static func contentWidth(for availableWidth: CGFloat) -> CGFloat {
        min(max(availableWidth, 0), maximumContentWidth)
    }
}

// MARK: - ViewBuilder

private extension OrderDetailView {
    
    /// 訂單標頭內容。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 訂單標頭 view。
    func header(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(order.id)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(palette.secondaryLabel)
            
            HStack(spacing: BLSpacing.small) {
                BLStatusPill(order.status.title, tone: order.status.tone)
                
                Text(OrderFormatters.shortDate(order.date))
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                
                Text("·")
                    .foregroundStyle(palette.tertiaryLabel)
                
                Text(order.currency.rawValue)
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Compact layout
    
    /// 收款、成本與獲利摘要卡片。
    /// - Parameters:
    ///   - summary: 訂單財務摘要。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 財務摘要 view。
    func profitCard(summary: OrderSummary, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                        Text("獲利")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(palette.secondaryLabel)
                        
                        Text("\(summary.profit >= 0 ? "+" : "")\(OrderFormatters.twd(summary.profit))")
                            .font(.largeTitle.bold())
                            .foregroundStyle(summary.profit >= 0 ? palette.green : palette.red)
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                        Text("毛利率")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(palette.secondaryLabel)
                        
                        Text(OrderFormatters.percent(summary.margin))
                            .font(.title3.bold())
                            .monospacedDigit()
                    }
                }
                
                Divider()
                
                HStack {
                    metric(
                        "總收款",
                        value: OrderFormatters.twd(summary.revenue),
                        palette: palette
                    )
                    Spacer()
                    metric(
                        "總成本",
                        value: OrderFormatters.twd(summary.totalCost),
                        palette: palette
                    )
                    Spacer()
                    metric(
                        "手續費",
                        value: OrderFormatters.twd(summary.fees),
                        palette: palette
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 窄欄版面使用的 donut 成本拆解卡片。
    /// - Parameters:
    ///   - summary: 訂單財務摘要。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 成本拆解 view。
    func compactCostBreakdown(summary: OrderSummary, palette: BLPalette) -> some View {
        let components = costComponents(palette: palette)
        
        return VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("成本拆解")
                .font(.headline)
            
            BLCard {
                HStack(alignment: .center, spacing: BLSpacing.large) {
                    BLDonutChart(
                        segments: components.map {
                            BLDonutSegment(
                                label: $0.title,
                                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                                color: $0.color
                            )
                        },
                        centerTitle: "總成本",
                        centerValue: OrderFormatters.twd(summary.totalCost)
                    )
                    
                    VStack(alignment: .leading, spacing: BLSpacing.medium) {
                        ForEach(components) { component in
                            HStack(spacing: BLSpacing.small) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(component.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(component.title)
                                    .font(.footnote)
                                    .foregroundStyle(palette.secondaryLabel)
                                
                                Spacer()
                                
                                Text(OrderFormatters.twd(component.value))
                                    .font(.footnote.weight(.semibold))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 窄欄版面使用的商品明細卡片。
    var compactItemList: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("商品明細")
                .font(.headline)
            
            itemsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Wide layout
    
    /// 寬欄版面使用的 3-up KPI 列。
    /// - Parameters:
    ///   - summary: 訂單財務摘要。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: KPI 列 view。
    func kpiThreeUp(summary: OrderSummary, palette: BLPalette) -> some View {
        HStack(alignment: .top, spacing: BLSpacing.medium) {
            kpiTile(
                label: "總收款",
                value: OrderFormatters.twd(summary.revenue),
                tint: palette.accent,
                palette: palette
            )
            kpiTile(
                label: "總成本",
                value: OrderFormatters.twd(summary.totalCost),
                tint: palette.orange,
                palette: palette
            )
            kpiTile(
                label: "獲利",
                value: "\(summary.profit >= 0 ? "+" : "")\(OrderFormatters.twd(summary.profit))",
                delta: OrderFormatters.percent(summary.margin),
                deltaUp: summary.profit >= 0,
                tint: summary.profit >= 0 ? palette.green : palette.red,
                palette: palette
            )
        }
    }
    
    /// 單一 KPI 卡片。
    /// - Parameters:
    ///   - label: 指標標題。
    ///   - value: 主要數值。
    ///   - delta: 副標數值，例如毛利率，可省略。
    ///   - deltaUp: `delta` 是否表示正向變化，影響色彩。
    ///   - tint: 標籤前色點與主要數值的強調色。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: KPI 卡片 view。
    func kpiTile(
        label: String,
        value: String,
        delta: String? = nil,
        deltaUp: Bool? = nil,
        tint: Color,
        palette: BLPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(palette.secondaryLabel)
            }
            
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(palette.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let delta {
                Text(delta)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(deltaColor(deltaUp, palette: palette))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                .stroke(palette.separator, lineWidth: 0.5)
        }
    }
    
    /// 寬欄版面：成本拆解條與商品明細並排。
    /// - Parameters:
    ///   - summary: 訂單財務摘要。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 兩欄並排 view。
    func wideBreakdownAndItems(summary: OrderSummary, palette: BLPalette) -> some View {
        HStack(alignment: .top, spacing: BLSpacing.medium) {
            breakdownBarsCard(summary: summary, palette: palette)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            wideItemsCard
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    
    /// 寬欄版面使用的成本拆解條卡片。
    /// - Parameters:
    ///   - summary: 訂單財務摘要。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 成本拆解條 view。
    func breakdownBarsCard(summary: OrderSummary, palette: BLPalette) -> some View {
        let components = costComponents(palette: palette)
        let totalDouble = NSDecimalNumber(decimal: summary.totalCost).doubleValue
        let total = totalDouble > 0 ? totalDouble : 1
        
        return BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("成本拆解")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                
                ForEach(components) { component in
                    breakdownBarRow(component, total: total, palette: palette)
                }
                
                Divider()
                
                HStack {
                    Text("總成本")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.label)
                    
                    Spacer()
                    
                    Text(OrderFormatters.twd(summary.totalCost))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(palette.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 成本拆解條的單列。
    /// - Parameters:
    ///   - component: 成本項目。
    ///   - total: 用於計算比例的總成本。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 成本條列 view。
    func breakdownBarRow(
        _ component: OrderCostComponent,
        total: Double,
        palette: BLPalette
    ) -> some View {
        let value = NSDecimalNumber(decimal: component.value).doubleValue
        let fraction = max(0, min(1, value / total))
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(component.color)
                    .frame(width: 8, height: 8)
                
                Text(component.title)
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                
                Spacer()
                
                Text(OrderFormatters.twd(component.value))
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.fillQuaternary)
                    
                    Capsule()
                        .fill(component.color)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 5)
        }
    }
    
    /// 寬欄版面使用的商品明細卡片，含標題。
    var wideItemsCard: some View {
        BLCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("商品明細")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, BLSpacing.large)
                    .padding(.top, BLSpacing.large)
                    .padding(.bottom, BLSpacing.small)
                
                itemRows
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 商品列卡片（窄欄版面用，內含 BLCard 包覆）。
    var itemsCard: some View {
        BLCard(padding: 0) {
            itemRows
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 商品列序列，不含外層卡片。
    var itemRows: some View {
        VStack(spacing: 0) {
            ForEach(order.items) { item in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        
                        Text("數量 \(item.quantity)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(OrderFormatters.currency(item.subtotal, currency: order.currency))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                .padding()
                
                if item.id != order.items.last?.id {
                    Divider()
                }
            }
        }
    }
    
    /// 顯示單一財務指標。
    /// - Parameters:
    ///   - title: 指標標題。
    ///   - value: 指標值。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 指標 view。
    func metric(_ title: String, value: String, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(title)
                .font(.caption)
                .foregroundStyle(palette.secondaryLabel)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Private Method

private extension OrderDetailView {
    
    /// 回傳成本拆解使用的資料。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 成本拆解清單。
    func costComponents(palette: BLPalette) -> [OrderCostComponent] {
        [
            OrderCostComponent(
                title: "商品金額",
                value: order.itemCost,
                color: palette.accent
            ),
            OrderCostComponent(
                title: "國內運費",
                value: order.domesticShipping,
                color: palette.teal
            ),
            OrderCostComponent(
                title: "國際集運",
                value: order.internationalShipping,
                color: palette.purple
            ),
            OrderCostComponent(
                title: "手續費",
                value: order.summary.fees,
                color: palette.orange
            ),
        ]
            .filter { $0.value > 0 }
    }
    
    /// 將 KPI delta 的方向轉換為色彩。
    /// - Parameters:
    ///   - up: 是否為正向變化。`nil` 視為中性。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 對應 delta 文字色。
    func deltaColor(_ up: Bool?, palette: BLPalette) -> Color {
        switch up {
        case .some(true):
            return palette.green
        case .some(false):
            return palette.red
        case .none:
            return palette.tertiaryLabel
        }
    }
}

/// 成本拆解中的單一項目。
private struct OrderCostComponent: Identifiable {
    
    // MARK: - Identifiable Properties
    
    /// 成本項目的穩定識別值。
    var id: String { title }
    
    // MARK: - Data Properties
    
    /// 成本項目名稱。
    let title: String
    
    /// 成本項目金額。
    let value: Decimal
    
    /// 成本項目顏色。
    let color: Color
}

// MARK: - Preview

#Preview("訂單詳情 · 窄欄") {
    NavigationStack {
        OrderDetailView(
            order: LedgerOrder.sampleOrders[0]
        )
    }
}

#Preview("訂單詳情 · 寬欄") {
    OrderDetailView(
        order: LedgerOrder.sampleOrders[0],
        layout: .wide
    )
    .frame(width: 720, height: 720)
}
