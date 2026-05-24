//
//  DashboardView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 總覽分頁的主要畫面。
///
/// 對應設計稿 iPhone / iPad / Mac 的「總覽」頁：
/// - 大標題 + 日期或月份子標
/// - 漸層 hero 卡 (本月淨獲利 + sparkline + 月目標進度)
/// - KPI 卡片格 (營業額、成本、毛利率、進行中訂單)
/// - 近期訂單卡 (reuse ``OrderRowView``)
struct DashboardView: View {
    
    // MARK: - View Properties
    
    /// App 根層級 store；用來讀取訂單以及切換分頁。
    @Bindable var store: StoreOf<RootFeature>
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

#if !os(macOS)
    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone (compact) 與 iPad (regular)。
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    /// 用來計算「本月／上月」與日期子標的「現在」時間；測試可注入固定值。
    @Dependency(\.date) private var date

    // MARK: - View Body
    
    /// 總覽頁的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        let core = Group {
            if !store.orders.hasLoaded {
                loadingPlaceholder(palette: palette)
            } else {
                ScrollView {
                    content(palette: palette)
                        .padding(.horizontal, BLSpacing.large)
                        .padding(.vertical, BLSpacing.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .task {
            // 確保使用者一進來總覽頁時，背後的訂單資料就先載入；
            // OrdersFeature.task 已內建空清單守衛，重複呼叫不會重新載入。
            await store.send(.orders(.task)).finish()
            // 同時把月度目標等設定載入，避免使用者直接從 Dashboard 啟動時看不到自訂目標。
            await store.send(.settings(.task)).finish()
        }

        // iOS (iPhone + iPad) 以 NavigationStack + navigationTitle 提供系統大標題，讓頂端與「更多」等分頁一致對齊；
        // macOS 維持自繪標題 (見 titleHeader)，與 OrdersMacView 等其他 macOS 畫面一致。
#if os(macOS)
        return core
#else
        return NavigationStack {
            core
                .navigationTitle("總覽")
        }
#endif
    }
}

// MARK: - ViewBuilder

private extension DashboardView {
    
    /// 訂單載入完成後依資料狀態決定顯示完整 dashboard 或第一次使用的 onboarding。
    ///
    /// 首次載入完成前的佔位畫面由 ``loadingPlaceholder(palette:)`` 在 ``body`` 中直接渲染，避免訂單為空時每次切換 tab 因 `isLoading` 暫時翻成 `true` 而落入「有資料」分支造成閃爍。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 內容 view。
    @ViewBuilder
    func content(palette: BLPalette) -> some View {
        if store.orders.orders.isEmpty {
            onboardingHero(palette: palette)
        } else {
            let stats = computeStats(
                orders: store.orders.orders,
                monthlyGoal: store.settings.monthlyProfitGoalTwd
            )

            VStack(alignment: .leading, spacing: BLSpacing.large) {
                titleHeader(palette: palette)
                heroAndKpiRow(stats: stats, palette: palette)
                recentOrdersSection(stats: stats, palette: palette)
            }
        }
    }

    /// 首次載入訂單前顯示的中性佔位畫面，水平垂直置中。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 佔位 view。
    func loadingPlaceholder(palette: BLPalette) -> some View {
        ProgressView()
            .controlSize(.regular)
            .tint(palette.secondaryLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 第一次開 App 還沒有任何訂單時的引導畫面。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: onboarding view。
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
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: BLSpacing.small) {
                Text("歡迎使用 BuyLedger")
                    .font(.title.bold())
                    .foregroundStyle(palette.label)
                
                Text("還沒有任何訂單。建立第一筆，馬上開始追蹤代購損益。")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, BLSpacing.large)
            
            Button {
                store.send(.startNewOrder)
            } label: {
                Label("建立第一筆訂單", systemImage: "plus")
            }
            .buttonStyle(BLButtonStyle(variant: .primary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BLSpacing.section * 2)
    }
    
    /// 大標題與日期子標。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 標題列 view。
    func titleHeader(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(currentDateSubtitle())
                .font(.footnote.weight(.medium))
                .foregroundStyle(palette.secondaryLabel)

            // iOS 改由 `.navigationTitle("總覽")` 提供標題；此處僅 macOS 仍自繪大標題。
#if os(macOS)
            Text("總覽")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)
#endif
        }
    }
    
    /// hero P&L 與 KPI 的並排組合。
    ///
    /// 在 iPhone (compact) 上維持 hero 在上、2×2 KPI grid 在下；在 iPad/Mac 上把 hero 放在左側 1.4 權重，3 個小 KPI 放在右側
    /// 1 權重的直欄裡，對應設計稿 iPad Dashboard 的 1.4fr + 3fr 版面。
    /// - Parameters:
    ///   - stats: 已計算的本月統計。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: hero + KPI 組合 view。
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
    
    /// 寬版面右側的 3 個 KPI 卡片 (直欄排列，與 hero 等高呼應)。
    /// - Parameters:
    ///   - stats: 已計算的本月統計。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 3 個 KPI 卡片。
    @ViewBuilder
    func wideKpiTiles(stats: DashboardStats, palette: BLPalette) -> some View {
        kpiTile(
            label: "營業額",
            value: formatTwd(stats.revenue),
            tint: palette.accent,
            delta: percentDeltaDisplay(stats.revenueDelta),
            deltaUp: deltaDirection(stats.revenueDelta),
            palette: palette
        )
        kpiTile(
            label: "毛利率",
            value: formatPercent(stats.margin),
            tint: palette.green,
            delta: marginDeltaDisplay(stats.marginDelta),
            deltaUp: deltaDirection(stats.marginDelta),
            palette: palette
        )
        kpiTile(
            label: "進行中訂單",
            value: "\(stats.activeCount)",
            tint: palette.purple,
            delta: "\(stats.activeCount) 件進行中",
            deltaUp: nil,
            palette: palette
        )
    }
    
    /// 漸層 hero 卡：本月淨獲利、sparkline 與月目標進度。
    /// - Parameters:
    ///   - stats: 已計算的本月統計。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: hero 卡片 view。
    func heroCard(stats: DashboardStats, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                Text("本月 · 淨獲利")
                    .font(.footnote.weight(.medium))
                    .opacity(0.85)
                
                Text(profitDisplay(stats.profit))
                    .font(.system(size: 36, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                HStack(spacing: BLSpacing.small) {
                    Text(profitDeltaDisplay(stats.profitDelta))
                        .font(.footnote)
                        .opacity(0.9)

                    Text("·").opacity(0.5)

                    Text("\(stats.orderCount) 單")
                        .font(.footnote)
                        .opacity(0.9)
                }
            }
            
            BLSparkline(data: stats.sparkline, tint: .white, height: 36)
                .opacity(0.6)
            
            goalProgressBar(stats: stats)
        }
        .padding(BLSpacing.large)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [palette.accent, palette.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .blCardShadow()
    }
    
    /// 月目標進度條；目標為 0 (使用者未設定) 時整列隱藏。
    /// - Parameter stats: 已計算的本月統計。
    /// - Returns: 進度條 view。
    @ViewBuilder
    func goalProgressBar(stats: DashboardStats) -> some View {
        if stats.goal > 0 {
            let pct = stats.goalProgress

            HStack(spacing: BLSpacing.small) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, geo.size.width * pct))
                    }
                }
                .frame(height: 6)

