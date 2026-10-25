//
//  SnapshotOrderCategoryGridTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderCategoryGrid` 的快照測試，涵蓋不同欄數、動態字級與選取狀態
@MainActor
struct SnapshotOrderCategoryGridTests {

    /// 驗證同一列含長名稱時，短名稱格與長名稱格等高，畫面符合基準圖
    @Test
    func orderCategoryGrid_長名稱同列等高_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let items = [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: [
                        "美妝",
                        "3C",
                        "零食",
                        "書籍",
                        "aespa Lemonade QQ 音樂限定禮包",
                    ],
                    displayedCount: 5,
                    selectedCount: 1,
                    isExpanded: true
                ),
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: [],
                    displayedCount: 2,
                    selectedCount: 0,
                    isExpanded: false
                ),
            ]

            // When
            let view = Self.categoryGridList(initialColumnCount: 3, groups: items, selected: ["美妝"])

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證組內只有一個類別時，格子仍保留一欄寬度，不撐滿整列，畫面符合基準圖
    @Test
    func orderCategoryGrid_單一類別保留一欄寬_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let groups = [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: ["美妝"],
                    displayedCount: 1,
                    selectedCount: 0,
                    isExpanded: true
                ),
            ]

            // When
            let view = Self.categoryGridList(initialColumnCount: 3, groups: groups, selected: [])

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證寬度 297 時類別格排為二欄 (比預設三欄少一欄)，畫面符合基準圖
    @Test
    func orderCategoryGrid_欄數減一_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let groups = [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: [
                        "美妝",
                        "3C",
                        "零食",
                        "書籍",
                        "aespa Lemonade QQ 音樂限定禮包",
                    ],
                    displayedCount: 5,
                    selectedCount: 1,
                    isExpanded: true
                ),
            ]

            // When
            let view = Self.categoryGridList(
                initialColumnCount: 2,
                groups: groups,
                selected: ["美妝"],
                width: 297
            )

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證無障礙字級時每個類別獨占一列，畫面符合基準圖
    @Test
    func orderCategoryGrid_無障礙字級單欄_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let groups = [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: [
                        "美妝",
                        "3C",
                        "零食",
                        "書籍",
                        "aespa Lemonade QQ 音樂限定禮包",
                    ],
                    displayedCount: 5,
                    selectedCount: 1,
                    isExpanded: true
                ),
            ]

            // When
            let view = Self.categoryGridList(
                initialColumnCount: 3,
                groups: groups,
                selected: ["美妝"],
                dynamicTypeSize: .accessibility3
            )

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotOrderCategoryGridTests {

    /// 以 `List` 宿主呈現類別格，寬度與 iPhone 篩選 sheet 的內容寬度相近
    ///
    /// - Parameters:
    ///   - initialColumnCount: 量到寬度前使用的欄數
    ///   - groups: 各組的顯示資料
    ///   - selected: 已選取的類別集合
    ///   - width: 宿主寬度
    ///   - dynamicTypeSize: 字級
    /// - Returns: 含類別格的宿主畫面
    static func categoryGridList(
        initialColumnCount: Int,
        groups: [OrderCategoryGroups.Display],
        selected: Set<String>,
        width: CGFloat = 393,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> some View {
        List {
            OrderCategoryGrid(
                groups: groups,
                initialColumnCount: initialColumnCount,
                onCategoryTapped: { _ in
                },
                onGroupTapped: { _ in
                },
                selected: selected
            )
        }
        .listStyle(.insetGrouped)
        .environment(\.locale, AppLanguage.traditionalChinese.locale)
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        .frame(width: width, height: 480)
    }
}
