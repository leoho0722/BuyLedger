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
/// - 漸層 hero 卡（本月淨獲利 + sparkline + 月目標進度）
/// - KPI 卡片格（營業額、成本、毛利率、進行中訂單）
/// - 近期訂單卡（reuse ``OrderRowView``）
struct DashboardView: View {

    // MARK: - View Properties

    /// App 根層級 store；用來讀取訂單以及切換分頁。
    @Bindable var store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

#if !os(macOS)
    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone（compact）與 iPad（regular）。
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    /// 月目標基準（新台幣）。
    private let monthlyGoal: Decimal = 80_000

    // MARK: - View Body

    /// 總覽頁的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        ScrollView {
            content(palette: palette)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.background)
        .task {
            // 確保使用者一進來總覽頁時，背後的訂單資料就先載入；
            // OrdersFeature.task 已內建空清單守衛，重複呼叫不會重新載入。
            await store.send(.orders(.task)).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension DashboardView {

    /// 依目前資料狀態決定顯示完整 dashboard 或第一次使用的 onboarding。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 內容 view。
    @ViewBuilder
    func content(palette: BLPalette) -> some View {
        if !store.orders.isLoading && store.orders.orders.isEmpty {
            onboardingHero(palette: palette)
        } else {
            let stats = computeStats(orders: store.orders.orders)

            VStack(alignment: .leading, spacing: BLSpacing.large) {
                titleHeader(palette: palette)
                heroAndKpiRow(stats: stats, palette: palette)
                recentOrdersSection(stats: stats, palette: palette)
            }
        }
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
                    .font(.headline)
                    .padding(.horizontal, BLSpacing.medium)
                    .padding(.vertical, BLSpacing.extraSmall)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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

            Text("總覽")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// hero P&L 與 KPI 的並排組合。
    ///
    /// 在 iPhone（compact）上維持 hero 在上、2×2 KPI grid 在下；在 iPad/Mac 上把 hero 放在左側 1.4 權重，3 個小 KPI 放在右側
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

    /// 寬版面右側的 3 個 KPI 卡片（直欄排列，與 hero 等高呼應）。
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
            delta: "+18.2%",
            deltaUp: true,
            palette: palette
        )
        kpiTile(
            label: "毛利率",
            value: formatPercent(stats.margin),
            tint: palette.green,
            delta: "+2.4 pt",
            deltaUp: true,
            palette: palette
        )
        kpiTile(
            label: "進行中訂單",
            value: "\(stats.activeCount)",
            tint: palette.purple,
            delta: "\(stats.activeCount) open",
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
                    Text(stats.profit >= 0 ? "↑ 24.3% MoM" : "↓ 24.3% MoM")
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

    /// 月目標進度條。
    /// - Parameter stats: 已計算的本月統計。
    /// - Returns: 進度條 view。
    func goalProgressBar(stats: DashboardStats) -> some View {
        let pct = stats.goalProgress

        return HStack(spacing: BLSpacing.small) {
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
                delta: "+18.2%",
                deltaUp: true,
                palette: palette
            )
            kpiTile(
                label: "成本",
                value: formatTwd(stats.cost),
                tint: palette.orange,
                delta: "+12.1%",
                deltaUp: false,
                palette: palette
            )
            kpiTile(
                label: "毛利率",
                value: formatPercent(stats.margin),
                tint: palette.green,
                delta: "+2.4 pt",
                deltaUp: true,
                palette: palette
            )
            kpiTile(
                label: "進行中訂單",
                value: "\(stats.activeCount)",
                tint: palette.purple,
                delta: "\(stats.activeCount) open",
                deltaUp: nil,
                palette: palette
            )
        }
    }

    /// 單一 KPI 卡片。
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

    /// 近期訂單區塊（標題列 + 列表卡）。
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
                                Divider().padding(.leading, BLSpacing.large + 40 + BLSpacing.medium)
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

    /// KPI 卡片的欄位設定（僅 compact 用 2 欄）。
    var kpiColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: BLSpacing.small), count: 2)
    }

    /// 是否採用 hero + 3 KPI 並排版面（iPad / Mac）。
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
private struct DashboardStats {

