//
//  DashboardView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 總覽分頁的主要畫面
struct DashboardView: View {
    
    // MARK: - View Properties
    
    /// 總覽功能 store
    @Bindable var store: StoreOf<DashboardFeature>
    
    /// App 目前選用的顯示語系
    let language: AppLanguage
    
    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone (compact) 與 iPad (regular)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 用來計算「本月／上月」與日期子標的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 月份分組與日期計算使用的行事曆
    @Dependency(\.calendar) private var calendar
    
    /// hero 淨獲利金額字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroProfitSize: CGFloat = 36
    
    /// 目前的動態字級；用來在無障礙字級下改變版面結構
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    /// onboarding 圖示尺寸，隨字級縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var onboardingIconSize: CGFloat = 56
    
    // MARK: - View Body
    
    /// 總覽頁的畫面內容
    var body: some View {
        let palette = BLPalette()
        
        // 依序處理已載入、錯誤與載入中狀態
        // 只判斷「是否已載入」會讓失敗永遠停在轉圈
        // 根 identifier 掛在各 loadState 分支自己的容器上，不掛最外層 group。
        // 不合併外層元素，讓重試鈕與內容可被找到。
        let core = Group {
            switch store.loadState {
            case .loaded:
                ScrollView {
                    content(palette: palette)
                        .padding(.horizontal, BLSpacing.large)
                        .padding(.vertical, BLSpacing.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.root)
                
            case let .failed(message):
                BLLoadFailureView(
                    message: message,
                    retryIdentifier: BLAccessibilityID.Dashboard.loadFailureRetryButton
                ) {
                    store.send(.retryTapped)
                }
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.loadFailure)
                
            case .loading:
                loadingPlaceholder(palette: palette)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.background)
            .task {
                // 進入總覽頁時先載入訂單與設定資料。
                // refresh 只轉發，去重由 OrdersFeature 的載入守衛處理
                await store.send(.task).finish()
            }
        
        // 導覽列由 NavigationStack 建立，測試以畫面根容器判定就緒。
        return NavigationStack {
            core
                .rootNavigationTitle("總覽", language: language)
        }
    }
}

// MARK: - ViewBuilder

private extension DashboardView {
    
    /// 依訂單資料顯示總覽或首次使用畫面
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 內容 view
    @ViewBuilder
    func content(palette: BLPalette) -> some View {
        if store.orders.isEmpty {
            onboardingHero(palette: palette)
        } else {
            let stats = DashboardStats(
                orders: store.orders,
                monthlyGoal: store.monthlyProfitGoalTwd,
                referenceDate: date(),
                calendar: calendar
            )
            
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                titleHeader(palette: palette)
                heroAndKpiRow(stats: stats, palette: palette)
                ongoingCampaignsSection(palette: palette)
                recentOrdersSection(stats: stats, palette: palette)
            }
        }
    }
    
