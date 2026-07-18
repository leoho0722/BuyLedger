//
//  DashboardView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 總覽分頁的主要畫面
///
/// 對應設計稿 iPhone / iPad 的「總覽」頁：
/// - 大標題 + 日期或月份子標
/// - 漸層 hero 卡 (本月淨獲利 + sparkline + 月目標進度)
/// - KPI 卡片格 (營業額、成本、毛利率、進行中訂單)
/// - 近期訂單卡 (reuse ``OrderRowView``)
struct DashboardView: View {

    // MARK: - View Properties

    /// App 根層級 store；用來讀取訂單以及切換分頁
    @Bindable var store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone (compact) 與 iPad (regular)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 用來計算「本月／上月」與日期子標的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 月份分組與相對日期計算所用的行事曆 (含時區)；測試可注入固定 gregorian／UTC
    @Dependency(\.calendar) private var calendar

    /// hero 淨獲利金額字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroProfitSize: CGFloat = 36

    // MARK: - View Body

    /// 總覽頁的畫面內容
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
            // OrdersFeature.task 已內建空清單守衛，重複呼叫不會重新載入
            await store.send(.orders(.task)).finish()
            // 同時把月度目標等設定載入，避免使用者直接從 Dashboard 啟動時看不到自訂目標
            await store.send(.settings(.task)).finish()
        }
        return NavigationStack {
            core
                .rootNavigationTitle("總覽", language: store.settings.language)
        }
    }
}

// MARK: - ViewBuilder

private extension DashboardView {

