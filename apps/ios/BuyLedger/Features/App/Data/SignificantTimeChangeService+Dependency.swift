//
//  SignificantTimeChangeService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import UIKit

// MARK: - DependencyKey

extension SignificantTimeChangeService: DependencyKey {

    /// 建立串流時同步註冊系統通知，取消串流時以鎖保護的觀察者憑證解除訂閱
    static var liveValue: Self {
        Self(
            changes: {
                let center = NotificationCenter.default
                return AsyncStream { continuation in
                    // 需同步回傳 AsyncStream，改用 notifications(named:) 得另開非結構化 Task 轉送
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