    // MARK: - Data Properties

    /// 本月已實現的營業額。
    let revenue: Decimal

    /// 本月成本。
    let cost: Decimal

    /// 本月淨獲利。
    let profit: Decimal

    /// 毛利率（profit / revenue）。
    let margin: Decimal

    /// 進行中（confirmed / purchased / shipping）的訂單數。
    let activeCount: Int

    /// 本月已實現的訂單筆數。
    let orderCount: Int

    /// 月目標金額。
    let goal: Decimal

    /// 已達月目標的比例（0 ~ 1）。
    let goalProgress: CGFloat

    /// 近 12 個月的淨獲利走勢值。
    let sparkline: [Double]

    /// 近期訂單（依日期由新到舊取前 4 筆）。
    let recentOrders: [LedgerOrder]
}

private extension DashboardView {

    /// 視為「進行中」的訂單狀態集合。
    static let activeStatuses: Set<OrderStatus> = [.confirmed, .purchased, .shipping]

    /// 視為「已實現」的訂單狀態集合（用於本月損益）。
    static let realizedStatuses: Set<OrderStatus> = [.confirmed, .purchased, .shipping, .delivered]

    /// 計算 ``DashboardStats``。
    /// - Parameter orders: 目前的訂單清單。
    /// - Returns: 總覽頁需要的統計值。
    func computeStats(orders: [LedgerOrder]) -> DashboardStats {
        let calendar = Calendar.current
        let now = Date()
        let monthInterval = calendar.dateInterval(of: .month, for: now)

        let monthOrders: [LedgerOrder] = {
            guard let monthInterval else { return [] }

            return orders.filter { order in
                Self.realizedStatuses.contains(order.status)
                    && (monthInterval.start..<monthInterval.end).contains(order.date)
            }
        }()

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
        let activeCount = orders.lazy.filter { Self.activeStatuses.contains($0.status) }.count
        let goal: Decimal = monthlyGoal
        let pct: CGFloat
        if goal == 0 {
            pct = 0
        } else {
            let raw = NSDecimalNumber(decimal: profit / goal).doubleValue
            pct = CGFloat(min(1.0, max(0.0, raw)))
        }

        let recent = orders.sorted { $0.date > $1.date }.prefix(4)

        return DashboardStats(
            revenue: revenue,
            cost: cost,
            profit: profit,
            margin: margin,
            activeCount: activeCount,
            orderCount: monthOrders.count,
            goal: goal,
            goalProgress: pct,
            sparkline: monthlyProfitSparkline(orders: orders, calendar: calendar, now: now),
            recentOrders: Array(recent)
        )
    }

    /// 產生最近 12 個月的淨獲利走勢資料。
    /// - Parameters:
    ///   - orders: 目前訂單清單。
    ///   - calendar: 用來計算月份的曆法。
    ///   - now: 基準日期（即「最後一個月」的所在日期）。
    /// - Returns: 共 12 個 `Double` 的走勢值。
    func monthlyProfitSparkline(orders: [LedgerOrder], calendar: Calendar, now: Date) -> [Double] {
        let realized = orders.filter { Self.realizedStatuses.contains($0.status) }

        return (0..<12).reversed().map { offset in
            guard
                let monthStart = calendar.date(byAdding: .month, value: -offset, to: now),
                let interval = calendar.dateInterval(of: .month, for: monthStart)
            else {
                return 0
            }

            let total = realized
                .filter { (interval.start..<interval.end).contains($0.date) }
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

    /// 將金額格式化為新台幣（無小數位）。
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
        Date().formatted(
            .dateTime
                .month(.wide)
                .day(.defaultDigits)
                .weekday(.wide)
                .locale(Locale(identifier: "zh_TW"))
        )
    }

    /// 將 KPI delta 的方向轉成色彩。
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
}

// MARK: - Preview

#Preview("總覽") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        return state
    }()

    return DashboardView(
        store: Store(initialState: previewState) {
            RootFeature()
        }
    )
}
