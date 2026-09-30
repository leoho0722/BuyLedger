//
//  BiometricAuthService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import LocalAuthentication

// MARK: - DependencyKey

extension BiometricAuthService: DependencyKey {

    /// 正式 App 透過 `LAContext` 呼叫系統本機驗證
    static var liveValue: Self {
        Self(
            isAvailable: {
                LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
            },
            authenticate: { reason in
                let context = LAContext()
                do {
                    let isAuthenticated = try await context.evaluatePolicy(
                        .deviceOwnerAuthentication,
                        localizedReason: reason
                    )
                    return Self.mapAuthenticationResult(success: isAuthenticated, error: nil)
                } catch {
                    return Self.mapAuthenticationResult(success: false, error: error)
                }
            },
            biometryType: {
                let context = LAContext()
                // biometryType 要先呼叫 canEvaluatePolicy 才有值
                _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                return Self.mapBiometryType(context.biometryType)
            }
        )
    }

    /// 測試預設不允許本機驗證，未覆寫的操作會回報未實作 issue
    static var testValue: Self {
        Self(
            isAvailable: unimplemented("BiometricAuthService.isAvailable", placeholder: false),
            authenticate: unimplemented("BiometricAuthService.authenticate", placeholder: .failure),
            biometryType: unimplemented(
                "BiometricAuthService.biometryType",
                placeholder: .unavailable
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 App 鎖定功能取得裝置本機驗證操作
    var biometricAuthService: BiometricAuthService {
        get { self[BiometricAuthService.self] }
        set { self[BiometricAuthService.self] = newValue }
    }
}