                Text("\(Int(pct * 100))% / \(formatTwd(stats.goal))")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }
    
    /// KPI 卡片格。
    /// - Parameters:
    ///   - stats: 已計算的本月統計。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: KPI 區塊 view。
    func kpiGrid(stats: DashboardStats, palette: BLPalette) -> some View {
        LazyVGrid(columns: kpiColumns, spacing: BLSpacing.small) {
            kpiTile(
                label: "營業額",
                value: formatTwd(stats.revenue),
                tint: palette.accent,
                delta: percentDeltaDisplay(stats.revenueDelta),
                deltaUp: deltaDirection(stats.revenueDelta),
                palette: palette
            )
            kpiTile(
                label: "成本",
                value: formatTwd(stats.cost),
                tint: palette.orange,
                delta: percentDeltaDisplay(stats.costDelta),
                deltaUp: deltaDirection(stats.costDelta),
                palette: palette
            )
            kpiTile(
                label: "毛利率",
                value: formatPercent(stats.margin),
                tint: palette.green,
                delta: marginDeltaDisplay(stats.marginDelta),
                deltaUp: deltaDirection(stats.marginDelta),
                palette: palette
            )
            kpiTile(
                label: "進行中訂單",
                value: "\(stats.activeCount)",
                tint: palette.purple,
                delta: "\(stats.activeCount) 件進行中",
                deltaUp: nil,
                palette: palette
            )
        }
    }
    
    /// 單一 KPI 卡片：左上 tint 色點 + 標籤、中段大數字、下方變化指標。
    /// - Parameters:
    ///   - label: 卡片左上方的指標名稱，例如「營業額」、「毛利率」。
    ///   - value: 卡片中央顯示的數值字串 (已預先 format)。
    ///   - tint: 左上方色點顏色，用來區分指標分類。
    ///   - delta: 下方變化字串，例如「+18.2%」、「3 open」。
    ///   - deltaUp: 變化方向：`true` 顯示上升色 (綠)、`false` 顯示下降色 (紅)、`nil` 顯示中性色。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: KPI 卡片 view。
    func kpiTile(
        label: String,
        value: String,
        tint: Color,
        delta: String,
        deltaUp: Bool?,
        palette: BLPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 8, height: 8)
                Text(label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(palette.secondaryLabel)
            }
            
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(palette.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(delta)
                .font(.caption.weight(.medium))
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
    }
    
    /// 近期訂單區塊 (標題列 + 列表卡)。
    /// - Parameters:
    ///   - stats: 已計算的本月統計。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 近期訂單區塊 view。
    func recentOrdersSection(stats: DashboardStats, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("近期訂單")
                    .font(.title3.bold())
                    .foregroundStyle(palette.label)
                
                Spacer()
                
                Button("查看全部") {
                    store.send(.tabSelected(.orders))
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.accent)
                .font(.subheadline.weight(.medium))
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
                        ForEach(Array(stats.recentOrders.enumerated()), id: \.element.id) { index, order in
                            OrderRowView(order: order)
                                .padding(.horizontal, BLSpacing.large)
                                .padding(.vertical, BLSpacing.small)
                            
                            if index < stats.recentOrders.count - 1 {
                                Divider()
                                    .padding(.leading, BLSpacing.large + 40 + BLSpacing.medium)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Layout Helper

private extension DashboardView {
    
    /// KPI 卡片的欄位設定 (僅 compact 用 2 欄)。
    var kpiColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: BLSpacing.small), count: 2)
    }
    
    /// 是否採用 hero + 3 KPI 並排版面 (iPad / Mac)。
    var useWideHero: Bool {
#if os(macOS)
        return true
#else
        return horizontalSizeClass != .compact
#endif
    }
}

