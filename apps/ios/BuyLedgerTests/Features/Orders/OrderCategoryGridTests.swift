//
//  OrderCategoryGridTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

@testable import BuyLedger

/// 類別格子的欄數計算與段落切分
struct OrderCategoryGridTests {

    // MARK: - Properties

    /// 最小格寬 96pt、間距 8pt 時，寬度對應的欄數；無障礙字級固定單欄
    static let columnCases: [ColumnCase] = [
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

    /// 三欄切段的測試案例清單
    static let rowSplitCases: [RowSplitCase] = [
        RowSplitCase(categories: ["美妝"], expectedCells: [1], expectedPlaceholders: [2]),
        RowSplitCase(categories: ["美妝", "3C"], expectedCells: [2], expectedPlaceholders: [1]),
        RowSplitCase(categories: ["美妝", "3C", "零食"], expectedCells: [3], expectedPlaceholders: [0]),
        RowSplitCase(
            categories: ["美妝", "3C", "零食", "書籍"],
            expectedCells: [3, 1],
            expectedPlaceholders: [0, 2]
        ),
    ]

    /// 依寬度、最小格寬與間距回報欄數，無障礙字級固定單欄
    ///
    /// - Parameter columnCase: 寬度與格寬測試案例
    @Test(arguments: OrderCategoryGridTests.columnCases)
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

    /// 三欄時依類別數切段，最後一段補齊佔位格
    ///
    /// - Parameter splitCase: 切段測試案例
    @Test(arguments: OrderCategoryGridTests.rowSplitCases)
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

    /// 切段後依原順序展開，不遺漏也不重複類別
    @Test
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

    /// 多段類別時，列識別值為組別種類與段序號
    @Test
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

    /// 無障礙單欄時，每個類別獨立一列且沒有佔位格
    @Test
    func rows_無障礙單欄_每個類別獨立一列() {
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

    /// 類別清單為空時回傳空陣列
    @Test
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

    /// 寬度對應欄數的測試案例
    struct ColumnCase: Sendable {

        /// 列容器寬度
        let width: CGFloat

        /// 最小格寬
        let minimumCellWidth: CGFloat

        /// 格子間距
        let spacing: CGFloat

        /// 是否為無障礙字級
        let isAccessibilitySize: Bool

        /// 規格對應的欄數
        let expectedColumns: Int
    }

    /// 三欄切段的測試案例
    struct RowSplitCase: Sendable {

        /// 可見類別
        let categories: [String]

        /// 每段的類別數
        let expectedCells: [Int]

        /// 每段的佔位格數
        let expectedPlaceholders: [Int]
    }
}
