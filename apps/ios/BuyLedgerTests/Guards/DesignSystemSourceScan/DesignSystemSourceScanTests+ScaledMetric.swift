//
//  DesignSystemSourceScanTests+ScaledMetric.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import Testing

extension DesignSystemSourceScanTests {

    /// 規則十二的呼叫情境：同檔 `@ScaledMetric` 屬性傳進元件縮放參數才回報，基準值、一般常數、非元件呼叫與註解通過
    ///
    /// - Parameter scenario: 原始碼片段與獨立指定的預期違規行號
    @Test(arguments: Self.doubleScaledArgumentCases)
    func doubleScaledArgumentLineNumbers_呼叫元件的六種寫法_分類結果符合預期(scenario: SourceScanCase) {
        // Given
        let scaledParameters: [String: Set<String>] = ["BLSparkline": ["height"]]

        // When
        let lineNumbers = Self.doubleScaledArgumentLineNumbers(
            in: scenario.source,
            scaledParameters: scaledParameters
        )

        // Then
        #expect(lineNumbers == scenario.expectedLineNumbers, "原始碼片段：\(scenario.source)")
    }

    /// 規則十二的掃描輸入：辨識不出元件自行縮放的參數時，正式掃描恆為通過
    ///
    /// - Throws: 原始檔讀取或目錄掃描失敗時拋出錯誤
    @Test
    func scaledComponentParameters_掃描設計系統元件_辨識圖表高度參數() throws(any Error) {
        // Given
        let scan = Self.scaledComponentParameters

        // When
        let parameters = try scan()

        // Then
        #expect(parameters["BLBarChart"] == ["height"])
        #expect(parameters["BLSparkline"] == ["height"])
    }

    /// 規則十二：元件已用 `@ScaledMetric` 縮放的參數，呼叫端傳基準值
    ///
    /// - Throws: 原始檔讀取或目錄掃描失敗時拋出錯誤
    /// - Note: 合成 `init` 會把傳入值當成基準再縮放一次，字級越大偏差越大
    @Test
    func doubleScaledArgumentViolations_傳入元件自行縮放的參數_使用基準值() throws(any Error) {
        // Given
        let scan = Self.doubleScaledArgumentViolations

        // When
        let violations = try scan()

        // Then
        #expect(
            violations.isEmpty,
            "以下位置把 `@ScaledMetric` 屬性傳進元件自行縮放的參數，會放大兩次，應改傳基準點數：\(Self.describe(violations))"
        )
    }
}

// MARK: - Private Method

private extension DesignSystemSourceScanTests {

    /// 規則十二的六種呼叫情境，預期行號逐列指定
    static var doubleScaledArgumentCases: [SourceScanCase] {
        [
            SourceScanCase(
                source: """
                @ScaledMetric private var sparklineHeight: CGFloat = 36
                BLSparkline(
                    data: points,
                    height: sparklineHeight
                )
                """,
                expectedLineNumbers: [4]
            ),
            SourceScanCase(
                source: """
                @ScaledMetric(relativeTo: .title) private var chartSize: CGFloat = 28
                BLSparkline(data: points, height: chartSize)
                """,
                expectedLineNumbers: [2]
            ),
            SourceScanCase(
                source: """
                @ScaledMetric private var sparklineHeight: CGFloat = 36
                BLSparkline(data: points, height: 36)
                """,
                expectedLineNumbers: []
            ),
            SourceScanCase(
                source: """
                @ScaledMetric private var chartHeight: CGFloat = 200
                chart.frame(height: chartHeight)
                """,
                expectedLineNumbers: []
            ),
            SourceScanCase(
                source: """
                let sparklineHeight: CGFloat = 36
                BLSparkline(data: points, height: sparklineHeight)
                """,
                expectedLineNumbers: []
            ),
            SourceScanCase(
                source: """
                @ScaledMetric private var sparklineHeight: CGFloat = 36
                // BLSparkline(data: points, height: sparklineHeight)
                """,
                expectedLineNumbers: []
            ),
        ]
    }
}
