//
//  InsightsCategoryCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 分析頁的類別排行卡，依獲利由高到低列出類別，點擊一列會通知呼叫端查看該類別的訂單
struct InsightsCategoryCard: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 依獲利由高到低排列的類別
    let categories: [InsightsCategory]

    /// 點擊類別列的動作，帶類別名稱
    let onCategoryTapped: (String) -> Void

    // MARK: - Body

    /// 卡片骨架，由上而下是標題與類別排行列，沒有類別資料時改顯示提示
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                title

                if categories.isEmpty {
                    emptyState
                } else {
                    rankRows
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension InsightsCategoryCard {

    /// 固定顯示「類別排行」的卡片標題
    var title: some View {
        Text("類別排行")
            .font(BLTypographyStyle.subhead.font.weight(.semibold))
            .foregroundStyle(palette.label)
    }

    /// 沒有類別資料時的提示
    var emptyState: some View {
        Text("尚無分類資料")
            .blTextStyle(.footnote)
            .foregroundStyle(palette.secondaryLabel)
    }

    /// 依獲利排行逐列顯示的類別，每列都可點擊
    var rankRows: some View {
        ForEach(Array(categories.enumerated()), id: \.element.name) { index, category in
            Button {
                onCategoryTapped(category.name)
            } label: {
                categoryRow(rank: index + 1, category: category, tint: tint(at: index))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("查看 \(category.name) 類別的訂單")
            .accessibilityValue(Text(BLFormatters.twd(category.profit, locale: locale)))
            .accessibilityIdentifier(
                BLAccessibilityID.Insights.categoryRankRow(category: category.name)
            )
        }
    }

    /// 類別排行單列：名次、類別名稱、獲利金額與相對於第一名的進度條
    ///
    /// - Parameters:
    ///   - rank: 名次，由 1 起算
    ///   - category: 類別資料
    ///   - tint: 進度條顏色
    /// - Returns: 類別列
    @ViewBuilder
    func categoryRow(rank: Int, category: InsightsCategory, tint: Color) -> some View {
        let value = NSDecimalNumber(decimal: category.profit).doubleValue
        let total = NSDecimalNumber(decimal: topProfit).doubleValue
        let fraction = total > 0 ? CGFloat(value / total) : 0

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(rank). \(category.name)")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)

                Spacer()

                Text(BLFormatters.twd(category.profit, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)

                Image(systemName: "chevron.right")
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.tertiaryLabel)
                    .accessibilityHidden(true)
            }

            ProgressView(value: min(max(fraction, 0), 1))
                .progressViewStyle(BLProgressViewStyle(tint: tint))
        }
    }
}

// MARK: - Private Method

private extension InsightsCategoryCard {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 進度條依排行順序循環使用的色盤序列
    var categoryTints: [Color] {
        [
            palette.accent,
            palette.purple,
            palette.orange,
            palette.teal,
            palette.pink,
        ]
    }

    /// 第一名類別的獲利，作為進度條比例的基準；沒有類別時為 1
    var topProfit: Decimal {
        categories.first?.profit ?? 1
    }

    /// 依排行順位取用循環色盤中的進度條顏色
    ///
    /// - Parameter index: 排行順位，由 0 起算
    /// - Returns: 該列進度條的顏色
    func tint(at index: Int) -> Color {
        categoryTints[index % categoryTints.count]
    }
}

// MARK: - Preview

#Preview("類別排行") {
    InsightsCategoryCard(categories: [
        InsightsCategory(name: "美妝保養", profit: 8_600),
        InsightsCategory(name: "服飾配件", profit: 5_200),
        InsightsCategory(name: "零食", profit: 1_900),
    ]) { _ in
    }
    .padding()
}

#Preview("無分類資料") {
    InsightsCategoryCard(categories: []) { _ in
    }
    .padding()
}