// MARK: - Statistics Computation

/// 總覽頁使用的本月與走勢統計。
///
/// MoM (month-over-month) 相關欄位在「上月無資料」時為 `nil`，UI 應顯示「—」並停用方向色。
private struct DashboardStats {

    // MARK: - Data Properties

    /// 本月已實現的營業額。
    let revenue: Decimal

    /// 本月成本。
    let cost: Decimal

    /// 本月淨獲利。
    let profit: Decimal

    /// 毛利率 (profit / revenue)。
    let margin: Decimal

    /// 進行中 (confirmed / purchased / shipping) 的訂單數。
    let activeCount: Int

    /// 本月已實現的訂單筆數。
    let orderCount: Int

    /// 月目標金額 (來自 `SettingsFeature.State.monthlyProfitGoalTwd`)。`0` 代表使用者未設定，UI 應隱藏進度條。
    let goal: Decimal

    /// 已達月目標的比例 (0 ~ 1)。
    let goalProgress: CGFloat

    /// 近 12 個月的淨獲利走勢值。
    let sparkline: [Double]

    /// 近期訂單 (依日期由新到舊取前 4 筆)。
    let recentOrders: [LedgerOrder]

    /// 營業額相對上月的成長率 (小數形式，0.18 即 +18%)；上月為 0 或無資料時為 `nil`。
    let revenueDelta: Decimal?

    /// 成本相對上月的成長率 (小數形式)；上月為 0 或無資料時為 `nil`。
    let costDelta: Decimal?

    /// 淨獲利相對上月的成長率 (小數形式)；上月為 0 或無資料時為 `nil`。
    let profitDelta: Decimal?

    /// 毛利率相對上月的差 (百分點，0.024 即 +2.4pt)；上月無資料時為 `nil`。
    let marginDelta: Decimal?
}

private extension DashboardView {
    
    /// 視為「進行中」的訂單狀態集合。
    static let activeStatuses: Set<OrderStatus> = [
        .confirmed,
        .purchased,
        .shipping
    ]

    /// 視為「已實現」的訂單狀態集合 (用於本月損益)。
    static let realizedStatuses: Set<OrderStatus> = [
        .confirmed,
        .purchased,
        .shipping,
        .delivered
    ]

    /// 「近期訂單」列表顯示的筆數；同時控制 ``computeStats(orders:monthlyGoal:)`` 的 prefix 取數。
    static let recentOrdersCount = 4
    
