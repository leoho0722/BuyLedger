//
//  OrdersRootRequest.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture

/// 根功能送進訂單容器的載入與跨功能資料變更請求
@CasePathable
enum OrdersRootRequest: Equatable, Sendable {

    /// 主檔讀取完成後載入共用訂單，由載入子 Feature 去重
    case load

    /// 套用開團刪除、開團改名或主檔改名後的訂單調整
    ///
    /// - Parameter request: 本機交易完成後應套用的訂單調整
    case cascade(OrdersCascadeOperations.Request)

    /// 切換訂單收款狀態，供開團詳情逐筆勾稽收款使用
    ///
    /// - Parameters:
    ///   - id: 要更新收款狀態的訂單編號
    ///   - status: 要套用的收款狀態
    case receiptStatusChange(id: LedgerOrder.ID, status: PaymentReceiptStatus)

    /// 套用主檔更新成功後已正規化的訂單，不重複落盤
    ///
    /// - Parameter orders: 已套用付款方式旗標的訂單
    case paymentMethodFlagsApply([LedgerOrder])

    /// 主檔端新增選項的結果，只由發起表單套用
    ///
    /// - Parameters:
    ///   - request: 原新增請求，保留表單識別值與付款方式旗標
    ///   - isStored: 是否寫入成功
    case optionAdditionCompleted(LookupAdditionRequest, isStored: Bool)
}
