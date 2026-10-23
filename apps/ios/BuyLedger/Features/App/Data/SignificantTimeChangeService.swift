//
//  SignificantTimeChangeService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import UIKit

/// 系統重大時間變更的監聽入口，供殼層在跨日或校時後刷新日期標題；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct SignificantTimeChangeService: Sendable {

    // MARK: - Properties

    /// 訂閱系統重大時間變更，取消串流時停止接收
    ///
    /// - Returns: 每次重大時間變更產生一個元素的串流
    var changes: Changes
}

// MARK: - Nested Types

extension SignificantTimeChangeService {

    /// `changes` 的函式型別
    typealias Changes = @Sendable () -> AsyncStream<Void>
}

// MARK: - DependencyKey

extension SignificantTimeChangeService: DependencyKey {

    /// 正式 App 監聽系統重大時間變更，取消串流時自動停止接收
    static var liveValue: Self {
        Self(
            changes: {
                let center = NotificationCenter.default
                return AsyncStream { continuation in
                    // 需同步回傳 `AsyncStream`，改用 `notifications(named:)` 得另開非結構化 `Task` 轉送
                    let observer = LockIsolated(
                        center.addObserver(
                            forName: UIApplication.significantTimeChangeNotification,
                            object: nil,
                            queue: nil
                        ) { _ in
                            continuation.yield(())
                        }
                    )
                    continuation.onTermination = { _ in
                        observer.withValue {
                            center.removeObserver($0)
                        }
                    }
                }
            }
        )
    }

    #if DEBUG

    /// Preview 使用立即結束的串流，在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "SignificantTimeChangeService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            changes: {
                AsyncStream {
                    $0.finish()
                }
            }
        )
    }

    #endif

    /// 測試預設未實作，漏接設定會回報 issue，佔位串流立即結束
    static var testValue: Self {
        Self(
            changes: unimplemented(
                "SignificantTimeChangeService.changes",
                placeholder: AsyncStream { $0.finish() }
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供殼層監聽跨日、校時與日光節約時間變更
    var significantTimeChangeService: SignificantTimeChangeService {
        get { self[SignificantTimeChangeService.self] }
        set { self[SignificantTimeChangeService.self] = newValue }
    }
}