    /// 顯示進行中的開團與進度；沒有資料時隱藏
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 進行中的開團卡 view (無進行中團時為 `EmptyView`)
    @ViewBuilder
    func ongoingCampaignsSection(palette: BLPalette) -> some View {
        // 單次掃描訂單，批次建立各團的畫面投影
        let ongoingCampaigns = store.campaigns.filter { $0.status == .ongoing }
        let summaries = CampaignSummary.batch(
            campaignNames: ongoingCampaigns.map(\.name), orders: store.orders)
        let rows = ongoingCampaigns.map {
            (campaign: $0, summary: summaries[$0.name] ?? CampaignSummary(campaignName: $0.name, orders: []))
        }
        
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("進行中的開團")
                    .blTextStyle(.headline)
                    .foregroundStyle(palette.label)
                
                BLCard {
                    VStack(spacing: BLSpacing.medium) {
                        ForEach(Array(rows.enumerated()), id: \.element.campaign.id) {
                            index, entry in
                            Button {
                                store.send(.delegate(.campaignTapped(entry.campaign.name)))
                            } label: {
                                ongoingCampaignRow(
                                    campaign: entry.campaign, summary: entry.summary,
                                    palette: palette
                                )
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            
                            if index < rows.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 「進行中的開團」卡的單列：團名、筆數／金額與到貨／收款進度
    /// - Parameters:
    ///   - campaign: 進行中的開團
    ///   - summary: 由 ``ongoingCampaignsSection(palette:)`` 一次算好的該團彙總
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 單列 view
    @ViewBuilder
    func ongoingCampaignRow(
        campaign: Campaign,
        summary: CampaignSummary,
        palette: BLPalette
    )
    -> some View
    {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            HStack(spacing: BLSpacing.small) {
                Text(campaign.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                Text(
                    """
                    \(summary.orderCount) 筆 · \
                    \(CampaignFormatters.twd(summary.receivables, locale: locale))
                    """
                )
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)
                .monospacedDigit()
            }
            
            BLProgressBar(
                title: "到貨",
                value: summary.deliveryRatio,
                trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
            )
            
            BLProgressBar(
                title: "收款",
                value: summary.receivedRatio,
                tint: palette.green,
                trailingText: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
            )
        }
    }
    
    /// 首次載入訂單前顯示的骨架
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 骨架 view
    @ViewBuilder
    func loadingPlaceholder(palette: BLPalette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .fill(palette.fillTertiary)
                    .frame(height: 180)
                
                LazyVGrid(columns: kpiColumns, spacing: BLSpacing.small) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                            .fill(palette.fillQuaternary)
                            .frame(height: 88)
                    }
                }
                
                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .fill(palette.fillQuaternary)
                    .frame(height: 240)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
        }
        .scrollDisabled(true)
        .overlay {
            BLDelayedProgressView()
        }
        .accessibilityElement()
        .accessibilityLabel(Text("載入中"))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.loading)
    }
    
    /// 第一次開 App 還沒有任何訂單時的引導畫面
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: onboarding view
    @ViewBuilder
    func onboardingHero(palette: BLPalette) -> some View {
        VStack(spacing: BLSpacing.large) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.accent, palette.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 132, height: 132)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: onboardingIconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            // 純裝飾插圖：訊息由下方文字承載，朗讀符號名稱只是雜訊
            .accessibilityHidden(true)
            
