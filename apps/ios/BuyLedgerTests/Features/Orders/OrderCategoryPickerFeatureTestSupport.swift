//
//  OrderCategoryPickerFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 類別選擇器測試共用的狀態建立與捨棄確認預期值
enum OrderCategoryPickerFeatureTestSupport {}

// MARK: - Internal Method

extension OrderCategoryPickerFeatureTestSupport {

    /// 建立隔離的類別主檔與固定日期，不讀持久化目錄
    ///
    /// - Parameters:
    ///   - categories: 可用類別名稱
    ///   - committed: 已套用類別集合
    /// - Returns: 暫存集合與已套用集合相同的選擇器狀態
    static func makeState(
        categories: [String] = [],
        committed: Set<String> = []
    ) -> OrderCategoryPickerFeature.State {
        OrderCategoryPickerFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: categories)),
            committedCategories: committed,
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }

    /// 依清單狀態建立選擇器狀態，共用同一份資料引用，並以清單的已選類別作為比較基準
    ///
    /// - Parameter state: 清單狀態
    /// - Returns: 保留同一份資料引用的選擇器
    static func makeState(for state: OrderListFeature.State) -> OrderCategoryPickerFeature.State {
        OrderCategoryPickerFeature.State(
            orders: state.$orders,
            campaigns: state.$campaigns,
            lookupCatalog: state.$lookupCatalog,
            committedCategories: state.selectedCategories,
            dateContext: state.dateContext
                ?? OrderDateContext(
                    now: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
        )
    }

    /// 建立捨棄確認對話方塊之字面值預期
    ///
    /// - Returns: 字面值的確認資料
    static func expectedDiscardAlert() -> AlertState<OrderCategoryPickerFeature.Action.DiscardAlert> {
        AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("orders.list.message.filtersHaveApplied")
        }
    }

    /// 建立開團中與已收單各三個類別的選擇器狀態，資料沿用篩選測試的分組夾具
    ///
    /// - Parameter committed: 已套用類別集合
    /// - Returns: 開團中三類、已收單三類的選擇器
    /// - Note: 只拿來當受測輸入，預期值不由此函式的結果推算
    static func makeGroupedState(committed: Set<String> = []) -> OrderCategoryPickerFeature.State {
        let source = OrderFilterFeatureTestSupport.makeGroupedState(
            selection: OrderFilterSelection(categories: committed)
        )
        return OrderCategoryPickerFeature.State(
            orders: source.$orders,
            campaigns: source.$campaigns,
            lookupCatalog: source.$lookupCatalog,
            committedCategories: committed,
            dateContext: source.dateContext
        )
    }
}
