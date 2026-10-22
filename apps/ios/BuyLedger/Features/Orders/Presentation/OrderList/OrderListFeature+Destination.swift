//
//  OrderListFeature+Destination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture

// MARK: - Nested Types

extension OrderListFeature {

    /// 訂單清單可呈現的篩選目的地
    @Reducer
    enum Destination {

        /// 暫存與套用整合篩選的面板
        ///
        /// - Parameter feature: 管理篩選草稿與捨棄確認的子 Feature
        case filterSheet(OrderFilterFeature)

        /// 暫存與套用 iPad 類別多選的選擇器
        ///
        /// - Parameter feature: 管理類別集合與捨棄確認的子 Feature
        case categoryPicker(OrderCategoryPickerFeature)
    }
}

// MARK: - Equatable

extension OrderListFeature.Destination.State: Equatable {}
