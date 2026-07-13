//
//  DashboardStats.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation

/// 總覽頁使用的本月與走勢統計
///
/// 完全 derive 自訂單清單，不依賴「現在」時間內部讀取：由呼叫端 (View 或測試) 以 `referenceDate` 與 `calendar` 注入基準時間
///
/// MoM (month-over-month) 相關欄位在「上月無資料」時為 `nil`，UI 應顯示「—」並停用方向色
struct DashboardStats {

    // MARK: - Data Properties

    /// 本月已實現的營業額
    let revenue: Decimal

    /// 本月成本
    let cost: Decimal

    /// 本月淨獲利
    let profit: Decimal

    /// 毛利率 (profit / revenue)
    let margin: Decimal

    /// 進行中 (confirmed / purchased / shipping) 的訂單數
    let activeCount: Int

    /// 本月已實現的訂單筆數
    let orderCount: Int

    /// 月目標金額 (來自 `SettingsFeature.State.monthlyProfitGoalTwd`)。`0` 代表使用者未設定，UI 應隱藏進度條
    let goal: Decimal

    /// 已達月目標的比例 (0 ~ 1)
    let goalProgress: CGFloat

    /// 近 12 個月的淨獲利走勢值
    let sparkline: [Double]

    /// 近期訂單 (依日期由新到舊取前 4 筆)
    let recentOrders: [LedgerOrder]

    /// 營業額相對上月的成長率 (小數形式，0.18 即 +18%)；上月為 0 或無資料時為 `nil`
    let revenueDelta: Decimal?

    /// 成本相對上月的成長率 (小數形式)；上月為 0 或無資料時為 `nil`
    let costDelta: Decimal?

    /// 淨獲利相對上月的成長率 (小數形式)；上月為 0 或無資料時為 `nil`
    let profitDelta: Decimal?

    /// 毛利率相對上月的差 (百分點，0.024 即 +2.4pt)；上月無資料時為 `nil`
    let marginDelta: Decimal?

    // MARK: - Static Properties

    /// 視為「進行中」的訂單狀態集合
    static let activeStatuses: Set<OrderStatus> = [
        .confirmed,
        .purchased,
        .shipping,
        .partiallyArrived,
        .arrived
    ]

    /// 視為「已實現」的訂單狀態集合 (用於本月損益)，引用 domain 層的單一事實來源
    static let realizedStatuses = OrderStatus.realizedStatuses

    /// 「近期訂單」列表顯示的筆數；同時控制 ``init(orders:monthlyGoal:referenceDate:calendar:)`` 的 prefix 取數
    static let recentOrdersCount = 4

    // MARK: - Init

    /// 依訂單清單、月度目標與基準時間計算總覽頁統計
    /// - Parameters:
    ///   - orders: 目前的訂單清單
    ///   - monthlyGoal: 月度淨獲利目標 (來自 SettingsFeature；`0` 代表未設定)
    ///   - referenceDate: 基準「現在」時間，決定「本月／上月」與 12 個月 sparkline 範圍
    ///   - calendar: 用來算月份區間的曆法
    init(orders: [LedgerOrder], monthlyGoal: Decimal, referenceDate: Date, calendar: Calendar) {
        let current = DashboardStats.monthlyTotals(orders: orders, calendar: calendar, referenceDate: referenceDate)
        let previous: MonthlyTotals = {
            guard let priorMonth = calendar.date(byAdding: .month, value: -1, to: referenceDate) else {
                return .empty
            }
            return DashboardStats.monthlyTotals(
                orders: orders,
                calendar: calendar,
                referenceDate: priorMonth
            )
        }()

        let activeCount = orders.lazy.filter {
            DashboardStats.activeStatuses.contains($0.status)
        }.count

        let pct: CGFloat
        if monthlyGoal == 0 {
            pct = 0
        } else {
            let raw = NSDecimalNumber(decimal: current.profit / monthlyGoal).doubleValue
            pct = CGFloat(min(1.0, max(0.0, raw)))
        }

        let recent = orders.sorted { $0.date > $1.date }.prefix(DashboardStats.recentOrdersCount)

        self.revenue = current.revenue
        self.cost = current.cost
        self.profit = current.profit
        self.margin = current.margin
        self.activeCount = activeCount
        self.orderCount = current.orderCount
        self.goal = monthlyGoal
        self.goalProgress = pct
        self.sparkline = DashboardStats.monthlyProfitSparkline(
            orders: orders,
            calendar: calendar,
            referenceDate: referenceDate
        )
        self.recentOrders = Array(recent)
        self.revenueDelta = DashboardStats.ratio(current: current.revenue, previous: previous.revenue)
        self.costDelta = DashboardStats.ratio(current: current.cost, previous: previous.cost)
        self.profitDelta = DashboardStats.ratio(current: current.profit, previous: previous.profit)
        self.marginDelta = previous.orderCount == 0 ? nil : current.margin - previous.margin
    }
}