    /// 訂單載入完成後依資料狀態決定顯示完整 dashboard 或第一次使用的 onboarding
    ///
    /// 首次載入完成前的佔位畫面由 ``loadingPlaceholder(palette:)`` 在 ``body`` 中直接渲染
    ///
    /// 避免訂單為空時每次切換 tab 因 `isLoading` 暫時翻成 `true` 而落入「有資料」分支造成閃爍
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 內容 view
    @ViewBuilder
    func content(palette: BLPalette) -> some View {
        if store.orders.orders.isEmpty {
            onboardingHero(palette: palette)
        } else {
            let stats = DashboardStats(
                orders: store.orders.orders,
                monthlyGoal: store.settings.monthlyProfitGoalTwd,
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

    /// 「進行中的開團」卡：列出 ``CampaignStatus/ongoing`` 的開團與其進度；沒有進行中的開團時整卡隱藏
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 進行中的開團卡 view (無進行中團時為 `EmptyView`)
    @ViewBuilder
    func ongoingCampaignsSection(palette: BLPalette) -> some View {
        // 一次 render 只為每個進行中開團投影一次彙總，避免每列於 body 重算 O(團 × 訂單)
        let orders = store.orders.orders
        let rows = store.campaigns.campaigns
            .filter { $0.status == .ongoing }
            .map { (campaign: $0, summary: CampaignSummary(campaignName: $0.name, orders: orders)) }

        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("進行中的開團")
                    .font(.headline)
                    .foregroundStyle(palette.label)

                BLCard {
                    VStack(spacing: BLSpacing.medium) {
                        ForEach(Array(rows.enumerated()), id: \.element.campaign.id) { index, entry in
                            Button {
                                store.send(.campaignSelected(entry.campaign.name))
                            } label: {
                                ongoingCampaignRow(campaign: entry.campaign, summary: entry.summary, palette: palette)
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
    func ongoingCampaignRow(campaign: Campaign, summary: CampaignSummary, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            HStack(spacing: BLSpacing.small) {
                Text(campaign.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(summary.orderCount) 筆 · \(CampaignFormatters.twd(summary.receivables, locale: locale))")
                    .font(.caption)
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

    /// 首次載入訂單前顯示的中性佔位畫面，水平垂直置中
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 佔位 view
    @ViewBuilder
    func loadingPlaceholder(palette: BLPalette) -> some View {
        ProgressView()
            .controlSize(.regular)
            .tint(palette.secondaryLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// 日期子標
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 標題列 view
    @ViewBuilder
    func titleHeader(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(currentDateSubtitle())
                .font(.footnote.weight(.medium))
                .foregroundStyle(palette.secondaryLabel)
        }
    }

    /// hero P&L 與 KPI 的並排組合
    ///
    /// 在 iPhone (compact) 上維持 hero 在上、2×2 KPI grid 在下；
    /// 在 iPad 上把 hero 放在左側 1.4 權重、3 個小 KPI 放在右側 1 權重的直欄裡，對應設計稿 iPad Dashboard 的 1.4fr + 3fr 版面
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

    /// 漸層 hero 卡：本月淨獲利、sparkline 與月目標進度
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: hero 卡片 view
    @ViewBuilder
    func heroCard(stats: DashboardStats, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                Text("本月 · 淨獲利")
                    .font(.footnote.weight(.medium))
                    .opacity(0.85)

                Text(profitDisplay(stats.profit))
                    .font(.system(size: heroProfitSize, weight: .bold))
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

    /// 月目標進度條；目標為 0 (使用者未設定) 時整列隱藏
    /// - Parameter stats: 已計算的本月統計
    /// - Returns: 進度條 view
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

    /// KPI 卡片格
    /// - Parameters:
    ///   - stats: 已計算的本月統計
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 區塊 view
    @ViewBuilder
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

    /// 單一 KPI 卡片：左上 tint 色點 + 標籤、中段大數字、下方變化指標
    /// - Parameters:
    ///   - label: 卡片左上方的指標名稱，例如「營業額」、「毛利率」
    ///   - value: 卡片中央顯示的數值字串 (已預先 format)
    ///   - tint: 左上方色點顏色，用來區分指標分類
    ///   - delta: 下方變化字串，例如「+18.2%」、「3 open」
    ///   - deltaUp: 變化方向：`true` 顯示上升色 (綠)、`false` 顯示下降色 (紅)、`nil` 顯示中性色
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: KPI 卡片 view
    @ViewBuilder
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
                Text(LocalizedStringKey(label))
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
                                .padding(.vertical, BLSpacing.extraSmall)

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

// MARK: - Private Method

private extension DashboardView {

    // MARK: Layout

    /// KPI 卡片的欄位設定 (僅 compact 用 2 欄)
    var kpiColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: BLSpacing.small), count: 2)
    }

    /// 是否採用 hero + 3 KPI 並排版面 (iPad)
    var useWideHero: Bool {
        return horizontalSizeClass != .compact
    }

    // MARK: Formatting

    /// 將獲利金額格式化為含正負號的新台幣字串
    /// - Parameter profit: 獲利金額
    /// - Returns: 顯示在 hero 卡上的金額字串
    func profitDisplay(_ profit: Decimal) -> String {
        let formatted = formatTwd(profit)

        return profit > 0 ? "+\(formatted)" : formatted
    }

    /// 依 App 選定 locale 將金額格式化為新台幣 (無小數位)
    /// - Parameter amount: 金額
    /// - Returns: 含 NT$ 前綴的字串
    func formatTwd(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }

    /// 依 App 選定 locale 將比例格式化為百分比
    /// - Parameter value: 介於 0 與 1 之間的比例
    /// - Returns: 含一位小數的百分比字串
    func formatPercent(_ value: Decimal) -> String {
        value.formatted(.percent.precision(.fractionLength(1)).locale(locale))
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
    ///
    /// 一律以「上升 → 綠、下降 → 紅、未知 → 中性」表示**原始方向**
    ///
    /// 針對成本這類「漲是壞」的指標，UI 不主動翻轉色彩，由使用者依 label 與內容自行判讀
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

    /// 依 App 選定 locale 把 MoM delta (小數型成長率) 轉成 `+18.2% MoM` 風格字串；`nil` 顯示「— MoM」
    /// - Parameter delta: 成長率，例如 `0.182` 表示 +18.2%
    /// - Returns: KPI 卡顯示用字串
    func percentDeltaDisplay(_ delta: Decimal?) -> String {
        guard let delta else {
            return "— MoM"
        }
        let formatted = delta.formatted(.percent.precision(.fractionLength(1)).locale(locale))
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
        let formatted = absDelta.formatted(.percent.precision(.fractionLength(1)).locale(locale))
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
