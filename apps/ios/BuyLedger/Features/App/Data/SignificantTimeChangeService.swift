//
//  SignificantTimeChangeService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

/// 系統重大時間變更的監聽入口，供殼層在跨日或校時後刷新日期標題；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct SignificantTimeChangeService: Sendable {

    // MARK: - Properties

    /// 訂閱系統重大時間變更，取消監聽時移除通知觀察者
    ///
    /// - Returns: 每次重大時間變更產生一個元素的串流
    var changes: Changes
}

// MARK: - Nested Types

extension SignificantTimeChangeService {

    /// `changes` 的函式型別
    typealias Changes = @Sendable () -> AsyncStream<Void>
}
