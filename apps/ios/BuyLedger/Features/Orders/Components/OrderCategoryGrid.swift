//
//  OrderCategoryGrid.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import SwiftUI

/// 依組別分段的類別格子，產出放進宿主 `List` 的 `Section` 內容，不自帶捲動容器
struct OrderCategoryGrid: View {

    // MARK: - Properties

    /// 判斷無障礙字級，無障礙字級固定單欄
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 組標題與摘要文字的語言
    @Environment(\.locale) private var locale

    /// 最小格寬的基準點數，依 Dynamic Type 縮放
    @ScaledMetric(relativeTo: .body) private var minimumCellWidth: CGFloat = 96

    /// 列容器量到的寬度，量到前使用宿主傳入的初始欄數
    @State private var measuredWidth: CGFloat?

    /// 各組目前的顯示資料
    let groups: [OrderCategoryGroups.Display]

    /// 量到寬度前使用的欄數，由宿主依版面傳入 (iPhone 3、iPad 4)
    let initialColumnCount: Int

    /// 點選類別格的回呼，參數為類別名稱
    let onCategoryTapped: (String) -> Void

    /// 點選組標題的回呼，參數為組別種類
    let onGroupTapped: (OrderCategoryGroups.Kind) -> Void

    /// 目前已選取的類別集合
    let selected: Set<String>

    // MARK: - Body

    /// 每組一個 `Section`，組內每段一列
    var body: some View {
        ForEach(groups) {
            groupSection($0)
        }
    }
}

// MARK: - Private Views

private extension OrderCategoryGrid {

    /// 建立單一分組並只計算一次格子列
    ///
    /// - Parameter group: 分組的顯示資料
    /// - Returns: 含組標題與格子列的區段
    func groupSection(_ group: OrderCategoryGroups.Display) -> some View {
        let rows = Self.rows(
            kind: group.kind,
            categories: group.visibleCategories,
            columnCount: resolvedColumnCount
        )
        return Section {
            ForEach(rows) {
                gridRow($0, rowCount: rows.count)
            }
        } header: {
            groupHeader(group)
        }
    }

