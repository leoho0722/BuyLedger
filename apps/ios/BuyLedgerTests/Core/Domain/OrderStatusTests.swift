//
//  OrderStatusTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderStatus` 的單元測試，涵蓋顯示文字與分組
struct OrderStatusTests {

    /// 驗證合併狀態使用固定的 `merged` 儲存值，避免既有資料無法讀回
    @Test
    func rawValue_合併狀態_儲存值為合併() {
        // Given

        // When
        let rawValue = OrderStatus.merged.rawValue

        // Then
        #expect(rawValue == "merged")
    }

    /// 驗證合併狀態的顯示文字，使用訂單清單的合併本地化鍵
    @Test
    func title_合併狀態_顯示合併鍵() {
        // Given

        // When
        let title = OrderStatus.merged.title

        // Then
        #expect(title == "orders.list.label.merged")
    }

    /// 驗證 `allCases` 的宣告順序中，合併狀態位於已取消之後
    ///
    /// - Throws: 狀態清單缺少預期 case 時丟出測試錯誤
    @Test
    func allCases_合併狀態_排在已取消之後() throws {
        // Given
        let allCases = OrderStatus.allCases

        // When
        let mergedIndex = try #require(allCases.firstIndex(of: .merged))
        let cancelledIndex = try #require(allCases.firstIndex(of: .cancelled))

        // Then
        #expect(mergedIndex > cancelledIndex)
    }

    /// 驗證 `realizedStatuses` 不含合併狀態，且依序為明列的七種狀態
    @Test
    func realizedStatuses_合併狀態_不計入已實現狀態() {
        // Given

        // When
        let realizedStatuses = OrderStatus.realizedStatuses

        // Then
        #expect(!realizedStatuses.contains(.merged))
        #expect(
            realizedStatuses
                == [
                    .confirmed,
                    .purchased,
                    .shipping,
                    .partiallyArrived,
                    .arrived,
                    .delivered,
                    .pickedUp,
                ]
        )
    }

    /// 驗證已取貨狀態使用固定的 `pickedUp` 儲存值，避免既有資料無法讀回
    @Test
    func rawValue_已取貨狀態_儲存值為已取貨() {
        // Given

        // When
        let rawValue = OrderStatus.pickedUp.rawValue

        // Then
        #expect(rawValue == "pickedUp")
    }

    /// 驗證已取貨狀態的顯示文字，沿用共用的已取貨本地化鍵
    @Test
    func title_已取貨狀態_顯示已取貨鍵() {
        // Given

        // When
        let title = OrderStatus.pickedUp.title

        // Then
        #expect(title == "common.general.label.pickedUp")
    }

    /// 驗證已取貨狀態屬於 `realizedStatuses`
    @Test
    func realizedStatuses_已取貨狀態_屬於已實現狀態() {
        // Given
        let realizedStatuses = OrderStatus.realizedStatuses

        // When
        let isRealized = realizedStatuses.contains(.pickedUp)

        // Then
        #expect(isRealized)
    }

    /// 驗證 `allCases` 的宣告順序中，已取貨位於已交付之後
    ///
    /// - Throws: 狀態清單缺少預期 case 時丟出測試錯誤
    @Test
    func allCases_已取貨狀態_排在已交付之後() throws {
        // Given
        let allCases = OrderStatus.allCases

        // When
        let pickedUpIndex = try #require(allCases.firstIndex(of: .pickedUp))
        let deliveredIndex = try #require(allCases.firstIndex(of: .delivered))

        // Then
        #expect(pickedUpIndex > deliveredIndex)
    }

    /// 驗證 `OrderStatusFilter.orderBrowsingCases` 包含已合併狀態，讓使用者能找到舊訂單
    @Test
    func orderBrowsingCases_狀態篩選_包含已合併() {
        // Given

        // When
        let browsingCases = OrderStatusFilter.orderBrowsingCases

        // Then
        #expect(browsingCases.contains(.status(.merged)))
    }
}
