//
//  View+LayoutMeasurement.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/31.
//

import SwiftUI

// MARK: - Layout Measurement

extension View {

    /// 將量測 anchor 掛在被修飾的實際前景內容上 (modifier 之前)，量測相對於根具名座標空間之 `frame`
    ///
    /// - Returns: 附加 anchor 量測背景之視圖
    func anchorContentFrame() -> some View {
        background(
            GeometryReader {
                Color.clear
                    .preference(
                        key: ViewLayoutMeasurementSupport.InnerFramePreferenceKey.self,
                        value: $0.frame(
                            in: .named(ViewLayoutMeasurementSupport.coordinateSpaceName)
                        )
                    )
            }
        )
    }
}