    /// 計算 ``DashboardStats``。
    /// - Parameters:
    ///   - orders: 目前的訂單清單。
    ///   - monthlyGoal: 月度淨獲利目標 (來自 SettingsFeature；`0` 代表未設定)。
    /// - Returns: 總覽頁需要的統計值。
    func computeStats(orders: [LedgerOrder], monthlyGoal: Decimal) -> DashboardStats {
        let calendar = Calendar.current
        let now = date()

        let current = monthlyTotals(orders: orders, calendar: calendar, referenceDate: now)
        let previous: MonthlyTotals = {
            guard let priorMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
                return .empty
            }
            return monthlyTotals(
                orders: orders,
                calendar: calendar,
                referenceDate: priorMonth
            )
        }()

        let activeCount = orders.lazy.filter {
            Self.activeStatuses.contains($0.status)
        }.count

        let pct: CGFloat
        if monthlyGoal == 0 {
            pct = 0
        } else {
            let raw = NSDecimalNumber(decimal: current.profit / monthlyGoal).doubleValue
            pct = CGFloat(min(1.0, max(0.0, raw)))
        }

        let recent = orders.sorted { $0.date > $1.date }.prefix(Self.recentOrdersCount)

        return DashboardStats(
            revenue: current.revenue,
            cost: current.cost,
            profit: current.profit,
            margin: current.margin,
            activeCount: activeCount,
            orderCount: current.orderCount,
            goal: monthlyGoal,
            goalProgress: pct,
            sparkline: monthlyProfitSparkline(
                orders: orders,
                calendar: calendar,
                now: now
            ),
            recentOrders: Array(recent),
            revenueDelta: ratio(current: current.revenue, previous: previous.revenue),
            costDelta: ratio(current: current.cost, previous: previous.cost),
            profitDelta: ratio(current: current.profit, previous: previous.profit),
            marginDelta: previous.orderCount == 0 ? nil : current.margin - previous.margin
        )
    }

    /// 任意月份的彙總值，用來複用「本月」與「上月」的計算。
    struct MonthlyTotals {

        // MARK: - Data Properties

        /// 該月已實現訂單的營業額總和。
        let revenue: Decimal

        /// 該月已實現訂單的成本總和 (含商品、運費與手續費)。
        let cost: Decimal

        /// 該月已實現訂單的淨獲利總和 (`revenue - cost`)。
        let profit: Decimal

        /// 該月毛利率 (`profit / revenue`)；`revenue` 為 0 時為 0。
        let margin: Decimal

        /// 該月已實現的訂單筆數，作為「上月有無資料可比」的判斷依據。
        let orderCount: Int

        // MARK: - Static Properties

        /// 整月無資料時使用的零值彙總，避免呼叫端各自處理 nil。
        static let empty = MonthlyTotals(
            revenue: 0,
            cost: 0,
            profit: 0,
            margin: 0,
            orderCount: 0
        )
    }

    /// 計算指定月份的營收／成本／獲利／毛利率／訂單筆數。
    /// - Parameters:
    ///   - orders: 全部訂單清單。
    ///   - calendar: 用來算月份區間的曆法。
    ///   - referenceDate: 基準日期，會以此日的所在月份為查詢範圍。
    /// - Returns: 月度彙總值；找不到月份區間時回傳 `.empty`。
    func monthlyTotals(orders: [LedgerOrder], calendar: Calendar, referenceDate: Date) -> MonthlyTotals {
        guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else {
            return .empty
        }

        let monthOrders = orders.filter { order in
            Self.realizedStatuses.contains(order.status)
                && (interval.start..<interval.end).contains(order.date)
        }

        var revenue: Decimal = 0
        var cost: Decimal = 0
        var profit: Decimal = 0
        for order in monthOrders {
            let summary = order.summary
            revenue += summary.revenue
            cost += summary.totalCost
            profit += summary.profit
        }
        let margin: Decimal = revenue == 0 ? 0 : profit / revenue

        return MonthlyTotals(
            revenue: revenue,
            cost: cost,
            profit: profit,
            margin: margin,
            orderCount: monthOrders.count
        )
    }

    /// 計算 `(current - previous) / previous` 的成長率；`previous == 0` 時回 `nil` 表「無基準可比」。
    /// - Parameters:
    ///   - current: 本期值。
    ///   - previous: 上期值。
    /// - Returns: 成長率 (小數)，上期為 0 時 `nil`。
    func ratio(current: Decimal, previous: Decimal) -> Decimal? {
        guard previous != 0 else { return nil }
        return (current - previous) / previous
    }
    
    /// 產生最近 12 個月的淨獲利走勢資料。
    /// - Parameters:
    ///   - orders: 目前訂單清單。
    ///   - calendar: 用來計算月份的曆法。
    ///   - now: 基準日期 (即「最後一個月」的所在日期)。
    /// - Returns: 共 12 個 `Double` 的走勢值。
    func monthlyProfitSparkline(
        orders: [LedgerOrder],
        calendar: Calendar,
        now: Date
    ) -> [Double] {
        let realized = orders.filter {
            Self.realizedStatuses.contains($0.status)
        }
        
        return (0..<12).reversed().map { offset in
            guard let monthStart = calendar.date(
                byAdding: .month,
                value: -offset,
                to: now
            ),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else {
                return 0
            }
            
            let total = realized
                .filter {
                    (interval.start..<interval.end).contains($0.date) }
                .reduce(Decimal.zero) { $0 + $1.summary.profit }
            
            return NSDecimalNumber(decimal: total).doubleValue
        }
    }
}