            VStack(spacing: BLSpacing.small) {
                Text("歡迎使用 BuyLedger")
                    .blTextStyle(.title1)
                    .foregroundStyle(palette.label)
                
                Text("還沒有任何訂單。建立第一筆，馬上開始追蹤代購損益。")
                    .blTextStyle(.subhead)
                    .foregroundStyle(palette.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, BLSpacing.large)
            
            Button {
                store.send(.delegate(.newOrderTapped))
            } label: {
                Label("建立第一筆訂單", systemImage: "plus")
            }
            .buttonStyle(BLButtonStyle(variant: .primary))
            .accessibilityIdentifier(BLAccessibilityID.Dashboard.emptyStateActionButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BLSpacing.section * 2)
        // 保留子元素 identifier，讓測試可點擊行動按鈕
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.emptyState)
    }
    
    /// 日期子標
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 標題列 view
    @ViewBuilder
    func titleHeader(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(currentDateSubtitle())
                .font(BLTypographyStyle.footnote.font.weight(.medium))
                .foregroundStyle(palette.secondaryLabel)
        }
    }
    
    /// hero P&L 與 KPI 的並排組合
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: hero + KPI 組合 view
    @ViewBuilder
    func heroAndKpiRow(stats: DashboardStats, palette: BLPalette) -> some View {
        if useWideHero {
            HStack(alignment: .top, spacing: BLSpacing.medium) {
                heroCard(stats: stats, palette: palette)
                    .frame(maxWidth: .infinity)
                
                VStack(spacing: BLSpacing.small) {
                    wideKpiTiles(stats: stats, palette: palette)
                }
                .frame(maxWidth: 320)
            }
        } else {
            VStack(spacing: BLSpacing.medium) {
                heroCard(stats: stats, palette: palette)
                kpiGrid(stats: stats, palette: palette)
            }
        }
    }
    
    /// 寬版面右側的 3 個 KPI 卡片 (直欄排列，與 hero 等高呼應)
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 3 個 KPI 卡片
    @ViewBuilder
    func wideKpiTiles(stats: DashboardStats, palette: BLPalette) -> some View {
        kpiTile(
            kpi: .revenue,
            label: "營業額",
            value: BLFormatters.twd(stats.revenue, locale: locale),
            tint: palette.accent,
            delta: LocalizedStringKey(percentDeltaDisplay(stats.revenueDelta)),
            deltaUp: deltaDirection(stats.revenueDelta),
            palette: palette
        )
        kpiTile(
            kpi: .grossMargin,
            label: "毛利率",
            value: BLFormatters.percent(stats.margin, locale: locale),
            tint: palette.green,
            delta: LocalizedStringKey(marginDeltaDisplay(stats.marginDelta)),
            deltaUp: deltaDirection(stats.marginDelta),
            palette: palette
        )
        kpiTile(
            kpi: .activeOrders,
            label: "進行中訂單",
            value: "\(stats.activeCount)",
            tint: palette.purple,
            delta: "\(stats.activeCount) 件進行中",
            deltaUp: nil,
            palette: palette
        )
    }
    
    /// 漸層 hero 卡：本月淨獲利、sparkline 與月目標進度
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: hero 卡片 view
    @ViewBuilder
    func heroCard(stats: DashboardStats, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                // 層級由字重與字級表達；不透明度降階會直接損害對比
                Text("本月 · 淨獲利")
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                
                Text(profitDisplay(stats.profit))
                    .font(.system(size: heroProfitSize, weight: .bold))
                    .monospacedDigit()
                // 無障礙字級允許換行，保留使用者設定的字級。
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.7)
                
                HStack(spacing: BLSpacing.small) {
                    Text(profitDeltaDisplay(stats.profitDelta))
                        .blTextStyle(.footnote)
                    
                    Text("·")
                    
                    Text("\(stats.orderCount) 單")
                        .blTextStyle(.footnote)
                }
            }
            
            BLSparkline(
                data: stats.sparkline,
                tint: .white,
                height: 36,
                summary: sparklineSummary(stats: stats),
                axisXTitle: language.localized("順序"),
                axisYTitle: language.localized("數值"),
                seriesName: language.localized("走勢圖"),
                pointOrdinalDescription: { ordinal in language.localized("第 \(ordinal) 筆") }
            )
            
            goalProgressBar(stats: stats)
        }
        .padding(BLSpacing.large)
        // 漸層上的文字固定使用白色。
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 使用低亮度漸層確保白字對比度。
        .blHeroCardBackground()
        .blCardShadow()
        // 保留走勢圖與目標進度的個別朗讀內容。
        // 淨獲利放入卡片值。
        .accessibilityElement(children: .contain)
        .accessibilityValue(Text(profitDisplay(stats.profit)))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.kpiTile(.netProfit))
    }
    
    /// 月目標進度條；目標為 0 (使用者未設定) 時整列隱藏
    /// - Parameter stats: 已計算的本月統計
    /// - Returns: 進度條 view
    @ViewBuilder
    func goalProgressBar(stats: DashboardStats) -> some View {
        if stats.goal > 0 {
            let pct = stats.goalProgress
            
            HStack(spacing: BLSpacing.small) {
                // 軌道與文字固定使用白色。
                ProgressView(value: pct)
                    .progressViewStyle(
                        BLProgressBarStyle(tint: .white, track: .white.opacity(0.25)))
                
                Text("\(Int(pct * 100))% / \(BLFormatters.twd(stats.goal, locale: locale))")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }
    
    /// KPI 卡片格
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 區塊 view
    @ViewBuilder
    func kpiGrid(stats: DashboardStats, palette: BLPalette) -> some View {
        LazyVGrid(columns: kpiColumns, spacing: BLSpacing.small) {
            kpiTile(
                kpi: .revenue,
                label: "營業額",
                value: BLFormatters.twd(stats.revenue, locale: locale),
                tint: palette.accent,
                delta: LocalizedStringKey(percentDeltaDisplay(stats.revenueDelta)),
                deltaUp: deltaDirection(stats.revenueDelta),
                palette: palette
            )
            kpiTile(
                kpi: .cost,
                label: "成本",
                value: BLFormatters.twd(stats.cost, locale: locale),
                tint: palette.orange,
                delta: LocalizedStringKey(percentDeltaDisplay(stats.costDelta)),
                deltaUp: deltaDirection(stats.costDelta),
                palette: palette
            )
            kpiTile(
                kpi: .grossMargin,
                label: "毛利率",
                value: BLFormatters.percent(stats.margin, locale: locale),
                tint: palette.green,
                delta: LocalizedStringKey(marginDeltaDisplay(stats.marginDelta)),
                deltaUp: deltaDirection(stats.marginDelta),
                palette: palette
            )
            kpiTile(
                kpi: .activeOrders,
                label: "進行中訂單",
                value: "\(stats.activeCount)",
                tint: palette.purple,
                delta: "\(stats.activeCount) 件進行中",
                deltaUp: nil,
                palette: palette
            )
        }
    }
    
    /// 單一 KPI 卡片：左上 tint 色點 + 標籤、中段大數字、下方變化指標
    /// - Parameters:
    ///   - kpi: 指標的穩定識別值
    ///   - label: 卡片左上方的指標名稱，例如「營業額」、「毛利率」
    ///   - value: 卡片中央顯示的數值字串 (已預先 format)
    ///   - tint: 左上方色點顏色，用來區分指標分類
    ///   - delta: 變化率文字
    ///   - deltaUp: 變化方向；`nil` 表示沒有比較值
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 卡片 view
    @ViewBuilder
    func kpiTile(
        kpi: BLAccessibilityID.Dashboard.KPI,
        label: String,
        value: String,
        tint: Color,
        delta: LocalizedStringKey,
        deltaUp: Bool?,
        palette: BLPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            HStack(spacing: 6) {
                // 純裝飾色點，語意已由標籤文字承載
                Circle().fill(tint).frame(width: 8, height: 8).accessibilityHidden(true)
                Text(LocalizedStringKey(label))
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                    .foregroundStyle(palette.secondaryLabel)
            }
            
            Text(value)
                .blTextStyle(.title3Bold)
                .monospacedDigit()
                .foregroundStyle(palette.label)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.8)
            
            Text(delta)
                .font(BLTypographyStyle.caption.font.weight(.medium))
                .foregroundStyle(deltaColor(deltaUp, palette: palette))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                .stroke(palette.separator, lineWidth: 0.5)
        }
        // 保留合併朗讀，數值由 accessibilityValue 提供。
        // 合併後子元素查不到，測試以卡片 identifier 定位後讀該元素的 value
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(value))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.kpiTile(kpi))
    }
    
    /// 近期訂單區塊 (標題列 + 列表卡)
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 近期訂單區塊 view
    @ViewBuilder
    func recentOrdersSection(stats: DashboardStats, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("近期訂單")
                    .blTextStyle(.title3Bold)
                    .foregroundStyle(palette.label)
                
                Spacer()
                
                Button("查看全部") {
                    store.send(.delegate(.viewAllOrdersTapped))
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.accent)
                .font(BLTypographyStyle.subhead.font.weight(.medium))
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.recentOrdersSeeAllButton)
            }
            
            if stats.recentOrders.isEmpty {
                ContentUnavailableView(
                    "尚無訂單",
                    systemImage: "tray",
                    description: Text("先建立第一筆訂單，這裡會顯示近期紀錄。")
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, BLSpacing.large)
                .background(palette.background)
            } else {
                BLCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(stats.recentOrders.enumerated()), id: \.element.id) {
                            index, order in
                            OrderRowView(order: order)
                                .padding(.horizontal, BLSpacing.large)
                                .padding(.vertical, BLSpacing.extraSmall)
                                .accessibilityIdentifier(
                                    BLAccessibilityID.Dashboard.recentOrderRow(orderID: order.id))
                            
                            if index < stats.recentOrders.count - 1 {
                                Divider()
                                    .padding(.leading, BLListMetrics.dividerInset)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Private Method

private extension DashboardView {
    
    // MARK: Layout
    
    /// KPI 卡片的欄位設定；無障礙字級改為單欄
    var kpiColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: BLSpacing.small), count: count)
    }
    
    /// 是否採用 hero + 3 KPI 並排版面 (iPad)
    var useWideHero: Bool {
        return horizontalSizeClass != .compact
    }
    
    // MARK: Accessibility
    
    /// hero 走勢圖的趨勢摘要
    /// - Parameter stats: 已計算的本月統計
    /// - Returns: 供輔助技術朗讀的摘要
    func sparklineSummary(stats: DashboardStats) -> LocalizedStringKey {
        let points = stats.sparkline
        guard points.count > 1,
              let first = points.first,
              let last = points.last,
              let lowest = points.min(),
              let highest = points.max()
        else {
            return "月獲利走勢圖，目前沒有資料"
        }
        
        // 三個方向各自成句、不拼接片語——拼接的句子無法在其他語言正確重組
        let low = BLFormatters.twd(Decimal(lowest), locale: locale)
        let high = BLFormatters.twd(Decimal(highest), locale: locale)
        if last > first {
            return "月獲利走勢圖，共 \(points.count) 個月，整體上升，最低 \(low)，最高 \(high)"
        }
        if last < first {
            return "月獲利走勢圖，共 \(points.count) 個月，整體下降，最低 \(low)，最高 \(high)"
        }
        return "月獲利走勢圖，共 \(points.count) 個月，整體持平，最低 \(low)，最高 \(high)"
    }
    
    // MARK: Formatting
    
    /// 將獲利金額格式化為含正負號的新台幣字串
    /// - Parameter profit: 獲利金額
    /// - Returns: 顯示在 hero 卡上的金額字串
    func profitDisplay(_ profit: Decimal) -> String {
        let formatted = BLFormatters.twd(profit, locale: locale)
        
        return profit > 0 ? "+\(formatted)" : formatted
    }
    
    /// 顯示在大標題上方、依 App 選定 locale 格式化的日期子標
    /// - Returns: 依選定 locale 呈現的日期字串
    func currentDateSubtitle() -> String {
        date().formatted(
            .dateTime
                .month(.wide)
                .day(.defaultDigits)
                .weekday(.wide)
                .locale(locale)
        )
    }
    
    /// 將 KPI delta 的方向轉成色彩
    /// - Parameters:
    ///   - up: `nil` 視為中性
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 對應的 delta 文字色
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
    
    /// 將 MoM 變化率格式化；nil 顯示「— MoM」
    /// - Parameter delta: 成長率，例如 `0.182` 表示 +18.2%
    /// - Returns: KPI 卡顯示用字串
    func percentDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let formatted = BLFormatters.percent(delta, locale: locale)
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) MoM"
    }
    
    /// 依 App 選定 locale 把毛利率 delta (百分點) 轉成 `+2.4 pt MoM` 風格字串
    /// - Parameter delta: 百分點差，例如 `0.024` 表示 +2.4pt
    /// - Returns: KPI 卡顯示用字串
    func marginDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let pts = delta * 100
        let formatted = pts.formatted(.number.precision(.fractionLength(1)).locale(locale))
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) pt MoM"
    }
    
    /// 依 App 選定 locale 把獲利 delta 轉成 hero 卡上的 `↑ 24.3% MoM` 風格字串
    /// - Parameter delta: 成長率，例如 `0.243` 表示 +24.3%
    /// - Returns: hero 卡顯示用字串；無資料時顯示「— MoM」
    func profitDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let arrow = delta >= 0 ? "↑" : "↓"
        let absDelta = delta < 0 ? -delta : delta
        let formatted = BLFormatters.percent(absDelta, locale: locale)
        return "\(arrow) \(formatted) MoM"
    }
    
    /// 將 delta 數值轉成 KPI tile 用的方向旗標 (`true`/`false`/`nil`)
    /// - Parameter delta: 成長率或百分點差
    /// - Returns: `true` 代表上升、`false` 代表下降、`nil` 代表無上月資料可比
    func deltaDirection(_ delta: Decimal?) -> Bool? {
        guard let delta else {
            return nil
        }
        return delta >= 0
    }
}

// MARK: - Preview

#Preview("總覽") {
    let previewState: DashboardFeature.State = {
        var state = DashboardFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.loadState = .loaded
        return state
    }()
    
    return DashboardView(
        store: Store(initialState: previewState) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}
