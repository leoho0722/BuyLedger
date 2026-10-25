//
//  OrderCategoryGridTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderCategoryGrid` 的單元測試，涵蓋欄數計算與類別切段
struct OrderCategoryGridTests {

    // MARK: - Properties

    /// 欄數計算的測試案例，涵蓋寬度、最小格寬與無障礙字級的組合
    private static let columnCases: [ColumnCase] = [
        ColumnCase(
            width: 256,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 2
        ),
        ColumnCase(
            width: 329,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 3
        ),
        ColumnCase(
            width: 476,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 4
        ),
        ColumnCase(
            width: 476,
            minimumCellWidth: 128,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 3
        ),
        ColumnCase(
            width: 200,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 2
        ),
        ColumnCase(
            width: 199,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 1
        ),
        ColumnCase(
            width: 150,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 1
        ),
        ColumnCase(
            width: 476,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: true,
            expectedColumns: 1
        ),
        ColumnCase(
            width: 329,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: true,
            expectedColumns: 1
        ),
        ColumnCase(
            width: 50,
            minimumCellWidth: 96,
            spacing: 8,
            isAccessibilitySize: false,
            expectedColumns: 1
        ),
    ]

    /// 三欄切段的測試案例，涵蓋一至四個類別的每列格數與佔位格數
    private static let rowSplitCases: [RowSplitCase] = [
        RowSplitCase(categories: ["美妝"], expectedCells: [1], expectedPlaceholders: [2]),
        RowSplitCase(categories: ["美妝", "3C"], expectedCells: [2], expectedPlaceholders: [1]),
        RowSplitCase(categories: ["美妝", "3C", "零食"], expectedCells: [3], expectedPlaceholders: [0]),
        RowSplitCase(
            categories: ["美妝", "3C", "零食", "書籍"],
            expectedCells: [3, 1],
            expectedPlaceholders: [0, 2]
        ),
    ]

    /// 驗證欄數依寬度、最小格寬與間距算出，寬度不足一欄時仍為一欄，無障礙字級不論寬度固定為一欄
    ///
    /// - Parameter columnCase: 寬度與格寬測試案例
    @Test(arguments: OrderCategoryGridTests.columnCases)
    @MainActor
    func columnCount_寬度與最小格寬組合_回傳對應欄數(columnCase: ColumnCase) {
        // Given
        let isAccessibility = columnCase.isAccessibilitySize

        // When
        let columns = OrderCategoryGrid.columnCount(
            width: columnCase.width,
            minimumCellWidth: columnCase.minimumCellWidth,
            spacing: columnCase.spacing,
            isAccessibilitySize: isAccessibility
        )

        // Then
        #expect(columns == columnCase.expectedColumns)
    }

    /// 驗證三欄時類別依數量切成多列，最後一列不足三格時以佔位格補齊
    ///
    /// - Parameter splitCase: 切段測試案例
    @Test(arguments: OrderCategoryGridTests.rowSplitCases)
    @MainActor
    func rows_三欄切段_最後一列補齊佔位格(splitCase: RowSplitCase) {
        // Given
        let columnCount = 3

        // When
        let rows = OrderCategoryGrid.rows(
            kind: .ongoing,
            categories: splitCase.categories,
            columnCount: columnCount
        )

        // Then
        #expect(rows.map { $0.categories.count } == splitCase.expectedCells)
        #expect(rows.map(\.placeholderCount) == splitCase.expectedPlaceholders)
    }

    /// 驗證類別切段後依原順序展開，與輸入清單相同，不遺漏也不重複
    @Test
    @MainActor
    func rows_切段後依原順序展開_不遺漏不重複() {
        // Given
        let categories = ["美妝", "3C", "零食", "書籍", "服飾", "食品", "文具"]
        let columnCount = 3

        // When
        let rows = OrderCategoryGrid.rows(
            kind: .closed,
            categories: categories,
            columnCount: columnCount
        )

        // Then
        #expect(rows.flatMap(\.categories) == categories)
    }

    /// 驗證類別分成多列時，各列的識別值由組別種類與從零起算的列序號組成
    @Test
    @MainActor
    func rows_多段類別_列識別值為組別與段序號() {
        // Given
        let categories = ["美妝", "3C", "零食", "書籍"]
        let columnCount = 3

        // When
        let rows = OrderCategoryGrid.rows(
            kind: .closed,
            categories: categories,
            columnCount: columnCount
        )

        // Then
        #expect(
            rows.map(\.id) == [
                OrderCategoryGrid.RowID(kind: .closed, index: 0),
                OrderCategoryGrid.RowID(kind: .closed, index: 1),
            ]
        )
    }

    /// 驗證欄數為一時，每個類別各自獨立成列，且沒有佔位格
    @Test
    @MainActor
    func rows_單欄_每個類別獨立一列() {
        // Given
        let categories = ["美妝", "3C"]
        let columnCount = 1

        // When
        let rows = OrderCategoryGrid.rows(
            kind: .ongoing,
            categories: categories,
            columnCount: columnCount
        )

        // Then
        #expect(rows.map { $0.categories.count } == [1, 1])
        #expect(rows.map(\.placeholderCount) == [0, 0])
    }

    /// 驗證類別清單為空時，切段後不產生任何列
    @Test
    @MainActor
    func rows_類別清單為空_回傳空陣列() {
        // Given
        let categories: [String] = []
        let columnCount = 3

        // When
        let rows = OrderCategoryGrid.rows(
            kind: .ongoing,
            categories: categories,
            columnCount: columnCount
        )

        // Then
        #expect(rows.isEmpty)
    }
}

// MARK: - Nested Types

extension OrderCategoryGridTests {

    /// `columnCount` 參數化測試的單一案例，含寬度、最小格寬、間距、是否無障礙字級與預期欄數
    struct ColumnCase: Sendable {

        /// 列的可用寬度
        let width: CGFloat

        /// 最小格寬
        let minimumCellWidth: CGFloat

        /// 格子間距
        let spacing: CGFloat

        /// 是否為無障礙字級
        let isAccessibilitySize: Bool

        /// 預期欄數
        let expectedColumns: Int
    }

    /// `rows` 三欄切段測試的單一案例，含待切段的類別與各列的格數、佔位格數
    struct RowSplitCase: Sendable {

        /// 可見類別
        let categories: [String]

        /// 每列的類別格數
        let expectedCells: [Int]

        /// 每列的佔位格數
        let expectedPlaceholders: [Int]
    }
}
