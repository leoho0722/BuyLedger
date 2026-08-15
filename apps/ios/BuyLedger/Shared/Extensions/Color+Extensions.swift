//
//  Color+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

// MARK: - Static Properties

extension Color {
    
    /// 資訊性次要文字的單一入口，代理至色盤的次要標籤色
    static var blSecondaryLabel: Color {
        BLPalette().secondaryLabel
    }
}
