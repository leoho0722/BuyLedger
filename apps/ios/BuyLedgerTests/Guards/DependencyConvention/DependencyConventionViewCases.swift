//
//  DependencyConventionViewCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

/// 畫面依賴與裝置曆法規則的違規與合規案例
enum DependencyConventionViewCases {}

// MARK: - Computed Properties

extension DependencyConventionViewCases {

    /// 畫面依賴規則應拒絕的案例，由 `DependencyConventionScanScenario` 彙總
    static var viewViolationCases: [DependencyScanViolationCase] {
        [
            DependencyScanViolationCase(
                name: "畫面結構內宣告 @Dependency",
                source: #"""
                struct DashboardView: View {
                    @Dependency(\.date) private var date

                    var body: some View {
                        Text("")
                    }
                }
                """#,
                relativePath: "Features/Dashboard/Presentation/Root/Views/DashboardView.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 2,
                expectedReference: "@Dependency(",
                expectedReason: "遵循 `View` 的型別不得宣告 `@Dependency`，依賴改由 Feature 寫入 State"
            ),
            DependencyScanViolationCase(
                name: "以 extension 遵循 View 時宣告 @Dependency",
                source: #"""
                struct OrderSummaryCard {
                    let title: String
                }

                extension OrderSummaryCard: View {
                    @Dependency(\.date) private var date

                    var body: some View {
                        Text(title)
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryCard.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 6,
                expectedReference: "@Dependency(",
                expectedReason: "遵循 `View` 的型別不得宣告 `@Dependency`，依賴改由 Feature 寫入 State"
            ),
            DependencyScanViolationCase(
                name: "主宣告帶 @Dependency，View 遵循寫在另一個 extension",
                source: #"""
                struct OrderSummaryCard {
                    @Dependency(\.date) private var date
                }

                extension OrderSummaryCard: View {
                    var body: some View {
                        Text("")
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryCard.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 2,
                expectedReference: "@Dependency(",
                expectedReason: "遵循 `View` 的型別不得宣告 `@Dependency`，依賴改由 Feature 寫入 State"
            ),
            DependencyScanViolationCase(
                name: "跨行繼承子句遵循 View 時宣告 @Dependency",
                source: #"""
                struct OrderSummaryCard: Equatable,
                    View {
                    @Dependency(\.date) private var date

                    var body: some View {
                        Text("")
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryCard.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 3,
                expectedReference: "@Dependency(",
                expectedReason: "遵循 `View` 的型別不得宣告 `@Dependency`，依賴改由 Feature 寫入 State"
            ),
            DependencyScanViolationCase(
                name: "SwiftUI.View 限定名稱遵循時宣告 @Dependency",
                source: #"""
                struct OrderSummaryCard: SwiftUI.View {
                    @Dependency(\.date) private var date

                    var body: some SwiftUI.View {
                        Text("")
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryCard.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 2,
                expectedReference: "@Dependency(",
                expectedReason: "遵循 `View` 的型別不得宣告 `@Dependency`，依賴改由 Feature 寫入 State"
            ),
            DependencyScanViolationCase(
                name: "非 View 型別內讀取 Calendar.current",
                source: #"""
                struct OrderSummaryFormatter {
                    private let calendar = Calendar.current

                    func weekday(of date: Date) -> Int {
                        calendar.component(.weekday, from: date)
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryFormatter.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 2,
                expectedReference: "Calendar.current",
                expectedReason: "不得讀取裝置曆法，曆法改由依賴注入的 calendar 提供"
            ),
            DependencyScanViolationCase(
                name: "非 View 型別內讀取 Calendar.autoupdatingCurrent",
                source: #"""
                enum InsightsCalendar {
                    static let calendar = Calendar.autoupdatingCurrent
                }
                """#,
                relativePath: "Features/Insights/InsightsCalendar.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 2,
                expectedReference: "Calendar.autoupdatingCurrent",
                expectedReason: "不得讀取裝置曆法，曆法改由依賴注入的 calendar 提供"
            ),
            DependencyScanViolationCase(
                name: "畫面本體內讀取 Calendar.current",
                source: #"""
                struct WeekdayLabels: View {
                    var body: some View {
                        Text(Calendar.current.shortWeekdaySymbols.joined())
                    }
                }
                """#,
                relativePath: "Features/Insights/WeekdayLabels.swift",
                sourceTree: .production,
                rules: [.viewDependency],
                expectedLine: 3,
                expectedReference: "Calendar.current",
                expectedReason: "不得讀取裝置曆法，曆法改由依賴注入的 calendar 提供"
            ),
        ]
    }

    /// 畫面依賴規則應接受的案例，由 `DependencyConventionScanScenario` 彙總
    static var viewPassingCases: [DependencyScanPassingCase] {
        [
            DependencyScanPassingCase(
                name: "同檔 Reducer 宣告的依賴不屬於畫面",
                source: #"""
                struct DashboardFeature: Reducer {
                    @Dependency(\.date) private var date

                    var body: some Reducer<State, Action> {
                        Reduce { _, _ in .none }
                    }
                }

                struct DashboardView: View {
                    let store: StoreOf<DashboardFeature>

                    var body: some View {
                        Text("")
                    }
                }
                """#,
                relativePath: "Features/Dashboard/Presentation/Root/DashboardFeature.swift",
                sourceTree: .production,
                rules: [.viewDependency]
            ),
            DependencyScanPassingCase(
                name: "非 View 型別宣告依賴",
                source: #"""
                struct OrderStatistics {
                    @Dependency(\.date) private var date

                    func total() -> Int {
                        0
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderStatistics.swift",
                sourceTree: .production,
                rules: [.viewDependency]
            ),
            DependencyScanPassingCase(
                name: "只遵循 ViewModifier 的型別宣告依賴",
                source: #"""
                struct OrderCardStyle: ViewModifier {
                    @Dependency(\.date) private var date

                    func body(content: Content) -> some View {
                        content
                    }
                }
                """#,
                relativePath: "Shared/DesignSystem/OrderCardStyle.swift",
                sourceTree: .production,
                rules: [.viewDependency]
            ),
            DependencyScanPassingCase(
                name: "名稱含 View 但不是整字 View 的型別宣告依賴",
                source: #"""
                final class OrderListViewModel: ObservableObject {
                    @Dependency(\.date) private var date

                    @ViewBuilder var header: some View {
                        EmptyView()
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderListViewModel.swift",
                sourceTree: .production,
                rules: [.viewDependency]
            ),
            DependencyScanPassingCase(
                name: "註解與字串中的 @Dependency 與 Calendar.current 不命中",
                source: #"""
                struct OrderSummaryCard: View {
                    // @Dependency(\.date) 與 Calendar.current 只留在註解中
                    let note = #"@Dependency(\.date) 與 Calendar.current"#

                    var body: some View {
                        Text(note)
                    }
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryCard.swift",
                sourceTree: .production,
                rules: [.viewDependency]
            ),
            DependencyScanPassingCase(
                name: "固定曆法不是裝置曆法",
                source: #"""
                struct OrderSummaryFormatter {
                    private let calendar = Calendar(identifier: .gregorian)
                }
                """#,
                relativePath: "Features/Orders/OrderSummaryFormatter.swift",
                sourceTree: .production,
                rules: [.viewDependency]
            ),
        ]
    }
}