    /// 一段格子列，量測列容器寬度供欄數計算；相鄰段之間的垂直間距為 `BLSpacing.small`，組的首尾留較大的內距
    ///
    /// - Parameters:
    ///   - row: 要呈現的段落
    ///   - rowCount: 同組的段數
    /// - Returns: 單一 `Grid` 列
    func gridRow(_ row: Row, rowCount: Int) -> some View {
        Grid(horizontalSpacing: BLSpacing.small, verticalSpacing: BLSpacing.small) {
            GridRow {
                ForEach(row.categories, id: \.self) {
                    categoryCell($0)
                }

                ForEach(0..<row.placeholderCount, id: \.self) { _ in
                    Color.clear
                        .gridCellUnsizedAxes(.vertical)
                        .accessibilityHidden(true)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: {
            measuredWidth = $0
        }
        // List 列設定須在最外層，不可依四組順序前移
        .listRowInsets(.top, row.id.index == 0 ? BLSpacing.medium : BLSpacing.extraSmall)
        .listRowInsets(
            .bottom,
            row.id.index == rowCount - 1 ? BLSpacing.medium : BLSpacing.extraSmall
        )
        .listRowSeparator(.hidden)
    }

    /// 單一類別格，選中時加淡色底、外框與文字左側置中的勾號
    ///
    /// - Parameter category: 類別名稱
    /// - Returns: 可獨立點選的格子按鈕
    func categoryCell(_ category: String) -> some View {
        let isSelected = selected.contains(category)
        return Button {
            onCategoryTapped(category)
        } label: {
            HStack(alignment: .center, spacing: BLSpacing.small) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blAccent)
                        .accessibilityHidden(true)
                }

                Text(category)
                    .multilineTextAlignment(.center)
            }
            .padding(BLSpacing.small)
            .frame(maxWidth: .infinity, minHeight: BLHitTarget.minimum)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isSelected ? Color.blAccent.opacity(0.18) : .blFillTertiary,
                in: RoundedRectangle(cornerRadius: BLRadius.small)
            )
            .overlay {
                RoundedRectangle(cornerRadius: BLRadius.small)
                    .stroke(isSelected ? .blAccent : Color.clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: BLRadius.small))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(BLAccessibilityID.Orders.categoryCell(category))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 組標題按鈕，顯示展開箭頭、組名與數量，有選取時加上已選數膠囊
    ///
    /// - Parameter group: 組別的顯示資料
    /// - Returns: 可切換展開狀態的標題
    func groupHeader(_ group: OrderCategoryGroups.Display) -> some View {
        let language = AppLanguage(locale: locale)
        let title = language.localizedString(
            forKey: "orders.filter.label.groupHeader",
            groupName(group.kind, language: language),
            group.displayedCount
        )
        return Button {
            onGroupTapped(group.kind)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Image(systemName: group.isExpanded ? "chevron.down" : "chevron.right")
                    .accessibilityHidden(true)

                Text(title)

                Spacer()

                if group.selectedCount > 0 {
                    BLStatusPill(
                        language.localizedString(
                            forKey: "orders.filter.label.selectedCount",
                            group.selectedCount
                        ),
                        tone: .accent,
                        showsIndicator: false
                    )
                    .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, minHeight: BLHitTarget.minimum, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Orders.categoryGroupHeader(group.kind.rawValue))
        .accessibilityValue(
            group.isExpanded
                ? language.localized("orders.filter.label.groupExpanded")
                : language.localized("orders.filter.label.groupCollapsed")
        )
    }
}

// MARK: - Nested Types

extension OrderCategoryGrid {

    /// 列的識別值，由組別種類與段序號組成
    struct RowID: Hashable {

        /// 組別種類
        let kind: OrderCategoryGroups.Kind

        /// 段序號，從 0 起算
        let index: Int
    }

    /// 一段格子，`placeholderCount` 為補齊整列的透明佔位格數
    struct Row: Equatable, Identifiable {

        /// 列的識別值
        let id: RowID

        /// 該段的類別名稱，依原順序排列
        let categories: [String]

        /// 補齊欄數的透明佔位格數
        let placeholderCount: Int
    }
}

// MARK: - Internal Method

extension OrderCategoryGrid {

    /// 依寬度、最小格寬與間距計算欄數，無障礙字級固定單欄
    ///
    /// - Parameters:
    ///   - width: 列容器的可用寬度
    ///   - minimumCellWidth: 單格的最小寬度
    ///   - spacing: 格子之間的間距
    ///   - isAccessibilitySize: 是否為無障礙字級
    /// - Returns: 欄數，至少為 1
    static func columnCount(
        width: CGFloat,
        minimumCellWidth: CGFloat,
        spacing: CGFloat,
        isAccessibilitySize: Bool
    ) -> Int {
        guard !isAccessibilitySize else {
            return 1
        }
        let step = minimumCellWidth + spacing
        guard step > 0 else {
            return 1
        }
        let fitting = ((width + spacing) / step).rounded(.down)
        guard fitting.isFinite else {
            return 1
        }
        return max(1, Int(fitting))
    }

    /// 將一組類別依欄數切段，最後一段補齊佔位格
    ///
    /// - Parameters:
    ///   - kind: 組別種類
    ///   - categories: 可見類別，依原順序排列
    ///   - columnCount: 欄數
    /// - Returns: 依序的段落，沒有類別時為空陣列
    static func rows(
        kind: OrderCategoryGroups.Kind,
        categories: [String],
        columnCount: Int
    ) -> [Row] {
        guard columnCount > 0 else {
            return []
        }
        var rows: [Row] = []
        var start = 0
        while start < categories.count {
            let end = min(start + columnCount, categories.count)
            rows.append(
                Row(
                    id: RowID(kind: kind, index: rows.count),
                    categories: Array(categories[start..<end]),
                    placeholderCount: columnCount - (end - start)
                )
            )
            start = end
        }
        return rows
    }
}

// MARK: - Private Method

private extension OrderCategoryGrid {

    /// 實際採用的欄數：量到寬度後依寬度計算，量到前無障礙字級為單欄、其餘用初始欄數
    var resolvedColumnCount: Int {
        guard let measuredWidth else {
            return dynamicTypeSize.isAccessibilitySize ? 1 : initialColumnCount
        }
        return Self.columnCount(
            width: measuredWidth,
            minimumCellWidth: minimumCellWidth,
            spacing: BLSpacing.small,
            isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
        )
    }

    /// 組別的本地化名稱
    ///
    /// - Parameters:
    ///   - kind: 組別種類
    ///   - language: 顯示語言
    /// - Returns: 組名
    func groupName(_ kind: OrderCategoryGroups.Kind, language: AppLanguage) -> String {
        switch kind {
        case .ongoing:
            language.localized("common.general.label.active")

        case .closed:
            language.localized("common.general.label.closed")
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        OrderCategoryGrid(
            groups: [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: ["美妝", "3C", "零食", "書籍"],
                    displayedCount: 4,
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
            ],
            initialColumnCount: 3,
            onCategoryTapped: { _ in
            },
            onGroupTapped: { _ in
            },
            selected: ["美妝"]
        )
    }
    .listStyle(.insetGrouped)
    .environment(\.locale, AppLanguage.traditionalChinese.locale)
}
