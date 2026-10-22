//
//  BLUITestLoadFailure.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

#if DEBUG

/// UI 測試要模擬的載入失敗情境
enum BLUITestLoadFailure: String, CaseIterable, Sendable {

    /// 不模擬失敗
    case none

    /// 訂單載入每次都失敗
    case orders

    /// 訂單只有第一次讀取失敗，重試即成功
    case ordersFirstReadOnly

    /// 開團載入失敗
    case campaigns

    /// 主檔載入失敗
    case lookups
}

#endif
