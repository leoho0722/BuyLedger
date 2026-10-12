//
//  OrdersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 容器的單元測試，並提供訂單分頁各測試檔共用的訂單與 alert 建構方法
@MainActor
struct OrdersFeatureTests {

}

// MARK: - Nested Types

extension OrdersFeatureTests {

    /// 訂單搜尋測試的輸入與預期結果
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    struct SearchCase: Sendable {

        /// 搜尋文字
        let query: String

        /// 搜尋後預期選取的訂單識別碼，也就是篩選結果的第一筆
        let selectedOrderID: String

        /// 預期篩選出的訂單識別碼
        let expectedOrderIDs: [String]
    }

    /// iPad 寬版畫面訂單列表欄上方篩選按鈕開啟的選擇器
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    enum FilterPicker: CaseIterable, Sendable {

        /// 類別選擇器
        case category

        /// 付款方式選擇器
        case paymentMethod

        /// 指向這個選擇器是否顯示的狀態欄位
        var keyPath: any WritableKeyPath<OrderListFeature.State, Bool> & Sendable {
            switch self {
            case .category:
                \.isCategoryPickerPresented

            case .paymentMethod:
                \.isPaymentMethodPickerPresented
            }
        }
    }
}

// MARK: - Internal Method

extension OrdersFeatureTests {

    /// 讓 `.task` 附帶的四項主檔讀取一律失敗，測試只需處理訂單載入
    ///
    /// - Parameter dependencies: 要注入的依賴集合
    /// - Note: 主檔失敗合併到載入回應，原有欄位不變
    static func suppressOrderLookupEffects(_ dependencies: inout DependencyValues) {
        let failingFetchOrderSources: OrderSourceService.FetchOrderSources = { () throws(PersistenceError) in
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchCategories: CategoryService.FetchCategories = { () throws(PersistenceError) in
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchPaymentMethodInfos: PaymentMethodService.FetchPaymentMethodInfos = { () throws(PersistenceError) in
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchStatuses: ReconciliationStatusService.FetchReconciliationStatuses = { () throws(PersistenceError) in
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }

        dependencies.orderSourceService.fetchOrderSources = failingFetchOrderSources
        dependencies.categoryService.fetchCategories = failingFetchCategories
        dependencies.paymentMethodService.fetchPaymentMethodInfos = failingFetchPaymentMethodInfos
        dependencies.reconciliationStatusService.fetchReconciliationStatuses = failingFetchStatuses
    }

    /// 建立只變更狀態的訂單複本
    ///
    /// - Parameters:
    ///   - order: 要複製的訂單
    ///   - status: 要套用的訂單狀態
    /// - Returns: 套用新狀態後的訂單
    static func withStatus(_ order: LedgerOrder, status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立折抵上限測試所需的訂單複本
    ///
    /// - Parameters:
    ///   - order: 要複製的訂單
    ///   - chargedAmount: 客戶實付金額
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - paymentMethod: 付款方式
    /// - Returns: 套用新的實付金額、無卡折抵金額與付款方式後的訂單
    static func withCardlessAmounts(
        _ order: LedgerOrder,
        chargedAmount: Decimal,
        cardlessDeductionAmount: Decimal,
        paymentMethod: String
    ) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立寫入失敗 alert，供測試比對
    ///
    /// - Parameter message: alert 顯示的錯誤訊息
    /// - Returns: 寫入失敗時顯示的 alert
    static func expectedWriteFailureAlert(
        _ message: LocalizedStringKey
    ) -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.list.label.operationFailed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("orders.merge.label.ok")
            }
        } message: {
            TextState(message)
        }
    }

    /// 建立只有一個類別的最小訂單，其餘欄位填零值或固定值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - category: 商品類別
    ///   - status: 訂單狀態
    ///   - paymentMethod: 付款方式
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        category: String,
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款"
    ) -> LedgerOrder {
        Self.makeOrder(
            id: id,
            categories: [category],
            status: status,
            paymentMethod: paymentMethod
        )
    }

    /// 建立可指定多個類別與開團名稱的最小訂單，其餘欄位填零值或固定值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - status: 訂單狀態
    ///   - paymentMethod: 付款方式
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        categories: [String],
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款",
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "來源",
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立刪除訂單的確認 alert
    ///
    /// - Parameters:
    ///   - orderID: 要刪除的訂單編號
    ///   - customerName: 訂單所屬客戶名稱
    /// - Returns: 刪除前顯示的確認 alert
    static func expectedDeletionConfirmation(
        orderID: LedgerOrder.ID,
        customerName: String
    ) -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.detail.label.deleteOrder")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(orderID)) {
                TextState("common.action.button.delete")
            }
            ButtonState(role: .cancel) {
                TextState("common.action.cancel")
            }
        } message: {
            TextState(
                LocalizedStringResource(
                    "orders.detail.message.deleteUndoneNotice",
                    defaultValue: "\(customerName)"
                )
            )
        }
    }

    /// 建立捨棄篩選變更的確認 alert
    ///
    /// - Returns: 捨棄前顯示的確認 alert
    static func expectedDiscardAlert() -> AlertState<OrderFilterFeature.Action.FilterDiscardAlert> {
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
}
