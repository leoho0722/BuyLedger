//
//  InsightsHeatmapCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 分析頁的下單熱力圖卡，以過去 N 週的星期與週次格狀顯示每天的下單筆數
struct InsightsHeatmapCard: View {

    // MARK: - Properties

    /// 熱力圖單一格子的高度，隨字級縮放 (以 `.caption2` 為基準)
    @ScaledMetric(relativeTo: .caption2) private var heatmapCellHeight: CGFloat = 30

    /// 熱力圖左側星期欄寬，隨字級縮放 (以 `.caption` 為基準)
    @ScaledMetric(relativeTo: .caption) private var heatmapWeekdayColumnWidth: CGFloat = 28

    /// 每個週次與星期組合的下單筆數，沒有訂單的格子不在字典內
    let cells: [HeatmapKey: Int]

    /// 由週一起排列的 7 個星期縮寫，依 App 選定的語言呈現
    let weekdayLabels: [String]

    // MARK: - Body

    /// 卡片骨架，由上而下是標題與格狀熱力圖
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                title

                grid
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension InsightsHeatmapCard {

    /// 卡片標題，點明涵蓋的週數
    var title: some View {
        Text("下單熱力 · 過去 \(weekCount) 週")
            .font(BLTypographyStyle.subhead.font.weight(.semibold))
            .foregroundStyle(palette.label)
    }

    /// 週次標籤列最左側的空格，與星期欄對齊
    var cornerSpacer: some View {
        Text(" ")
            .frame(width: heatmapWeekdayColumnWidth)
    }

    /// 週次標籤列，W1 為最早的一週
    var weekLabels: some View {
        ForEach(0..<weekCount, id: \.self) {
            Text("W\($0 + 1)")
                .frame(maxWidth: .infinity)
                .blTextStyle(.caption2)
                .foregroundStyle(palette.secondaryLabel)
        }
    }

    /// 全部格子，依序排出每個星期的星期標籤與各週的熱力格
    var gridCells: some View {
        // 攤平成單層 ForEach，確保 LazyVGrid 正確建立 cell
        ForEach(0..<(7 * (weekCount + 1)), id: \.self) {
            cell(at: $0)
        }
    }

    /// 格狀熱力圖：第一列為週次標籤，其後每個星期一列，並附整圖的無障礙摘要
    var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            cornerSpacer

            weekLabels

            gridCells
        }
        // 整圖摘要：讓使用者不必逐格走過就能理解這張圖的範圍與規模
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("下單熱力圖，涵蓋過去 \(weekCount) 週，最高單日 \(maxCount) 單"))
    }

    /// 攤平後第 N 格的內容：每列第一格是星期標籤，其餘是熱力格
    ///
    /// - Parameter index: 攤平後的格子順位，由 0 起算
    /// - Returns: 星期標籤或熱力格
    @ViewBuilder
    func cell(at index: Int) -> some View {
        let weekday = index / (weekCount + 1)
        let column = index % (weekCount + 1)

        if column == 0 {
            weekdayColumnLabel(weekday)
        } else {
            heatmapCell(
                count: cells[HeatmapKey(week: column - 1, weekday: weekday)] ?? 0,
                weekdayLabel: weekdayLabels[weekday],
                week: column
            )
        }
    }

    /// 每列最左側的星期標籤
    ///
    /// - Parameter weekday: 0 為週一、6 為週日
    /// - Returns: 星期標籤
    func weekdayColumnLabel(_ weekday: Int) -> some View {
        Text(weekdayLabels[weekday])
            .frame(width: heatmapWeekdayColumnWidth, alignment: .leading)
            .blTextStyle(.caption)
            .foregroundStyle(palette.secondaryLabel)
    }

    /// 熱力圖單一格子，顏色深淺依訂單筆數相對於最高筆數而定
    ///
    /// - Parameters:
    ///   - count: 訂單筆數
    ///   - weekdayLabel: 星期縮寫，供無障礙朗讀
    ///   - week: 第幾週，由 1 起算，供無障礙朗讀
    /// - Returns: 熱力格
    @ViewBuilder
    func heatmapCell(count: Int, weekdayLabel: String, week: Int) -> some View {
        let depth = BLHeatmapDepth.depth(for: count, maxCount: maxCount)

        // 明確設定高度撐起格子，因為 `RoundedRectangle` 沒有 intrinsic size，
        // 在 LazyVGrid 中靠 `aspectRatio` 會被旁邊 Text 那列壓成 0 高度而完全不顯示
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(depth?.background ?? palette.fillQuaternary)
            .frame(maxWidth: .infinity)
            .frame(height: heatmapCellHeight)
            .overlay {
                if let depth {
                    Text("\(count)")
                        .font(BLTypographyStyle.caption2.font.weight(.semibold))
                        .foregroundStyle(depth.numeral)
                        .accessibilityHidden(true)
                }
            }
            // 排除零值格，避免朗讀沒有意義的數字，
            // 非零格子帶上「星期 + 第幾週」讓數字有座標可依附
            .accessibilityHidden(count == 0)
            .accessibilityLabel(Text("\(weekdayLabel) 第 \(week) 週"))
            .accessibilityValue(Text("\(count) 單"))
    }
}

// MARK: - Private Method

private extension InsightsHeatmapCard {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 熱力圖涵蓋的週數
    var weekCount: Int {
        InsightsStats.heatmapWeekCount
    }

    /// 整張熱力圖中最高的單日訂單筆數，沒有資料時為 1
    var maxCount: Int {
        cells.values.max() ?? 1
    }

    /// 格狀圖的欄配置：固定寬度的星期欄，加上每週一個等寬欄
    var columns: [GridItem] {
        [GridItem(.fixed(heatmapWeekdayColumnWidth), spacing: 6)]
            + Array(repeating: GridItem(.flexible(), spacing: 6), count: weekCount)
    }
}

// MARK: - Preview

#Preview("下單熱力圖") {
    InsightsHeatmapCard(
        cells: [
            HeatmapKey(week: 7, weekday: 0): 3,
            HeatmapKey(week: 7, weekday: 2): 1,
            HeatmapKey(week: 6, weekday: 4): 2,
            HeatmapKey(week: 4, weekday: 5): 5,
        ],
        weekdayLabels: ["一", "二", "三", "四", "五", "六", "日"]
    )
    .padding()
}
