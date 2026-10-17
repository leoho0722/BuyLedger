//
//  DependencyConventionScanScenario+LexicalCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

// MARK: - Computed Properties

extension DependencyConventionScanScenario {

    /// 去除註解、字串與正規表示式中的內容後應通過的案例，供 `passingCases` 跨檔組合使用
    static var lexicalPassingCases: [PassingCase] {
        [
            PassingCase(
                name: "含引號的 regex literal 後接合規程式碼",
                source: #"let pattern = #/"""[\s\S]*?"""|"([^"\\]|\\.)*"/#; let count = 1"#,
                relativePath: "PatternTests.swift",
                sourceTree: .unitTests,
                rules: [.dependencyTypeSubscript]
            ),
            PassingCase(
                name: "註解、字串、插值與多行字串中的規則文字不命中",
                source: ##"""
                /// @Dependency(OrderService.self)
                /* 外層註解
                   /* 巢狀註解 ModelContainer */
                   PersistenceContainer.shared */ // @Dependency(OrderService.self)
                let example = "@Dependency(CategoryService.self)"
                let rawExample = #"@Dependency(ExchangeRateService.self)"#
                let interpolated = "內容 \(String(describing: "@Dependency(PaymentMethodService.self)"))"
                let rawInterpolated = #"內容 \#(String(describing: "@Dependency(CampaignService.self)"))"#
                let documentation = """
                @Dependency(PaymentMethodService.self)
                ModelContext PersistenceContainer.shared
                static let shared = 1
                """
                let rawDocumentation = #"""
                @Dependency(CampaignService.self)
                ModelContainer
                """#
                """##,
                relativePath: "Features/Orders/OrdersFeature.swift",
                sourceTree: .production,
                rules: DependencyConventionScanTests.ScanRule.allCases
            ),
        ]
    }
}
