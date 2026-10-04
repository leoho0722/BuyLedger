//
//  BiometricAuthService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import LocalAuthentication

/// 提供裝置本機驗證與生物辨識類型；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
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
    /// - Returns: 映射後的驗證結果
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

    /// 將 `LAContext.biometryType` 映射為 ``BiometryKind``
    ///
    /// - Parameter laBiometryType: `LAContext.biometryType` 回傳的系統列舉值
    /// - Returns: 映射後的生物辨識類型
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
