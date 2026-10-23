//
//  BiometricAuthService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import LocalAuthentication

/// 提供裝置本機驗證與生物辨識類型；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct BiometricAuthService: Sendable {

    // MARK: - Properties

    /// 檢查裝置目前能不能進行本機驗證 (生物辨識或裝置密碼)
    ///
    /// - Returns: 可以驗證時為 `true`
    var isAvailable: IsAvailable

    /// 請求一次本機驗證，附上顯示於系統驗證對話框的理由文字
    ///
    /// - Parameter reason: 顯示給使用者的驗證理由
    /// - Returns: 本機驗證結果
    var authenticate: Authenticate

    /// 查詢裝置支援哪一種生物辨識
    ///
    /// - Returns: 支援的生物辨識種類；沒有可用的生物辨識時為 `.unavailable`
    var biometryType: BiometryType
}

// MARK: - Nested Types

extension BiometricAuthService {

    /// `isAvailable` 的函式型別
    typealias IsAvailable = @Sendable () -> Bool

    /// `authenticate` 的函式型別
    typealias Authenticate = @Sendable (_ reason: String) async -> AuthenticationResult

    /// `biometryType` 的函式型別
    typealias BiometryType = @Sendable () -> BiometryKind

    /// 一次驗證請求的結果
    enum AuthenticationResult: Equatable, Sendable {

        /// 驗證成功
        case success

        /// 驗證失敗 (含裝置密碼輸入錯誤次數過多等非取消性失敗)
        case failure

        /// 使用者、系統或 App 取消驗證
        case cancelled
    }

    /// 裝置支援的生物辨識種類
    enum BiometryKind: Equatable, Sendable {

        /// 以臉部辨識驗證 (Face ID)
        case faceID

        /// 以指紋辨識驗證 (Touch ID)
        case touchID

        /// 無可用生物辨識 (裝置無此硬體，或僅能以裝置密碼驗證)
        case unavailable
    }
}

// MARK: - Internal Method

extension BiometricAuthService {

    /// 整理系統本機驗證結果，供 App 判斷成功、失敗或取消
    ///
    /// - Parameters:
    ///   - success: 系統驗證完成時回傳的結果是否成功
    ///   - error: 系統驗證完成時提供的錯誤；非 `LAError` 時視為一般失敗
    /// - Returns: 轉換後的驗證結果
    static func mapAuthenticationResult(
        success: Bool,
        error: (any Error)?
    ) -> AuthenticationResult {
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

    /// 將 `LAContext.biometryType` 轉換為 ``BiometryKind``
    ///
    /// - Parameter laBiometryType: `LAContext.biometryType` 回傳的系統列舉值
    /// - Returns: 轉換後的生物辨識類型
    static func mapBiometryType(_ laBiometryType: LABiometryType) -> BiometryKind {
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
                // `biometryType` 要先呼叫 `canEvaluatePolicy` 才有值
                _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                return Self.mapBiometryType(context.biometryType)
            }
        )
    }

    #if DEBUG

    /// Preview 使用成功的 Face ID 結果；在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "BiometricAuthService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            isAvailable: { true },
            authenticate: { _ in .success },
            biometryType: { .faceID }
        )
    }

    #endif

    /// 測試預設不允許本機驗證，沒有覆寫的操作被呼叫時測試直接失敗
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
