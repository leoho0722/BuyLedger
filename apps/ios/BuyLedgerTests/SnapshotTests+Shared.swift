//
//  SnapshotTests+Shared.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 長條圖放入 30 天資料並開啟捲動時，預設停在最新的一端，每根長條都標出日期
    @Test
    func blBarChart_近三十天資料_捲動停在最新日期() {
        TestDependencies.withFixedNow {
            // Given
            let calendar = TestDependencies.fixedCalendar
            let base = TestDependencies.fixedNow

            let bars: [BLBarChartValue] = (0..<30).reversed().compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: base) else {
                    return nil
                }
                let amount = (offset * 53) % 180 + 20
                return BLBarChartValue(
                    label: day.formatted(
                        .verbatim(
                            "\(month: .twoDigits)/\(day: .twoDigits)",
                            timeZone: calendar.timeZone,
                            calendar: calendar
                        )
                    ),
                    value: Double(amount),
                    valueDescription: "NT$\(amount)"
                )
            }

            // When
            let view = BLBarChart(data: bars, height: 200, isScrollEnabled: true)
                .frame(width: 393)
                .padding()

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 資料無法開啟時的阻斷畫面，顯示說明文字與「改用空白資料庫繼續」按鈕
    @Test
    func persistenceFailureView_持久化錯誤_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given

            // When
            let view = PersistenceFailureView(
                store: Store(initialState: PersistenceFailureFeature.State()) {
                    PersistenceFailureFeature()
                }
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            // 復原按鈕的 prominent 玻璃樣式在離屏渲染會整張變黑，改於 key window 渲染
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}
