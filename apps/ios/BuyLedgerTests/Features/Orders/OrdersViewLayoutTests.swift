//
//  OrdersViewLayoutTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/3.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersView` 的單元測試，涵蓋尺寸分類對清單排列的判斷
struct OrdersViewLayoutTests {

    /// 驗證缺少尺寸分類時退回單欄，清單與詳情仍可由原生返回到達
    @Test
    func usesRegularList_缺少尺寸分類_退回單欄() {
        // Given
        let horizontalSizeClass: UserInterfaceSizeClass? = nil

        // When
        let isRegularList = OrdersView.usesRegularList(horizontalSizeClass: horizontalSizeClass)

        // Then
        #expect(isRegularList == false)
    }

    /// 驗證水平 compact 時採單欄，詳情改為推入而不並排
    @Test
    func usesRegularList_水平compact_採單欄() {
        // Given
        let horizontalSizeClass: UserInterfaceSizeClass? = .compact

        // When
        let isRegularList = OrdersView.usesRegularList(horizontalSizeClass: horizontalSizeClass)

        // Then
        #expect(isRegularList == false)
    }

    /// 驗證水平 regular 時採並排，清單與詳情同時可見
    @Test
    func usesRegularList_水平regular_採並排() {
        // Given
        let horizontalSizeClass: UserInterfaceSizeClass? = .regular

        // When
        let isRegularList = OrdersView.usesRegularList(horizontalSizeClass: horizontalSizeClass)

        // Then
        #expect(isRegularList)
    }
}
