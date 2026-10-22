//
//  DashboardFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證總覽頁的格式化輸出，預期值以字面值比對
struct DashboardFormattersTests {

    /// 獲利為正數時在新台幣金額前加上正號，繁體中文環境的金額前綴為 `$`
    @Test
    func signedProfit_正數獲利_繁體中文加上正號() {
        // Given
        let profit: Decimal = 1_234

        // When
        let text = DashboardFormatters.signedProfit(
            profit,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "+$1,234")
    }

    /// 獲利為零時不加正號，英文環境的金額前綴為 `NT$`
    @Test
    func signedProfit_零值_英文不加正號() {
        // Given
        let profit: Decimal = 0

        // When
        let text = DashboardFormatters.signedProfit(profit, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "NT$0")
    }

    /// 獲利為負數時保留負號，且不加正號
    @Test
    func signedProfit_負數獲利_英文保留負號() {
        // Given
        let profit: Decimal = -567

        // When
        let text = DashboardFormatters.signedProfit(profit, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "-NT$567")
    }

    /// 上月沒有可比較的數值時，獲利變化顯示破折號加上 MoM
    @Test
    func profitDelta_無上月資料_顯示破折號() {
        // Given
        let delta: Decimal? = nil

        // When
        let text = DashboardFormatters.profitDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "— MoM")
    }

    /// 獲利變化為零時箭頭為上升，因為零被歸類為大於或等於零
    @Test
    func profitDelta_零成長_箭頭為上升() {
        // Given
        let delta: Decimal = 0

        // When
        let text = DashboardFormatters.profitDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "↑ 0.0% MoM")
    }

    /// 正成長時顯示上升箭頭、一位小數的百分比與 MoM
    @Test
    func profitDelta_正成長_顯示上升箭頭與百分比() {
        // Given
        let delta: Decimal = 0.243

        // When
        let text = DashboardFormatters.profitDelta(
            delta,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "↑ 24.3% MoM")
    }

    /// 負成長時顯示下降箭頭，百分比取絕對值
    @Test
    func profitDelta_負成長_顯示下降箭頭與絕對值() {
        // Given
        let delta: Decimal = -0.5

        // When
        let text = DashboardFormatters.profitDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "↓ 50.0% MoM")
    }

    /// KPI 變化率沒有上月資料時顯示破折號加上 MoM
    @Test
    func percentDelta_無上月資料_顯示破折號() {
        // Given
        let delta: Decimal? = nil

        // When
        let text = DashboardFormatters.percentDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "— MoM")
    }

    /// KPI 正成長時百分比前加上正號
    @Test
    func percentDelta_正成長_加上正號() {
        // Given
        let delta: Decimal = 0.182

        // When
        let text = DashboardFormatters.percentDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "+18.2% MoM")
    }

    /// KPI 負成長時保留負號，不加正號
    @Test
    func percentDelta_負成長_保留負號不加正號() {
        // Given
        let delta: Decimal = -0.123

        // When
        let text = DashboardFormatters.percentDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "-12.3% MoM")
    }

    /// KPI 變化率為零時加上正號，與大於零的情況相同
    @Test
    func percentDelta_零成長_加上正號() {
        // Given
        let delta: Decimal = 0

        // When
        let text = DashboardFormatters.percentDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "+0.0% MoM")
    }

    /// 毛利率沒有上月資料時顯示破折號加上 MoM，不顯示百分點單位
    @Test
    func marginDelta_無上月資料_顯示破折號() {
        // Given
        let delta: Decimal? = nil

        // When
        let text = DashboardFormatters.marginDelta(
            delta,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "— MoM")
    }

    /// 毛利率成長 0.024 時換算為 2.4 個百分點，前加正號並接上 pt MoM
    @Test
    func marginDelta_正百分點_換算為百分點並加上正號() {
        // Given
        let delta: Decimal = 0.024

        // When
        let text = DashboardFormatters.marginDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "+2.4 pt MoM")
    }

    /// 毛利率下降時保留負號，不加正號
    @Test
    func marginDelta_負百分點_保留負號() {
        // Given
        let delta: Decimal = -0.012

        // When
        let text = DashboardFormatters.marginDelta(delta, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "-1.2 pt MoM")
    }

    /// 進度過半時顯示整數百分比，後接目標金額
    @Test
    func goalProgress_進度過半_顯示整數百分比與目標金額() {
        // Given
        let progress: CGFloat = 0.5
        let goal: Decimal = 80_000

        // When
        let text = DashboardFormatters.goalProgress(
            progress,
            goal: goal,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "50% / $80,000")
    }

    /// 未設定目標時目標金額為零，進度也為零，英文環境金額前綴為 NT$
    @Test
    func goalProgress_未設定目標_顯示零() {
        // Given
        let progress: CGFloat = 0
        let goal: Decimal = 0

        // When
        let text = DashboardFormatters.goalProgress(
            progress,
            goal: goal,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(text == "0% / NT$0")
    }

    /// 達成目標時進度為一百，顯示 100%
    @Test
    func goalProgress_達成目標_顯示一百() {
        // Given
        let progress: CGFloat = 1.0
        let goal: Decimal = 1_000

        // When
        let text = DashboardFormatters.goalProgress(
            progress,
            goal: goal,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "100% / $1,000")
    }

    /// 到貨進度以已到貨與進行中數量以斜線連接
    @Test
    func deliveryProgress_已到貨與進行中_以斜線連接() {
        // Given
        let arrived = 2
        let active = 5

        // When
        let text = DashboardFormatters.deliveryProgress(arrived: arrived, active: active)

        // Then
        #expect(text == "2/5")
    }

    /// 沒有進行中訂單時顯示零比零
    @Test
    func deliveryProgress_沒有進行中訂單_顯示零比零() {
        // Given
        let arrived = 0
        let active = 0

        // When
        let text = DashboardFormatters.deliveryProgress(arrived: arrived, active: active)

        // Then
        #expect(text == "0/0")
    }
}
