//
//  MockHTTPClient.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 記錄各傳輸方法收到的請求並回傳預先設定的 data 結果
final class MockHTTPClient: Sendable {

    // MARK: - Properties

    /// `data(for:)` 的呼叫次數
    private let dataCallCountState = LockIsolated(0)

    /// `data(for:)` 依呼叫順序收到的請求
    private let dataReceivedArgumentsState = LockIsolated<[URLRequest]>([])

    /// `data(for:)` 要回傳的固定結果
    private let dataResultState = LockIsolated<Result<(Data, HTTPURLResponse), APIError>>(
        .failure(
            .transport(
                underlying: NSError(
                    domain: "com.leoho.BuyLedger.http-client-mock",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "MockHTTPClient 未設定 data 回應。"]
                )
            )
        )
    )

    /// `bytes(for:)` 的呼叫次數
    private let bytesCallCountState = LockIsolated(0)

    /// `bytes(for:)` 依呼叫順序收到的請求
    private let bytesReceivedArgumentsState = LockIsolated<[URLRequest]>([])
}

// MARK: - Computed Properties

extension MockHTTPClient {

    /// `data(for:)` 的呼叫次數
    var dataCallCount: Int {
        dataCallCountState.withValue { $0 }
    }

    /// `data(for:)` 收到的請求
    var dataReceivedArguments: [URLRequest] {
        dataReceivedArgumentsState.withValue { $0 }
    }

    /// 設定 `data(for:)` 的回傳結果
    var dataResult: Result<(Data, HTTPURLResponse), APIError> {
        get {
            dataResultState.withValue { $0 }
        }
        set {
            dataResultState.withValue { $0 = newValue }
        }
    }

    /// `bytes(for:)` 的呼叫次數
    var bytesCallCount: Int {
        bytesCallCountState.withValue { $0 }
    }

    /// `bytes(for:)` 收到的請求
    var bytesReceivedArguments: [URLRequest] {
        bytesReceivedArgumentsState.withValue { $0 }
    }
}

// MARK: - HTTPClientProtocol

extension MockHTTPClient: HTTPClientProtocol {

    /// 記錄請求並回傳測試端設定的結果
    ///
    /// - Parameter request: 呼叫端送來的 `URLRequest`
    /// - Returns: 設定成功時的資料與 `HTTPURLResponse`
    /// - Throws: `dataResult` 失敗時丟出設定的 `APIError` case
    ///   `.transport(underlying:)`、`.http(statusCode:)`、`.decoding(underlying:)`、
    ///   `.apiError(code:)`、`.quotaExceeded` 或 `.invalidKey`
    func data(for request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) {
        dataCallCountState.withValue { $0 += 1 }
        dataReceivedArgumentsState.withValue { $0.append(request) }
        let result = dataResultState.withValue { $0 }
        return try result.get()
    }

    /// 記錄請求並以 transport 錯誤拒絕串流
    ///
    /// - Parameter request: 呼叫端送來的 `URLRequest`
    /// - Returns: 此 mock 不會回傳串流
    /// - Throws: 一律丟出 `.transport(underlying:)`
    /// - Note: 測試中無法建立 `URLSession.AsyncBytes`，因此不提供可設定的成功結果
    func bytes(
        for request: URLRequest
    ) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) {
        bytesCallCountState.withValue {
            $0 += 1
        }
        bytesReceivedArgumentsState.withValue {
            $0.append(request)
        }
        throw .transport(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.http-client-mock",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "MockHTTPClient 未設定串流回應。"]
            )
        )
    }
}
