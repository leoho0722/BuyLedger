//
//  OrderCostBreakdown.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation

/// 訂單詳情共用的成本項目計算，不持有畫面色彩
enum OrderCostBreakdown {

}

// MARK: - Nested Types

extension OrderCostBreakdown {

    /// 成本項目使用的語意色調，由畫面轉成色盤顏色
    enum Tone: Equatable, Sendable {

        /// 商品金額的強調色調
        case accent

        /// 刷卡手續費的橘色色調
        case orange

        /// 平台手續費的藍綠色色調
        case teal

        /// 金流手續費的紫色色調
        case purple

        /// 國內運費的靛色色調
        case indigo

        /// 國際運費的粉紅色色調
        case pink

        /// 外國國內運費的黃色色調
        case yellow
    }

    /// 一項成本的標題、金額與語意色調
    struct Component: Equatable, Identifiable, Sendable {

        /// 成本項目名稱
        let title: String

        /// 成本項目金額
        let value: Decimal

        /// 畫面應使用的色調
        let tone: Tone

        /// 以原有標題識別成本項目
        var id: String {
            title
        }
    }

    /// 圈狀圖的單一區段，金額已轉為 `Double` 並附上本地化金額描述
    struct DonutSlice: Equatable, Sendable {

        /// 區段名稱，即成本項目名稱
        let label: String

        /// 區段數值，供圈狀圖計算占比
        let value: Double

        /// 供輔助技術朗讀的本地化金額描述
        let valueDescription: String

        /// 畫面依此選擇區段顏色的語意色調
        let tone: Tone
    }
}

// MARK: - Internal Method

extension OrderCostBreakdown {

    /// 整理商品、手續費與貨到付款運費，只保留正值項目
    ///
    /// - Parameter order: 要顯示成本拆解的訂單
    /// - Returns: 保留既有順序、標題與金額的成本項目
    static func components(for order: LedgerOrder) -> [Component] {
        let summary = order.summary
        let codDomesticShipping = order.isCashOnDelivery ? order.domesticShipping : 0
        let codInternationalShipping = order.isCashOnDelivery ? order.internationalShipping : 0
        let codForeignDomesticShipping = order.isCashOnDelivery ? order.foreignDomesticShipping : 0
        return [
            Component(
                title: "orders.detail.label.itemCost",
                value: order.itemCost,
                tone: Tone.accent
            ),
            Component(
                title: "orders.detail.label.cardFee",
                value: summary.cardFee,
                tone: Tone.orange
            ),
            Component(
                title: "orders.detail.label.platformFee",
                value: summary.platformFee,
                tone: Tone.teal
            ),
            Component(
                title: "orders.detail.label.paymentProcessingFee",
                value: summary.paymentFee,
                tone: Tone.purple
            ),
            Component(
                title: "orders.detail.label.localShipping",
                value: codDomesticShipping,
                tone: Tone.indigo
            ),
            Component(
                title: "orders.detail.label.internationalShipping",
                value: codInternationalShipping,
                tone: Tone.pink
            ),
            Component(
                title: "orders.detail.label.foreignLocalShipping",
                value: codForeignDomesticShipping,
                tone: Tone.yellow
            ),
        ]
            .filter { $0.value > 0 }
    }

    /// 將成本項目轉成圈狀圖的區段，金額轉為 `Double` 並附上本地化的金額描述
    ///
    /// - Parameters:
    ///   - components: 詳情 State 提供的成本項目，保留原有順序
    ///   - locale: 金額描述使用的 `locale`
    /// - Returns: 與成本項目同順序的圈狀圖區段，顏色由畫面依語意色調決定
    static func donutSlices(for components: [Component], locale: Locale) -> [DonutSlice] {
        components.map {
            DonutSlice(
                label: $0.title,
                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                valueDescription: OrderFormatters.twd($0.value, locale: locale),
                tone: $0.tone
            )
        }
    }
}
