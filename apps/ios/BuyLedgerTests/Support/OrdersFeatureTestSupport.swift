//
//  OrdersFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

@testable import BuyLedger

/// 提供訂單分頁測試共用的訂單、表單狀態與通知
enum OrdersFeatureTestSupport {}

// MARK: - Internal Method

extension OrdersFeatureTestSupport {

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
        OrdersFeatureTestSupport.makeOrder(
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

    /// 建立只有「知道了」按鈕的失敗通知，供比對預期值
    ///
    /// - Parameter message: 預期通知訊息
    /// - Returns: `.alert` case 的目的地狀態，可直接指派給訂單分頁的目的地或暫存通知
    static func failureNotice(
        _ message: LocalizedStringKey
    ) -> OrdersPresentationFeature.Destination.State {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState(message)
            }
        )
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

    /// 以唯讀常數目錄建立已有「美妝」類別且開著編輯表單的訂單分頁狀態
    ///
    /// - Returns: `OrdersFeature.State` 值，可直接作為 `TestStore` 的初始狀態
    static func makeOptionState() -> OrdersFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = OrdersFeature.State()
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.$lookupCatalog = SharedReader(value: LookupCatalog(categories: ["美妝"]))
            state.list.$lookupCatalog = state.$lookupCatalog
            state.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(
                        categories: ["美妝"],
                        calendar: TestDependencies.fixedCalendar
                    ),
                    currentDate: TestDependencies.fixedNow
                )
            )
            state.presentation.destination?.modify(\.edit) {
                $0.draft.categories = ["美妝"]
            }
            return state
        }
    }
}
