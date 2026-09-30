//
//  BLUITestLoadSource.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

/// UI 測試載入失敗的資料來源
enum BLUITestLoadSource: String, Sendable {

    /// 訂單資料
    case orders

    /// 開團資料
    case campaigns

    /// 訂單來源主檔
    case orderSources

    /// 商品類別主檔
    case categories

    /// 付款方式詳細資料
    case paymentMethodInfos

    /// 對帳狀態主檔
    case reconciliationStatuses

    /// 支援幣別清單
    case currencyCodes
}

#endif
