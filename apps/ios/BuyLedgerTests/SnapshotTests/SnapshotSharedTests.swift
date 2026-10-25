//
//  SnapshotSharedTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `BLBarChart`、`PersistenceFailureView`、`PaymentMethodEditorSheet` 與 `AISummaryView` 的快照測試，涵蓋共用元件
@MainActor
struct SnapshotSharedTests {

    /// 驗證長條圖放入 30 天資料並開啟捲動時，預設停在最新的一端，每根長條都標出日期，畫面符合基準圖
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

    /// 驗證資料無法開啟時，阻斷畫面顯示說明文字與「改用空白資料庫繼續」按鈕，畫面符合基準圖
    ///
    /// - Note: 復原按鈕的 prominent 玻璃樣式在離屏渲染會整張變黑，改於 key window 渲染
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
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證新增付款方式的表單以空白名稱開啟，名稱為空時新增鈕停用，畫面符合基準圖
    ///
    /// - Note: 表單以獨立 sheet 呈現並自帶 `NavigationStack`
    /// - Note: 新增鈕為 `.borderedProminent`，於 key window 渲染
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    @Test
    func paymentMethodEditorSheet_新增付款方式_顯示空白表單() {
        TestDependencies.withFixedNow {
            // Given

            // When
            let view = PaymentMethodEditorSheet(
                title: "orders.edit.label.addPaymentMethod",
                message: "orders.lookup.message.enterNewPayment",
                namePlaceholder: "orders.detail.label.paymentMethodName",
                submitTitle: "orders.list.button.add",
                isEmbedded: false
            ) { _, _, _, _ in
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證編輯既有付款方式時帶入名稱與三種旗標，三個開關皆為開啟且儲存鈕可用，畫面符合基準圖
    ///
    /// - Note: 名稱非空，儲存鈕為可用狀態
    /// - Note: 表單以獨立 sheet 呈現，於 key window 渲染
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    @Test
    func paymentMethodEditorSheet_編輯既有付款方式_顯示三種旗標() {
        TestDependencies.withFixedNow {
            // Given

            // When
            let view = PaymentMethodEditorSheet(
                title: "orders.lookup.label.editPaymentMethod",
                message: "orders.lookup.message.editNameTags",
                namePlaceholder: "orders.detail.label.paymentMethodName",
                submitTitle: "orders.edit.button.save",
                initialName: "信用卡",
                isInitialCardless: true,
                isInitialBankTransfer: true,
                isInitialCashOnDelivery: true,
                isEmbedded: false
            ) { _, _, _, _ in
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證 AI 總結完成後顯示 Markdown 格式的摘要內容，底部附 AI 免責膠囊，畫面符合基準圖
    ///
    /// - Note: 基準只涵蓋 `.finished` 與 `.failed`
    /// - Note: `.idle`、`.streaming` 顯示進度轉圈，不是靜態畫面，因此不列入基準
    /// - Note: 使用 `EmptyReducer`，`.task` 不會觸發 `AISummaryService`
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    @Test
    func aiSummaryView_總結完成_顯示摘要內容() {
        TestDependencies.withFixedNow {
            // Given
            var state = AISummaryFeature.State(prompt: "範例 prompt", model: "gemma4:31b-cloud")
            state.phase = .finished
            state.summaryText = "# 商品摘要\n\n已取得的部分內容"

            // When
            let view = AISummaryView(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證 AI 總結失敗時顯示失敗說明與重試鈕，不顯示摘要內容，畫面符合基準圖
    ///
    /// - Note: 重試鈕為 `.borderedProminent`，於 key window 渲染
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    @Test
    func aiSummaryView_總結失敗_顯示重試鈕() {
        TestDependencies.withFixedNow {
            // Given
            var state = AISummaryFeature.State(prompt: "範例 prompt", model: "gemma4:31b-cloud")
            state.phase = .failed
            state.errorMessage = "ai.summary.message.summaryFailedTry"

            // When
            let view = AISummaryView(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}