// MARK: - Formatting

private extension DashboardView {
    
    /// 將獲利金額格式化為含正負號的新台幣字串。
    /// - Parameter profit: 獲利金額。
    /// - Returns: 顯示在 hero 卡上的金額字串。
    func profitDisplay(_ profit: Decimal) -> String {
        let formatted = formatTwd(profit)
        
        return profit > 0 ? "+\(formatted)" : formatted
    }
    
    /// 將金額格式化為新台幣 (無小數位)。
    /// - Parameter amount: 金額。
    /// - Returns: 含 NT$ 前綴的字串。
    func formatTwd(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(Locale(identifier: "zh_TW"))
        )
    }
    
    /// 將比例格式化為百分比。
    /// - Parameter value: 介於 0 與 1 之間的比例。
    /// - Returns: 含一位小數的百分比字串。
    func formatPercent(_ value: Decimal) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }
    
    /// 顯示在大標題上方的日期子標。
    /// - Returns: 例如「5月1日 週五」。
    func currentDateSubtitle() -> String {
        date().formatted(
            .dateTime
                .month(.wide)
                .day(.defaultDigits)
                .weekday(.wide)
                .locale(Locale(identifier: "zh_TW"))
        )
    }
    
    /// 將 KPI delta 的方向轉成色彩。
    ///
    /// 一律以「上升 → 綠、下降 → 紅、未知 → 中性」表示**原始方向**；針對成本這類「漲是壞」的指標，UI 不主動翻轉色彩，由 label 與內容由使用者自行判讀。
    /// - Parameters:
    ///   - up: `nil` 視為中性。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 對應的 delta 文字色。
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

    /// 把 MoM delta (小數型成長率) 轉成 `+18.2% MoM` 風格字串；`nil` 顯示「— MoM」。
    /// - Parameter delta: 成長率，例如 `0.182` 表示 +18.2%。
    /// - Returns: KPI 卡顯示用字串。
    func percentDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else { return "— MoM" }
        let formatted = delta.formatted(.percent.precision(.fractionLength(1)))
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) MoM"
    }

    /// 把毛利率 delta (百分點) 轉成 `+2.4 pt MoM` 風格字串。
    /// - Parameter delta: 百分點差，例如 `0.024` 表示 +2.4pt。
    /// - Returns: KPI 卡顯示用字串。
    func marginDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else { return "— MoM" }
        let pts = delta * 100
        let formatted = pts.formatted(.number.precision(.fractionLength(1)))
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) pt MoM"
    }

    /// 把獲利 delta 轉成 hero 卡上的 `↑ 24.3% MoM` 風格字串。
    /// - Parameter delta: 成長率，例如 `0.243` 表示 +24.3%。
    /// - Returns: hero 卡顯示用字串；無資料時顯示「— MoM」。
    func profitDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else { return "— MoM" }
        let arrow = delta >= 0 ? "↑" : "↓"
        let absDelta = delta < 0 ? -delta : delta
        let formatted = absDelta.formatted(.percent.precision(.fractionLength(1)))
        return "\(arrow) \(formatted) MoM"
    }

    /// 將 delta 數值轉成 KPI tile 用的方向旗標 (`true`/`false`/`nil`)。
    /// - Parameter delta: 成長率或百分點差。
    /// - Returns: `true` 代表上升、`false` 代表下降、`nil` 代表無上月資料可比。
    func deltaDirection(_ delta: Decimal?) -> Bool? {
        guard let delta else { return nil }
        return delta >= 0
    }
}

// MARK: - Preview

#Preview("總覽") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.hasLoaded = true
        return state
    }()
    
    return DashboardView(
        store: Store(initialState: previewState) {
            RootFeature()
        }
    )
}
