//
//  CampaignFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團畫面的格式化輸出，預期值以字面值比對
struct CampaignFormattersTests {

    /// 已到貨與進行中的筆數以斜線連接
    @Test
    func deliveryProgress_已到貨與進行中_以斜線連接() {
        // Given
        let arrived = 2
        let active = 5

        // When
        let text = CampaignFormatters.deliveryProgress(arrived: arrived, active: active)

        // Then
        #expect(text == "2/5")
    }

    /// 沒有進行中訂單時仍顯示零比零
    @Test
    func deliveryProgress_沒有進行中訂單_顯示零比零() {
        // Given
        let arrived = 0
        let active = 0

        // When
        let text = CampaignFormatters.deliveryProgress(arrived: arrived, active: active)

        // Then
        #expect(text == "0/0")
    }

    /// 已收比例為一半時依 locale 顯示無小數位的百分比
    @Test
    func receivedRatioText_已收一半_顯示無小數位百分比() {
        // Given
        let ratio = 0.5

        // When
        let text = CampaignFormatters.receivedRatioText(ratio, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "50%")
    }

    /// 已收比例的小數尾數四捨五入後只保留整數百分比
    @Test
    func receivedRatioText_小數比例_四捨五入為整數百分比() {
        // Given
        let ratio = 0.654

        // When
        let text = CampaignFormatters.receivedRatioText(ratio, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "65%")
    }

    /// 不顯示開團日期時回傳空值
    @Test
    func openDateText_不顯示開團日期_回傳空值() {
        // Given
        let date = Date(timeIntervalSince1970: 1_772_366_400)

        // When
        let text = CampaignFormatters.openDateText(
            date,
            isShowing: false,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(text == nil)
    }

    /// 顯示開團日期時依 locale 呈現月日與星期
    @Test
    func openDateText_顯示開團日期_回傳月日與星期() {
        // Given
        let date = Date(timeIntervalSince1970: 1_772_366_400)

        // When
        let text = CampaignFormatters.openDateText(
            date,
            isShowing: true,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(text == "Mar 1 Sun")
    }
}
