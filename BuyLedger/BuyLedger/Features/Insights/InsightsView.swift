//
//  InsightsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 分析分頁的主要畫面。
///
/// 對應設計稿 iPhone / iPad / Mac 的「分析」頁：bar chart 走勢、商品類別排行、成本結構 donut、8 週下單熱力圖；可切換期間、可點擊類別 drill-down 到訂單頁。
struct InsightsView: View {

    // MARK: - View Properties

    /// App 根層級 store。
    @Bindable var store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

#if !os(macOS)
    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone（compact）與 iPad（regular）。
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    /// 目前選取的趨勢期間。
    @State private var selectedRange: InsightsDateRange = .twelveMonths

    // MARK: - View Body

    /// 分析頁的畫面內容。
    ///
    /// 訂單為空時改顯示 ``emptyState(palette:)``——空圖表（$0、空 heatmap）對使用者沒有價值且容易誤導。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        Group {
            if !store.orders.isLoading && store.orders.orders.isEmpty {
                emptyState(palette: palette)
            } else {
                analyticsContent(palette: palette)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .task {
            await store.send(.orders(.task)).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension InsightsView {

    /// 有訂單資料時的完整分析內容。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 分析內容 view。
    func analyticsContent(palette: BLPalette) -> some View {
        let stats = computeStats(orders: store.orders.orders, range: selectedRange)

        return ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                titleHeader(palette: palette)
                rangePicker
                trendCard(stats: stats, palette: palette)
                breakdownGrid(stats: stats, palette: palette)
                heatmapCard(palette: palette)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 沒有訂單時的空狀態，引導使用者先建立訂單。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 空狀態 view。
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView {
            Label("尚未有足夠可用於分析的資料", systemImage: "chart.bar.xaxis")
        } description: {
            Text("先到「訂單」分頁新增幾筆訂單，這裡就會出現走勢、類別排行、成本結構與下單熱力圖。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 大標題列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 標題列 view。
    func titleHeader(palette: BLPalette) -> some View {
        Text("分析")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(palette.label)
            .accessibilityAddTraits(.isHeader)
    }

    /// 期間選擇器。
    var rangePicker: some View {
        Picker("期間", selection: $selectedRange) {
            ForEach(InsightsDateRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    /// 走勢卡。
    /// - Parameters:
    ///   - stats: 已計算的分析資料。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 走勢卡 view。
    func trendCard(stats: InsightsStats, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text(selectedRange.trendCardTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.secondaryLabel)

                    Spacer()

                    Text(stats.trendDelta)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.green)
                }

                Text(formatTwd(stats.totalProfit))
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)

                BLBarChart(data: stats.trendBars, height: 200)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 類別排行 + 成本結構並列。
    /// - Parameters:
    ///   - stats: 已計算的分析資料。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 並列卡片 view。
    @ViewBuilder
    func breakdownGrid(stats: InsightsStats, palette: BLPalette) -> some View {
        if useWideLayout {
            HStack(alignment: .top, spacing: BLSpacing.medium) {
                categoryCard(stats: stats, palette: palette)
                    .frame(maxWidth: .infinity)
                costStructureCard(stats: stats, palette: palette)
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: BLSpacing.medium) {
                categoryCard(stats: stats, palette: palette)
                costStructureCard(stats: stats, palette: palette)
            }
        }
    }

    /// 類別排行卡。
    /// - Parameters:
    ///   - stats: 已計算的分析資料。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 類別卡 view。
    func categoryCard(stats: InsightsStats, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("類別排行")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                if stats.categories.isEmpty {
                    Text("尚無分類資料")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryLabel)
                } else {
                    let topProfit = stats.categories.first?.profit ?? 1
                    ForEach(Array(stats.categories.enumerated()), id: \.element.name) { index, category in
                        Button {
                            store.send(.categorySelected(category.name))
                        } label: {
                            categoryRow(
                                rank: index + 1,
                                category: category,
                                topProfit: topProfit,
                                tint: categoryTints(palette: palette)[index % categoryTints(palette: palette).count],
                                palette: palette
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("查看 \(category.name) 類別的訂單")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 類別排行單列。
    /// - Parameters:
    ///   - rank: 名次。
    ///   - category: 類別資料。
    ///   - topProfit: 第一名的獲利金額（作為比例基準）。
    ///   - tint: bar 顏色。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 類別列 view。
    func categoryRow(
        rank: Int,
        category: InsightsCategory,
        topProfit: Decimal,
        tint: Color,
        palette: BLPalette
    ) -> some View {
        let value = NSDecimalNumber(decimal: category.profit).doubleValue
        let total = NSDecimalNumber(decimal: topProfit).doubleValue
        let fraction = total > 0 ? CGFloat(value / total) : 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(rank). \(category.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                Spacer()

                Text(formatTwd(category.profit))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(palette.tertiaryLabel)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.fillQuaternary)
                    Capsule().fill(tint).frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
    }

    /// 成本結構 donut 卡。
    /// - Parameters:
    ///   - stats: 已計算的分析資料。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 成本結構卡 view。
    func costStructureCard(stats: InsightsStats, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("成本結構")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                HStack(alignment: .center, spacing: BLSpacing.large) {
                    BLDonutChart(
                        segments: stats.costSegments.map {
                            BLDonutSegment(
                                label: $0.label,
                                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                                color: $0.color
                            )
                        },
                        centerTitle: "總成本",
                        centerValue: formatTwd(stats.totalCost)
                    )

                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        ForEach(stats.costSegments) { segment in
                            HStack(spacing: BLSpacing.small) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(segment.color)
                                    .frame(width: 8, height: 8)

                                Text(segment.label)
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryLabel)

                                Spacer()

                                Text(formatTwd(segment.value))
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(palette.label)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// 過去 8 週的下單熱力圖。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 熱力圖卡 view。
    func heatmapCard(palette: BLPalette) -> some View {
        let cells = computeHeatmap(orders: store.orders.orders)
        let maxCount = cells.values.max() ?? 1

        return BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("下單熱力 · 過去 8 週")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                LazyVGrid(
                    columns: [GridItem(.fixed(28), spacing: 6)] + Array(
                        repeating: GridItem(.flexible(), spacing: 6),
                        count: 8
                    ),
                    spacing: 6
                ) {
                    Text(" ")
                        .frame(width: 28)

                    ForEach(0..<8, id: \.self) { week in
                        Text("W\(week + 1)")
                            .font(.caption2)
                            .foregroundStyle(palette.tertiaryLabel)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(0..<7, id: \.self) { weekday in
                        Text(weekdayLabel(weekday))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryLabel)
                            .frame(width: 28, alignment: .leading)

                        ForEach(0..<8, id: \.self) { week in
                            heatmapCell(
                                count: cells[HeatmapKey(week: week, weekday: weekday)] ?? 0,
                                maxCount: maxCount,
                                palette: palette
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 熱力圖單一 cell。
    /// - Parameters:
    ///   - count: 訂單筆數。
    ///   - maxCount: 整張熱力圖中最高的訂單筆數，用來決定相對深淺。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: cell view。
    func heatmapCell(count: Int, maxCount: Int, palette: BLPalette) -> some View {
        let opacity: Double = {
            guard count > 0, maxCount > 0 else { return 0.06 }
            return 0.2 + (Double(count) / Double(maxCount)) * 0.8
        }()

        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(palette.accent.opacity(opacity))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(count == 0 ? "0 單" : "\(count) 單")
    }
}

// MARK: - Layout Helper

private extension InsightsView {

    /// 是否使用寬版面（並列兩張卡）。
    var useWideLayout: Bool {
#if os(macOS)
        return true
#else
        return horizontalSizeClass != .compact
#endif
    }

    /// 類別 bar 的色盤序列。
    func categoryTints(palette: BLPalette) -> [Color] {
        [palette.accent, palette.purple, palette.orange, palette.teal, palette.pink]
    }

    /// 顯示在熱力圖左側的星期縮寫。
    /// - Parameter index: 0 為週一、6 為週日。
    /// - Returns: 中文單字星期縮寫。
    func weekdayLabel(_ index: Int) -> String {
        ["一", "二", "三", "四", "五", "六", "日"][index]
    }
}

// MARK: - Date Range

/// 分析頁可選的趨勢期間。
enum InsightsDateRange: String, CaseIterable, Identifiable, Sendable {

    // MARK: - Cases

    /// 過去 30 天。
    case thirtyDays

    /// 過去 6 個月。
    case sixMonths

    /// 過去 12 個月。
    case twelveMonths

    // MARK: - Identifiable Properties

    /// 區間穩定識別。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在 segmented control 上的標題。
    var title: String {
        switch self {
        case .thirtyDays:
            "30 天"
        case .sixMonths:
            "6 個月"
        case .twelveMonths:
            "12 個月"
        }
    }

    /// 顯示在 trend card 上的子標題。
    var trendCardTitle: String {
        switch self {
        case .thirtyDays:
            "30 天淨獲利"
        case .sixMonths:
            "6 個月淨獲利"
        case .twelveMonths:
            "12 個月淨獲利"
        }
    }
}

// MARK: - Statistics Computation

/// 分析頁的整體統計。
private struct InsightsStats {

    // MARK: - Data Properties

    /// 走勢圖（依 range 動態：30 天用「日」、6/12 個月用「月」）。
    let trendBars: [BLBarChartValue]

    /// 期間內淨獲利總和。
    let totalProfit: Decimal

    /// 顯示在走勢卡右上角的成長率字樣。
    let trendDelta: String

    /// 各分類獲利排行（由高到低）。
    let categories: [InsightsCategory]

    /// 成本結構各區塊。
    let costSegments: [InsightsCostSegment]

    /// 全期成本總和。
    let totalCost: Decimal
}

/// 類別排行資料。
private struct InsightsCategory: Identifiable {

    // MARK: - Identifiable Properties

    /// 用 name 當識別值。
    var id: String { name }

    // MARK: - Data Properties

    /// 類別名稱。
    let name: String

    /// 該類別累計獲利。
    let profit: Decimal
}

/// 成本結構單一區塊。
private struct InsightsCostSegment: Identifiable {

    // MARK: - Identifiable Properties

    /// 用 label 當識別值。
    var id: String { label }

    // MARK: - Data Properties

    /// 顯示在 legend 的標籤。
    let label: String

    /// 此區塊金額。
    let value: Decimal

    /// 顯示色彩。
    let color: Color
}

/// 熱力圖鍵。
private struct HeatmapKey: Hashable {

    // MARK: - Data Properties

    /// 第幾週（0 為最早、7 為本週）。
    let week: Int

    /// 第幾天（0 為週一、6 為週日）。
    let weekday: Int
}

private extension InsightsView {

    /// 視為「已實現」的訂單狀態集合。
    static let realizedStatuses: Set<OrderStatus> = [.confirmed, .purchased, .shipping, .delivered]

    /// 計算 ``InsightsStats``。
    /// - Parameters:
    ///   - orders: 目前訂單清單。
    ///   - range: 趨勢期間。
    /// - Returns: 分析頁需要的統計值。
    func computeStats(orders: [LedgerOrder], range: InsightsDateRange) -> InsightsStats {
        let realized = orders.filter { Self.realizedStatuses.contains($0.status) }
        let calendar = Calendar.current
        let now = Date()
        let trendBars = trendBars(realized: realized, range: range, calendar: calendar, now: now)

        let totalProfit = trendBars.reduce(Decimal(0)) { $0 + Decimal($1.value) }

        let categoryGroup = Dictionary(grouping: realized, by: { $0.category })
        let categories = categoryGroup
            .map { InsightsCategory(name: $0.key, profit: $0.value.reduce(Decimal.zero) { $0 + $1.summary.profit }) }
            .sorted { $0.profit > $1.profit }

        let palette = BLTheme.palette(for: colorScheme)
        let totalCost = realized.reduce(Decimal.zero) { $0 + $1.summary.totalCost }
        let totalItem = realized.reduce(Decimal.zero) { $0 + $1.itemCost }
        let totalDom = realized.reduce(Decimal.zero) { $0 + $1.domesticShipping }
        let totalIntl = realized.reduce(Decimal.zero) { $0 + $1.internationalShipping }
        let totalFees = realized.reduce(Decimal.zero) { $0 + $1.summary.fees }

        let costSegments = [
            InsightsCostSegment(label: "商品金額", value: totalItem, color: palette.accent),
            InsightsCostSegment(label: "國內運費", value: totalDom, color: palette.teal),
            InsightsCostSegment(label: "國際集運", value: totalIntl, color: palette.purple),
            InsightsCostSegment(label: "手續費", value: totalFees, color: palette.orange),
        ].filter { $0.value > 0 }

        return InsightsStats(
            trendBars: trendBars,
            totalProfit: totalProfit,
            trendDelta: realized.isEmpty ? " " : "↑ 累計",
            categories: categories,
            costSegments: costSegments,
            totalCost: totalCost
        )
    }

    /// 依 range 產生對應的 bar chart 資料：30 天逐日、6/12 個月逐月。
    /// - Parameters:
    ///   - realized: 已實現的訂單。
    ///   - range: 趨勢期間。
    ///   - calendar: 用來分組的曆法。
    ///   - now: 基準日。
    /// - Returns: 對應每段時間的累計獲利。
    func trendBars(
        realized: [LedgerOrder],
        range: InsightsDateRange,
        calendar: Calendar,
        now: Date
    ) -> [BLBarChartValue] {
        switch range {
        case .thirtyDays:
            return (0..<30).reversed().compactMap { offset in
                guard
                    let dayStart = calendar.date(byAdding: .day, value: -offset, to: now),
                    let interval = calendar.dateInterval(of: .day, for: dayStart)
                else {
                    return nil
                }

                let dayProfit = realized
                    .filter { (interval.start..<interval.end).contains($0.date) }
                    .reduce(Decimal.zero) { $0 + $1.summary.profit }

                let label = dayStart.formatted(
                    .dateTime
                        .day(.defaultDigits)
                        .locale(Locale(identifier: "zh_TW"))
                )

                return BLBarChartValue(
                    label: label,
                    value: NSDecimalNumber(decimal: dayProfit).doubleValue
                )
            }

        case .sixMonths, .twelveMonths:
            let monthCount = range == .sixMonths ? 6 : 12

            return (0..<monthCount).reversed().compactMap { offset in
                guard
                    let monthStart = calendar.date(byAdding: .month, value: -offset, to: now),
                    let interval = calendar.dateInterval(of: .month, for: monthStart)
                else {
                    return nil
                }

                let monthProfit = realized
                    .filter { (interval.start..<interval.end).contains($0.date) }
                    .reduce(Decimal.zero) { $0 + $1.summary.profit }

                let label = monthStart.formatted(
                    .dateTime
                        .month(.defaultDigits)
                        .locale(Locale(identifier: "zh_TW"))
                )

                return BLBarChartValue(
                    label: label,
                    value: NSDecimalNumber(decimal: monthProfit).doubleValue
                )
            }
        }
    }

    /// 計算過去 8 週每天的下單筆數（不分狀態，只看建立日期）。
    /// - Parameter orders: 目前訂單清單。
    /// - Returns: 鍵為 `HeatmapKey`、值為訂單筆數。
    func computeHeatmap(orders: [LedgerOrder]) -> [HeatmapKey: Int] {
        let calendar = Calendar.current
        let now = Date()
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return [:]
        }

        var result: [HeatmapKey: Int] = [:]

        for order in orders {
            let day = calendar.startOfDay(for: order.date)
            let daysFromCurrentWeekStart = calendar.dateComponents([.day], from: day, to: currentWeek.start).day ?? 0
            let weekOffset = -(daysFromCurrentWeekStart / 7)
            let weekIndex = 7 - weekOffset

            guard weekIndex >= 0, weekIndex < 8 else { continue }

            // weekday: 1=週日 ... 7=週六；轉成 0=週一 ... 6=週日
            let raw = calendar.component(.weekday, from: order.date)
            let weekday = (raw + 5) % 7

            let key = HeatmapKey(week: weekIndex, weekday: weekday)
            result[key, default: 0] += 1
        }

        return result
    }
}

// MARK: - Formatting

private extension InsightsView {

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
}

// MARK: - Preview

#Preview("分析") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        return state
    }()

    return InsightsView(
        store: Store(initialState: previewState) {
            RootFeature()
        }
    )
}