// MARK: - Nested Types

extension DashboardStats {

    /// 任意月份的彙總值，用來複用「本月」與「上月」的計算
    fileprivate struct MonthlyTotals {

        // MARK: - Data Properties

        /// 該月已實現訂單的營業額總和
        let revenue: Decimal

        /// 該月已實現訂單的成本總和 (含商品、運費與手續費)
        let cost: Decimal

        /// 該月已實現訂單的淨獲利總和 (`revenue - cost`)
        let profit: Decimal

        /// 該月毛利率 (`profit / revenue`)；`revenue` 為 0 時為 0
        let margin: Decimal

        /// 該月已實現的訂單筆數，作為「上月有無資料可比」的判斷依據
        let orderCount: Int

        // MARK: - Static Properties

        /// 整月無資料時使用的零值彙總，避免呼叫端各自處理 nil
        static let empty = MonthlyTotals(
            revenue: 0,
            cost: 0,
            profit: 0,
            margin: 0,
            orderCount: 0
        )
    }
}

// MARK: - Private Method

private extension DashboardStats {

    /// 計算指定月份的營收／成本／獲利／毛利率／訂單筆數
    /// - Parameters:
    ///   - orders: 全部訂單清單
    ///   - calendar: 用來算月份區間的曆法
    ///   - referenceDate: 基準日期，會以此日的所在月份為查詢範圍
    /// - Returns: 月度彙總值；找不到月份區間時回傳 `.empty`
    static func monthlyTotals(orders: [LedgerOrder], calendar: Calendar, referenceDate: Date) -> MonthlyTotals {
        guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else {
            return .empty
        }

        let monthOrders = orders.filter { order in
            DashboardStats.realizedStatuses.contains(order.status)
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

    /// 計算 `(current - previous) / previous` 的成長率；`previous == 0` 時回 `nil` 表「無基準可比」
    /// - Parameters:
    ///   - current: 本期值
    ///   - previous: 上期值
    /// - Returns: 成長率 (小數)，上期為 0 時 `nil`
    static func ratio(current: Decimal, previous: Decimal) -> Decimal? {
        guard previous != 0 else {
            return nil
        }
        return (current - previous) / previous
    }

    /// 產生最近 12 個月的淨獲利走勢資料
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - calendar: 用來計算月份的曆法
    ///   - referenceDate: 基準日期 (即「最後一個月」的所在日期)
    /// - Returns: 共 12 個 `Double` 的走勢值
    static func monthlyProfitSparkline(
        orders: [LedgerOrder],
        calendar: Calendar,
        referenceDate: Date
    ) -> [Double] {
        let realized = orders.filter {
            DashboardStats.realizedStatuses.contains($0.status)
        }

        return (0..<12).reversed().map { offset in
            guard let monthStart = calendar.date(
                byAdding: .month,
                value: -offset,
                to: referenceDate
            ),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else {
                return 0
            }

            let total = realized
                .filter { (interval.start..<interval.end).contains($0.date) }
                .reduce(Decimal.zero) { $0 + $1.summary.profit }

            return NSDecimalNumber(decimal: total).doubleValue
        }
    }
}
