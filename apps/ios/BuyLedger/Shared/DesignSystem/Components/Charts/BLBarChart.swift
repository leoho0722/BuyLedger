//
//  BLBarChart.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Charts
import SwiftUI

/// 使用設計系統主色的簡潔長條圖
///
/// X 軸採用類別軸，標籤天生對齊在各自長條的 band 上；標籤過多時會依可用寬度等間隔抽稀，
/// 只在會重疊時才稀疏。啟用捲動後，內容比視窗寬時改用水平 `ScrollView`，
/// 並以 `.defaultScrollAnchor(.trailing)` 預設停在最右端 (最新資料)
struct BLBarChart: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 長條圖要呈現的資料
    let data: [BLBarChartValue]

    /// 圖表高度
    var height: CGFloat = 180

    /// 是否啟用水平捲動 (預設關閉，維持靜態呼叫者與 Preview 行為)
    var isScrollEnabled: Bool = false

    /// 單一 X 軸標籤的最小水平間距 (caption2 下 YY/MM 約略寬度)，決定標籤過多時的抽稀門檻
    private let minLabelSpacing: CGFloat = 28

    /// 啟用捲動時，單一長條的最小可視寬度。設為略大於最寬標籤 (MM/dd)，
    /// 讓每個可視長條都有空間顯示自己的標籤 (逐筆不抽稀)，且標籤落在自身 band 內、捲到邊緣也不截斷
    private let minBarSpacing: CGFloat = 44

    // MARK: - View Body

    /// 長條圖的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        GeometryReader { proxy in
            chart(palette: palette, viewportWidth: proxy.size.width)
        }
        .frame(height: height)
    }
}

// MARK: - ViewBuilder

private extension BLBarChart {

    /// 依目前可用寬度繪製長條圖。內容比視窗寬時 (例如 30 天逐日、12 個月)，改用水平 `ScrollView`
    /// 並以 `.defaultScrollAnchor(.trailing)` 預設停在最右；此錨點在內容尺寸變動時會重新定位，
    /// 因此不受卡片寬度尚未定案的 layout 時序影響
    /// - Parameters:
    ///   - palette: 目前外觀使用的色盤
    ///   - viewportWidth: `GeometryReader` 量到的可用寬度
    @ViewBuilder
    func chart(palette: BLPalette, viewportWidth: CGFloat) -> some View {
        let total = data.count
        let visibleCount = visibleBarCount(total: total, viewportWidth: viewportWidth)

        if isScrollEnabled, total > visibleCount, viewportWidth > 0 {
            // 內容寬度讓每根長條維持最小寬度，其餘以水平捲動瀏覽，預設停在最右端 (最新)
            let contentWidth = viewportWidth * CGFloat(total) / CGFloat(visibleCount)

            ScrollView(.horizontal, showsIndicators: false) {
                barChart(palette: palette, renderWidth: contentWidth)
                    .frame(width: contentWidth)
            }
            .defaultScrollAnchor(.trailing)
        } else {
            barChart(palette: palette, renderWidth: viewportWidth)
        }
    }

    /// 建構長條圖本體；X 軸標籤依 `renderWidth` 抽稀，只在會重疊時稀疏
    /// - Parameters:
    ///   - palette: 目前外觀使用的色盤
    ///   - renderWidth: 圖表實際繪製寬度 (捲動時為內容寬度，否則為視窗寬度)
    @ViewBuilder
    func barChart(palette: BLPalette, renderWidth: CGFloat) -> some View {
        let axisLabels = stridedLabels(renderWidth: renderWidth)

        Chart(Array(data.enumerated()), id: \.offset) { _, item in
            BarMark(
                x: .value("日期", item.label),
                y: .value("金額", item.value)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .foregroundStyle(palette.accent.gradient)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: axisLabels) { _ in
                AxisValueLabel()
                    .foregroundStyle(palette.tertiaryLabel)
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Private Method

private extension BLBarChart {

    /// 計算一個視窗內可容納的長條數 (用來決定捲動時的內容寬度)
    /// - Parameters:
    ///   - total: 資料總筆數
    ///   - viewportWidth: 可用寬度
    /// - Returns: 介於 `1...total` 的可視長條數
    func visibleBarCount(total: Int, viewportWidth: CGFloat) -> Int {
        guard isScrollEnabled, total > 0, viewportWidth > 0 else {
            return max(total, 1)
        }
        let capacity = max(1, Int(viewportWidth / minBarSpacing))
        return min(total, capacity)
    }

    /// 依實際繪製寬度算出 X 軸要顯示哪些標籤 (等間隔抽稀，並永遠補上最後一筆作為右端錨點)
    /// 捲動時內容夠寬 → 不抽稀、逐筆顯示；不捲動且長條過密時才稀疏
    /// - Parameter renderWidth: 圖表實際繪製寬度
    /// - Returns: 要繪製標籤的標籤子集；資料為空時回傳空陣列
    func stridedLabels(renderWidth: CGFloat) -> [String] {
        let total = data.count
        guard total > 0 else { return [] }

        let capacity = max(1, Int(renderWidth / minLabelSpacing))
        let stride = max(1, Int((Double(total) / Double(capacity)).rounded(.up)))

        var indices = Array(Swift.stride(from: 0, to: total, by: stride))
        // 補上最後一筆作為右端錨點；若與前一個抽樣點太近 (< stride) 則取代而非附加，避免兩個標籤重疊
        if let last = indices.last, last != total - 1 {
            if total - 1 - last < stride {
                indices[indices.count - 1] = total - 1
            } else {
                indices.append(total - 1)
            }
        }
        return indices.map { data[$0].label }
    }
}

// MARK: - Preview

#Preview("長條圖") {
    BLBarChart(
        data: [
            BLBarChartValue(label: "1月", value: 82),
            BLBarChartValue(label: "2月", value: 126),
            BLBarChartValue(label: "3月", value: 96),
            BLBarChartValue(label: "4月", value: 142),
        ]
    )
    .padding()
}

#Preview("30 天逐日 (可捲動)") {
    let calendar = Calendar(identifier: .gregorian)
    let base = Date(timeIntervalSince1970: 1_777_500_000)
    let data = (0..<30).reversed().compactMap { offset -> BLBarChartValue? in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: base) else {
            return nil
        }
        return BLBarChartValue(
            label: day.formatted(
                .verbatim(
                    "\(month: .twoDigits)/\(day: .twoDigits)",
                    timeZone: calendar.timeZone,
                    calendar: calendar
                )
            ),
            value: Double((offset * 37) % 160 + 20)
        )
    }

    BLBarChart(data: data, height: 200, isScrollEnabled: true)
        .padding()
}
