//
//  SystemAccessibilityID.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/13.
//

/// 系統指定且 App 無法改名的無障礙識別碼，僅供 UI 測試定位
enum SystemAccessibilityID {

    // MARK: - Properties

    /// 系統指定且 App 無法改名的導覽返回按鈕識別碼
    static let backButton = "BackButton"

    /// 系統指定且 App 無法改名的 Popover 全螢幕關閉區域識別碼
    static let popoverDismissRegion = "PopoverDismissRegion"

    /// 系統指定且 App 無法改名的側邊欄切換按鈕識別碼，iPad 橫向觀測到的值
    static let sidebarToggleButton = "ToggleSidebar"

    /// 系統指定且 App 無法改名的側邊欄切換按鈕替代識別碼，iPad 直向觀測到的值
    static let sidebarToggleButtonAlternate = "ToggleSideBar"
}
