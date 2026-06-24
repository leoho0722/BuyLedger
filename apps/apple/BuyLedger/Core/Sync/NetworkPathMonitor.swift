//
//  NetworkPathMonitor.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/22.
//

import ComposableArchitecture
import Foundation
import Network

/// 網路連線狀態監聽的可注入依賴。包住 `NWPathMonitor`，以 `AsyncStream<Bool>` 對外吐出
/// 連線事件，供 ``CloudSyncEngine`` 在連線恢復時 drain 待送佇列
///
/// 可注入：測試以 `withDependencies` 替換成自製 stream，免依賴真實網路狀態
struct NetworkPathMonitor: Sendable {

    // MARK: - Dependency Properties

    /// 連線狀態事件串流；
    /// 每次連線狀態變化 (含初次) 吐出一個布林 (true = 已連線)
    var connectivity: @Sendable () -> AsyncStream<Bool>
}

extension NetworkPathMonitor: DependencyKey {

    // MARK: - Dependency Values

    /// 正式實作；
    /// 以 `NWPathMonitor` 在背景佇列觀察路徑狀態，satisfied 視為已連線
    nonisolated static let liveValue = NetworkPathMonitor(
        connectivity: {
            AsyncStream { continuation in
                let monitor = NWPathMonitor()
                let queue = DispatchQueue(label: "com.leoho.BuyLedger.networkPathMonitor")
                monitor.pathUpdateHandler = { path in
                    continuation.yield(path.status == .satisfied)
                }
                continuation.onTermination = { _ in
                    monitor.cancel()
                }
                monitor.start(queue: queue)
            }
        }
    )

    /// 測試實作；吐出單一「已連線」事件後結束
    nonisolated static let testValue = NetworkPathMonitor(
        connectivity: {
            AsyncStream { continuation in
                continuation.yield(true)
                continuation.finish()
            }
        }
    )

    /// 預覽實作；沿用 ``testValue``
    nonisolated static let previewValue = testValue
}

extension DependencyValues {

    // MARK: - Dependency Values

    /// 網路連線狀態監聽依賴
    var networkPathMonitor: NetworkPathMonitor {
        get { self[NetworkPathMonitor.self] }
        set { self[NetworkPathMonitor.self] = newValue }
    }
}
