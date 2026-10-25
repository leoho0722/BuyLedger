//
//  CampaignFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFormatters` 的單元測試，預期值以字面值比對
struct CampaignFormattersTests {

    /// 驗證交貨進度以斜線連接已到貨與進行中的筆數，已到貨在前，例如 2/5
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

    /// 驗證沒有進行中訂單時，交貨進度仍顯示 0/0
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

    /// 驗證已收比例為一半時，依傳入的 locale 顯示無小數位的百分比，英文為 50%
    @Test
    func receivedRatioText_已收一半_顯示無小數位百分比() {
        // Given
        let ratio = 0.5

        // When
        let text = CampaignFormatters.receivedRatioText(ratio, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "50%")
    }

    /// 驗證已收比例帶小數時，百分比四捨五入為整數，例如 0.654 顯示 65%
    @Test
    func receivedRatioText_小數比例_四捨五入為整數百分比() {
        // Given
        let ratio = 0.654

        // When
        let text = CampaignFormatters.receivedRatioText(ratio, locale: AppLanguage.english.locale)

        // Then
        #expect(text == "65%")
    }

    /// 驗證不顯示開團日期 (`isShowing` 為 `false`) 時，`openDateText` 回傳 `nil`
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

    /// 驗證顯示開團日期時，依傳入的 locale 呈現月日與星期，英文 locale 下 2026/3/1 為「Mar 1 Sun」
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
