//
//  UITestError.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

/// UI 測試記錄失敗後用來停止目前流程的訊號
enum UITestError: Error {

    /// 失敗已記錄，後續步驟不應繼續
    ///
    /// - Parameter message: 記錄的失敗訊息
    case stopped(message: String)
}
