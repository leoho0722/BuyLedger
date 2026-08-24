//
//  OrderDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單詳情與成本拆解畫面
struct OrderDetailView: View {
    
    // MARK: - View Properties
    
    /// 要顯示的訂單
    let order: LedgerOrder
    
    /// 詳情頁的版面樣式
    var layout: OrderDetailLayout = .compact
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    // MARK: - View Body
    
    /// 訂單詳情的畫面內容
    var body: some View {
        let palette = BLPalette()
        let summary = order.summary
        
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.large) {
                    header(palette: palette)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    switch layout {
                    case .compact:
                        orderSourceCard(palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        profitCard(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if hasCardlessAdjustments {
                            cardlessAdjustmentsCard(palette: palette)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if hasCostBreakdown {
                            compactCostBreakdown(summary: summary, palette: palette)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        compactItemList
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if hasNotes {
                            compactNotes
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                    case .wide:
                        orderSourceCard(palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        kpiThreeUp(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if hasCardlessAdjustments {
                            cardlessAdjustmentsCard(palette: palette)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        wideBreakdownAndItems(summary: summary, palette: palette)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if hasNotes {
                            wideNotesCard(palette: palette)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailRoot)
        }
        .background(palette.background)
    }
}

// MARK: - Nested Types

extension OrderDetailView {
    
    /// 訂單詳情頁可採用的版面樣式
    enum OrderDetailLayout {
        
        // MARK: - Cases
        
        /// 窄欄版面 (iPhone push 詳情)
        case compact
        
        /// 寬欄版面 (iPad detail)
        case wide
    }
    
    /// 訂單詳情頁使用的版面限制
    private enum OrderDetailLayoutMetrics {
        
        // MARK: - Static Properties
        
        /// 詳情內容在寬視窗與全螢幕下的最大可讀寬度
        static let maximumContentWidth: CGFloat = 1_440
        
        // MARK: - Private Method
        
        /// 依照 detail 欄目前可用寬度回傳內容容器寬度
        /// - Parameter availableWidth: detail 欄目前可用寬度
        /// - Returns: 套用最大寬度上限後的內容容器寬度
        static func contentWidth(for availableWidth: CGFloat) -> CGFloat {
            min(max(availableWidth, 0), maximumContentWidth)
        }
    }
    
    /// 成本拆解中的單一項目
    fileprivate struct OrderCostComponent: Identifiable {
        
        // MARK: - Identifiable Properties
        
        /// 成本項目的穩定識別值
        var id: String { title }
        
        // MARK: - Data Properties
        
        /// 成本項目名稱
        let title: String
        
        /// 成本項目金額
        let value: Decimal
        
        /// 成本項目顏色
        let color: Color
    }
}

// MARK: - ViewBuilder

private extension OrderDetailView {
    
    /// 訂單標頭內容
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 訂單標頭 view
    @ViewBuilder
    func header(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(order.displayID)
                .font(BLTypographyStyle.footnote.font.monospacedDigit())
                .foregroundStyle(palette.secondaryLabel)
            
            HStack(spacing: BLSpacing.small) {
                BLStatusPill(order.status.title, tone: order.status.tone)
                
                Text(OrderFormatters.shortDate(order.date, locale: locale))
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                
                Text("·")
                    .foregroundStyle(palette.secondaryLabel)
                
                Text(currencyDisplayText(for: order.currency))
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 顯示訂單來源的卡片
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 訂單來源卡片 view
    @ViewBuilder
    func orderSourceCard(palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                infoPair(
                    title: "訂單來源",
                    value: orderSourceDisplayText,
                    palette: palette
                )
                
                infoPair(
                    title: "商品類別",
                    value: categoriesDisplayText,
                    palette: palette
                )
                
                infoPair(
                    title: "開團",
                    value: campaignsDisplayText,
                    palette: palette
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 顯示來源卡片中的欄位標題與內容
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - value: 顯示值
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 標題與值的直排 view
    @ViewBuilder
    func infoPair(
        title: String,
        value: String,
        palette: BLPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(LocalizedStringKey(title))
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .textCase(.uppercase)
            
            Text(value)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(palette.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Compact layout
    
    /// 收款、成本與獲利摘要卡片
    /// - Parameters:
    ///   - summary: 訂單財務摘要
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 財務摘要 view
    @ViewBuilder
    func profitCard(summary: OrderSummary, palette: BLPalette) -> some View {
        let profitValue = """
            \(summary.profit >= 0 ? "+" : "")\
            \(OrderFormatters.twd(summary.profit, locale: locale))
            """
        let revenueValue = OrderFormatters.twd(summary.revenue, locale: locale)
        let costValue = OrderFormatters.twd(summary.totalCost, locale: locale)
        
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                        Text("獲利")
                            .font(BLTypographyStyle.footnote.font.weight(.semibold))
                            .foregroundStyle(palette.secondaryLabel)
                        
                        Text(profitValue)
                            .blTextStyle(.largeTitle)
                            .foregroundStyle(summary.profit >= 0 ? palette.green : palette.red)
                            .monospacedDigit()
                    }
                    // 合併朗讀，主要數值由 accessibilityValue 承載供 UI 測試讀取
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.profit))
                    .accessibilityValue(profitValue)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                        Text("毛利率")
                            .font(BLTypographyStyle.footnote.font.weight(.semibold))
                            .foregroundStyle(palette.secondaryLabel)
                        
                        Text(OrderFormatters.marginPercent(summary, locale: locale))
                            .blTextStyle(.title3Bold)
                            .monospacedDigit()
                    }
                }
                
                Divider()
                
                HStack {
                    metric(
                        "總收款",
                        value: revenueValue,
                        palette: palette
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.revenue))
                    .accessibilityValue(revenueValue)
                    
                    Spacer()
                    
                    metric(
                        "總成本",
                        value: costValue,
                        palette: palette
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.cost))
                    .accessibilityValue(costValue)
                    
                    Spacer()
                    
                    metric(
                        "手續費",
                        value: OrderFormatters.twd(summary.fees, locale: locale),
                        palette: palette
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 窄欄版面使用的 donut 成本拆解卡片
    /// - Parameters:
    ///   - summary: 訂單財務摘要
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 成本拆解 view
    @ViewBuilder
    func compactCostBreakdown(summary: OrderSummary, palette: BLPalette) -> some View {
        let components = costComponents(palette: palette)
        
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("成本拆解")
                .blTextStyle(.headline)
            
            BLCard {
                VStack(alignment: .leading, spacing: BLSpacing.large) {
                    BLDonutChart(
                        segments: components.map {
                            BLDonutSegment(
                                label: $0.title,
                                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                                color: $0.color,
                                valueDescription: OrderFormatters.twd($0.value, locale: locale)
                            )
                        },
                        centerTitle: "總成本",
                        centerValue: OrderFormatters.twd(summary.totalCost, locale: locale),
                        axisXTitle: language.localized("類別"),
                        axisYTitle: language.localized("占比"),
                        seriesName: language.localized("圈狀圖")
                    )
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: BLSpacing.medium) {
                        ForEach(components) { component in
                            HStack(spacing: BLSpacing.small) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(component.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(LocalizedStringKey(component.title))
                                    .blTextStyle(.footnote)
                                    .foregroundStyle(palette.secondaryLabel)
                                
                                Spacer()
                                
                                Text(OrderFormatters.twd(component.value, locale: locale))
                                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
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
    
    /// 窄欄版面使用的商品明細卡片
    @ViewBuilder
    var compactItemList: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("商品明細")
                .blTextStyle(.headline)
            
            itemsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 窄欄版面使用的備註卡片 (唯讀)；僅在 ``hasNotes`` 為 `true` 時顯示
    @ViewBuilder
    var compactNotes: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("備註")
                .blTextStyle(.headline)
            
            BLCard {
                Text(order.notes)
                    .blTextStyle(.subhead)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Wide layout
    
    /// 寬欄版面使用的 3-up KPI 列
    /// - Parameters:
    ///   - summary: 訂單財務摘要
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 列 view
    @ViewBuilder
    func kpiThreeUp(summary: OrderSummary, palette: BLPalette) -> some View {
        let revenueValue = OrderFormatters.twd(summary.revenue, locale: locale)
        let costValue = OrderFormatters.twd(summary.totalCost, locale: locale)
        let profitValue = """
            \(summary.profit >= 0 ? "+" : "")\
            \(OrderFormatters.twd(summary.profit, locale: locale))
            """
        
        HStack(alignment: .top, spacing: BLSpacing.medium) {
            kpiTile(
                label: "總收款",
                value: revenueValue,
                tint: palette.accent,
                palette: palette
            )
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.revenue))
            .accessibilityValue(revenueValue)
            
            kpiTile(
                label: "總成本",
                value: costValue,
                tint: palette.orange,
                palette: palette
            )
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.cost))
            .accessibilityValue(costValue)
            
            kpiTile(
                label: "獲利",
                value: profitValue,
                delta: OrderFormatters.marginPercent(summary, locale: locale),
                deltaUp: summary.profit >= 0,
                tint: summary.profit >= 0 ? palette.green : palette.red,
                palette: palette
            )
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.profit))
            .accessibilityValue(profitValue)
        }
    }
    
    /// 單一 KPI 卡片
    /// - Parameters:
    ///   - label: 指標標題
    ///   - value: 主要數值
    ///   - delta: 副標數值，例如毛利率，可省略
    ///   - deltaUp: `delta` 是否表示正向變化，影響色彩
    ///   - tint: 標籤前色點與主要數值的強調色
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 卡片 view
    @ViewBuilder
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
                // 純裝飾色點，語意已由標籤文字承載
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                
                Text(LocalizedStringKey(label))
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                    .foregroundStyle(palette.secondaryLabel)
            }
            
            Text(value)
                .blTextStyle(.title2)
                .monospacedDigit()
                .foregroundStyle(palette.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let delta {
                Text(delta)
                    .font(BLTypographyStyle.caption.font.weight(.medium))
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
        // 合併為單一朗讀單位；裝飾色點已先排除
        .accessibilityElement(children: .combine)
    }
    
    /// 寬欄版面：成本拆解條與商品明細並排
    /// - Parameters:
    ///   - summary: 訂單財務摘要
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 兩欄並排 view
    @ViewBuilder
    func wideBreakdownAndItems(summary: OrderSummary, palette: BLPalette) -> some View {
        HStack(alignment: .top, spacing: BLSpacing.medium) {
            if hasCostBreakdown {
                breakdownBarsCard(summary: summary, palette: palette)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            
            wideItemsCard
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    
    /// 寬欄版面使用的成本拆解條卡片
    /// - Parameters:
    ///   - summary: 訂單財務摘要
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 成本拆解條 view
    @ViewBuilder
    func breakdownBarsCard(summary: OrderSummary, palette: BLPalette) -> some View {
        let components = costComponents(palette: palette)
        let totalDouble = NSDecimalNumber(decimal: summary.totalCost).doubleValue
        let total = totalDouble > 0 ? totalDouble : 1
        
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("成本拆解")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                
                ForEach(components) { component in
                    breakdownBarRow(component, total: total, palette: palette)
                }
                
                Divider()
                
                HStack {
                    Text("總成本")
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(palette.label)
                    
                    Spacer()
                    
                    Text(OrderFormatters.twd(summary.totalCost, locale: locale))
                        .font(BLTypographyStyle.subhead.font.bold())
                        .monospacedDigit()
                        .foregroundStyle(palette.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 成本拆解條的單列
    /// - Parameters:
    ///   - component: 成本項目
    ///   - total: 用於計算比例的總成本
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 成本條列 view
    @ViewBuilder
    func breakdownBarRow(
        _ component: OrderCostComponent,
        total: Double,
        palette: BLPalette
    ) -> some View {
        let value = NSDecimalNumber(decimal: component.value).doubleValue
        let fraction = max(0, min(1, value / total))
        
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(component.color)
                    .frame(width: 8, height: 8)
                
                Text(LocalizedStringKey(component.title))
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                
                Spacer()
                
                Text(OrderFormatters.twd(component.value, locale: locale))
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)
            }
            
            // 軌道高度 (6pt) 由共用樣式 BLProgressBarStyle 決定，非本檔控制
            ProgressView(value: fraction)
                .progressViewStyle(BLProgressBarStyle(tint: component.color))
        }
    }
    
    /// 寬欄版面使用的商品明細卡片，含標題
    @ViewBuilder
    var wideItemsCard: some View {
        BLCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("商品明細")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(Color.blSecondaryLabel)
                    .textCase(.uppercase)
                    .padding(.horizontal, BLSpacing.large)
                    .padding(.top, BLSpacing.large)
                    .padding(.bottom, BLSpacing.small)
                
                itemRows
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 寬欄版面的唯讀備註卡片
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 備註卡片 view
    @ViewBuilder
    func wideNotesCard(palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                Text("備註")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                
                Text(order.notes)
                    .blTextStyle(.subhead)
                    .foregroundStyle(palette.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 商品列卡片 (窄欄版面用，內含 BLCard 包覆)
    @ViewBuilder
    var itemsCard: some View {
        BLCard(padding: 0) {
            itemRows
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 商品列序列，不含外層卡片
    @ViewBuilder
    var itemRows: some View {
        VStack(spacing: 0) {
            ForEach(order.items) { item in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                        Text(item.name)
                            .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        
                        Text("數量 \(item.quantity)")
                            .blTextStyle(.caption)
                            .foregroundStyle(Color.blSecondaryLabel)
                    }
                    
                    Spacer()
                    
                    Text(
                        OrderFormatters.currency(
                            item.subtotal,
                            currency: order.currency,
                            locale: locale
                        )
                    )
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .monospacedDigit()
                }
                .padding()
                
                if item.id != order.items.last?.id {
                    Divider()
                }
            }
        }
    }
    
    /// 無卡明細卡片：當訂單為「無卡」類付款方式且有折抵或補款金額時顯示
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 無卡明細卡片 view
    @ViewBuilder
    func cardlessAdjustmentsCard(palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                Text("無卡明細")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                
                HStack {
                    Text("無卡折抵金額")
                        .blTextStyle(.subhead)
                        .foregroundStyle(palette.label)
                    Spacer()
                    Text("-\(OrderFormatters.twd(order.cardlessDeductionAmount, locale: locale))")
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(palette.red)
                }
                
                HStack {
                    Text("無卡補款金額")
                        .blTextStyle(.subhead)
                        .foregroundStyle(palette.label)
                    Spacer()
                    Text("+\(OrderFormatters.twd(order.cardlessSupplementAmount, locale: locale))")
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(palette.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 顯示單一財務指標
    /// - Parameters:
    ///   - title: 指標標題
    ///   - value: 指標值
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 指標 view
    @ViewBuilder
    func metric(
        _ title: String,
        value: String,
        palette: BLPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(LocalizedStringKey(title))
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)
            
            Text(value)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Private Method

private extension OrderDetailView {
    
    /// 有無卡折抵或補款時顯示明細卡片
    var hasCardlessAdjustments: Bool {
        order.cardlessDeductionAmount > 0 || order.cardlessSupplementAmount > 0
    }
    
    /// 是否顯示成本拆解；總成本為 0 時隱藏
    var hasCostBreakdown: Bool {
        order.summary.totalCost > 0
    }
    
    /// trim 後有備註時顯示備註卡片
    var hasNotes: Bool {
        !order.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 訂單來源的顯示文字；trim 後為空時回傳「—」空狀態，不杜撰來源名稱
    var orderSourceDisplayText: String {
        let trimmed = order.orderSource.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }
    
    /// 串接有效商品類別；沒有類別時回傳「—」
    var categoriesDisplayText: String {
        let names = order.categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return names.isEmpty ? "—" : names.joined(separator: "、")
    }
    
    /// 開團顯示文字：以「、」串接全部非空白開團；未歸團回傳「未歸團」
    var campaignsDisplayText: String {
        let names = order.campaignNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return names.isEmpty ? "未歸團" : names.joined(separator: "、")
    }
    
    /// 由 `\.locale` 換算對應的 App 語言
    var language: AppLanguage {
        AppLanguage(locale: locale)
    }
    
    /// 依 App 語言偏好產生幣別顯示文字
    /// - Parameter currency: 訂單幣別
    /// - Returns: 顯示字串
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        guard language == .traditionalChinese else {
            return currency.rawValue
        }
        
        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : name
    }
    
    /// 回傳成本拆解使用的資料
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 成本拆解清單
    func costComponents(palette: BLPalette) -> [OrderCostComponent] {
        // 一般訂單不把運費計入成本，貨到付款則計入三種運費
        // 手續費拆成刷卡、平台與金流三項
        let summary = order.summary
        // 只有貨到付款計入三種運費。
        let codDomesticShipping = order.isCashOnDelivery ? order.domesticShipping : 0
        let codInternationalShipping = order.isCashOnDelivery ? order.internationalShipping : 0
        let codForeignDomesticShipping = order.isCashOnDelivery ? order.foreignDomesticShipping : 0
        return [
            OrderCostComponent(
                title: "商品金額",
                value: order.itemCost,
                color: palette.accent
            ),
            OrderCostComponent(
                title: "刷卡手續費",
                value: summary.cardFee,
                color: palette.orange
            ),
            OrderCostComponent(
                title: "平台手續費",
                value: summary.platformFee,
                color: palette.teal
            ),
            OrderCostComponent(
                title: "金流手續費",
                value: summary.paymentFee,
                color: palette.purple
            ),
            OrderCostComponent(
                title: "國內運費",
                value: codDomesticShipping,
                color: palette.indigo
            ),
            OrderCostComponent(
                title: "國際運費",
                value: codInternationalShipping,
                color: palette.pink
            ),
            OrderCostComponent(
                title: "外國國內運費",
                value: codForeignDomesticShipping,
                color: palette.yellow
            ),
        ]
            .filter { $0.value > 0 }
    }
    
    /// 將 KPI delta 的方向轉換為色彩
    /// - Parameters:
    ///   - up: 是否為正向變化。`nil` 視為中性
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 對應 delta 文字色
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
