//
//  BiometricAuthClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import Foundation
import LocalAuthentication

/// 呼叫系統本機驗證 (生物辨識或裝置密碼) 的依賴介面
struct BiometricAuthClient: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 裝置目前是否可執行本機驗證 (生物辨識或裝置密碼)
    /// - Returns: 裝置是否支援本機驗證
    var isAvailable: @Sendable () -> Bool
    
    /// 請求一次本機驗證，附上顯示於系統驗證對話框的理由文字
    /// - Parameter reason: 顯示給使用者的驗證理由
    /// - Returns: 本機驗證結果
    var authenticate: @Sendable (_ reason: String) async -> AuthenticationResult
    
    /// 裝置目前的生物辨識類型
    /// - Returns: 裝置使用的生物辨識類型
    var biometryType: @Sendable () -> BiometryType
}

// MARK: - Nested Types

extension BiometricAuthClient {
    
    /// 一次驗證請求的結果
    enum AuthenticationResult: Equatable, Sendable {
        
        // MARK: - Cases
        
        /// 驗證成功
        case success
        
        /// 驗證失敗 (含裝置密碼輸入錯誤次數過多等非取消性失敗)
        case failure
        
        /// 使用者或系統取消驗證
        case cancelled
    }
    
    /// 裝置支援的生物辨識種類
    enum BiometryType: Equatable, Sendable {
        
        // MARK: - Cases
        
        /// Face ID
        case faceID
        
        /// Touch ID
        case touchID
        
        /// 無可用生物辨識 (裝置無此硬體，或僅能以裝置密碼驗證)
        case unavailable
    }
}

// MARK: - Dependency Values

extension BiometricAuthClient: DependencyKey {
    
    /// App 執行時以真實 `LAContext` 呼叫系統本機驗證
    nonisolated static let liveValue = BiometricAuthClient(
        isAvailable: {
            LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        },
        authenticate: { reason in
            let context = LAContext()
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )
                return BiometricAuthClient.mapAuthenticationResult(success: success, error: nil)
            } catch {
                return BiometricAuthClient.mapAuthenticationResult(success: false, error: error)
            }
        },
        biometryType: {
            let context = LAContext()
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            return BiometricAuthClient.mapBiometryType(context.biometryType)
        }
    )
    
    /// 測試用的固定生物辨識結果；可用 withDependencies 覆寫
    nonisolated static let testValue = BiometricAuthClient(
        isAvailable: { true },
        authenticate: { _ in .success },
        biometryType: { .faceID }
    )
    
    /// Preview 使用固定結果，不觸發系統驗證
    nonisolated static let previewValue = BiometricAuthClient(
        isAvailable: { true },
        authenticate: { _ in .success },
        biometryType: { .faceID }
    )
}

// MARK: - Internal Method

extension BiometricAuthClient {
    
    /// 將 evaluatePolicy 的回呼結果轉成 AuthenticationResult
    /// - Parameters:
    ///   - success: `evaluatePolicy` 回呼的成功旗標
    ///   - error: `evaluatePolicy` 回呼的錯誤；非 `LAError` 時視為一般失敗
    /// - Returns: 映射後的驗證結果
    static func mapAuthenticationResult(success: Bool, error: Error?) -> AuthenticationResult {
        if success {
            return .success
        }
        
        guard let laError = error as? LAError else {
            return .failure
        }
        switch laError.code {
        case .userCancel, .systemCancel, .appCancel:
            return .cancelled
            
        default:
            return .failure
        }
    }
    
    /// 將 `LAContext.biometryType` 映射為 ``BiometryType``
    /// - Parameter laBiometryType: `LAContext.biometryType` 回傳的系統列舉值
    /// - Returns: 映射後的生物辨識類型
    static func mapBiometryType(_ laBiometryType: LABiometryType) -> BiometryType {
        switch laBiometryType {
        case .none:
            return .unavailable
            
        case .touchID:
            return .touchID
            
        case .faceID:
            return .faceID
            
        case .opticID:
            return .unavailable
            
        @unknown default:
            return .unavailable
        }
    }
}
