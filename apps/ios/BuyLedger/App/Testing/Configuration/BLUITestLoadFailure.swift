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

    /// 訂單每次讀取都先延遲再失敗，用來驗證讀取中離開畫面
    case ordersDelayed

    /// 開團載入失敗
    case campaigns

    /// 主檔載入失敗
    case lookups

    /// 匯率每次讀取都先延遲再失敗，用來驗證讀取中切分頁
    case exchangeRatesDelayed
}

#endif
