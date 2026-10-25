//
//  DesignSystemSourceScanScaledMetricTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import Testing

/// `DesignSystemSourceScaledMetricScanner` 的單元測試，涵蓋元件縮放參數的辨識與基準值傳遞
struct DesignSystemSourceScanScaledMetricTests {

    /// 驗證規則十二的呼叫情境：同檔 `@ScaledMetric` 屬性傳進元件縮放參數才回報，基準值、一般常數、非元件呼叫與註解都通過
    ///
    /// - Parameter scenario: 原始碼片段與獨立指定的預期違規行號
    @Test(arguments: Self.doubleScaledArgumentCases)
    func doubleScaledArgumentLineNumbers_呼叫元件的六種寫法_分類結果符合預期(
        scenario: DesignSystemSourceScanner.SourceScanCase
    ) {
        // Given
        let scaledParameters: [String: Set<String>] = ["BLSparkline": ["height"]]

        // When
        let lineNumbers = DesignSystemSourceScaledMetricScanner.doubleScaledArgumentLineNumbers(
            in: scenario.source,
            scaledParameters: scaledParameters
        )

        // Then
        #expect(lineNumbers == scenario.expectedLineNumbers, "原始碼片段：\(scenario.source)")
    }

    /// 驗證掃描設計系統元件能辨識出 `BLBarChart` 與 `BLSparkline` 的縮放高度參數，辨識不出時正式掃描會恆為通過
    ///
    /// - Throws: 原始檔讀取或目錄掃描失敗時丟出錯誤
    @Test
    func scaledComponentParameters_掃描設計系統元件_辨識圖表高度參數() throws {
        // Given
        let scan = DesignSystemSourceScaledMetricScanner.scaledComponentParameters

        // When
        let parameters = try scan()

        // Then
        #expect(parameters["BLBarChart"] == ["height"])
        #expect(parameters["BLSparkline"] == ["height"])
    }

    /// 驗證正式原始碼傳入元件自行縮放的參數時都使用基準值，沒有把 `@ScaledMetric` 屬性直接傳入
    ///
    /// - Throws: 原始檔讀取或目錄掃描失敗時丟出錯誤
    /// - Note: 合成 `init` 會把傳入值當成基準再縮放一次，字級越大偏差越大
    @Test
    func doubleScaledArgumentViolations_傳入元件自行縮放的參數_使用基準值() throws {
        // Given
        let scan = DesignSystemSourceScaledMetricScanner.doubleScaledArgumentViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "以下位置把 `@ScaledMetric` 屬性傳進元件自行縮放的參數，會放大兩次，應改傳基準點數：\(DesignSystemSourceScanner.describe(violations))"
        )
    }
}

// MARK: - Private Method

private extension DesignSystemSourceScanScaledMetricTests {

    /// 規則十二的六種呼叫情境，預期行號逐列指定
    static var doubleScaledArgumentCases: [DesignSystemSourceScanner.SourceScanCase] {
        [
            DesignSystemSourceScanner.SourceScanCase(
                source: """
                    @ScaledMetric private var sparklineHeight: CGFloat = 36
                    BLSparkline(
                        data: points,
                        height: sparklineHeight
                    )
                    """,
                expectedLineNumbers: [4]
            ),
            DesignSystemSourceScanner.SourceScanCase(
                source: """
                    @ScaledMetric(relativeTo: .title) private var chartSize: CGFloat = 28
                    BLSparkline(data: points, height: chartSize)
                    """,
                expectedLineNumbers: [2]
            ),
            DesignSystemSourceScanner.SourceScanCase(
                source: """
                    @ScaledMetric private var sparklineHeight: CGFloat = 36
                    BLSparkline(data: points, height: 36)
                    """,
                expectedLineNumbers: []
            ),
            DesignSystemSourceScanner.SourceScanCase(
                source: """
                    @ScaledMetric private var chartHeight: CGFloat = 200
                    chart.frame(height: chartHeight)
                    """,
                expectedLineNumbers: []
            ),
            DesignSystemSourceScanner.SourceScanCase(
                source: """
                    let sparklineHeight: CGFloat = 36
                    BLSparkline(data: points, height: sparklineHeight)
                    """,
                expectedLineNumbers: []
            ),
            DesignSystemSourceScanner.SourceScanCase(
                source: """
                    @ScaledMetric private var sparklineHeight: CGFloat = 36
                    // BLSparkline(data: points, height: sparklineHeight)
                    """,
                expectedLineNumbers: []
            ),
        ]
    }
}
