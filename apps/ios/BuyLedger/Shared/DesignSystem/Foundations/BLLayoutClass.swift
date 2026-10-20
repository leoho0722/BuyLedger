//
//  BLLayoutClass.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/4.
//

import SwiftUI

/// 依視窗的水平與垂直尺寸分類決定共用版面
enum BLLayoutClass: Equatable, Sendable {

    /// 任一方向為緊湊或未提供尺寸分類時使用的窄版
    case compact

    /// 水平與垂直尺寸分類都為常規時使用的寬版
    case regular

    // MARK: - Init

    /// 建立尺寸分類對應的版面，只有雙向常規時使用寬版
    ///
    /// - Parameters:
    ///   - horizontal: 水平尺寸分類，未提供時為 `nil`
    ///   - vertical: 垂直尺寸分類，未提供時為 `nil`
    init(horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?) {
        if horizontal == .regular && vertical == .regular {
            self = .regular
        } else {
            self = .compact
        }
    }
}

// MARK: - blLayoutClass

extension EnvironmentValues {

    /// 根層決定並寫入環境的版面，未決定時為 `nil`
    @Entry private var decidedLayoutClass: BLLayoutClass? = nil

    /// 版面分類，根層已決定時沿用其值，否則依水平與垂直尺寸分類推導
    ///
    /// - Note: Preview 與截圖測試沒有根層決定值，因此由尺寸分類推導
    var blLayoutClass: BLLayoutClass {
        get {
            if let decidedLayoutClass {
                return decidedLayoutClass
            }
            return BLLayoutClass(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
        }
        set {
            decidedLayoutClass = newValue
        }
    }
}
