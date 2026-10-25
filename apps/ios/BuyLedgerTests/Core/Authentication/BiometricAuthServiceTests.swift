//
//  BiometricAuthServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import LocalAuthentication
import Testing

@testable import BuyLedger

/// `BiometricAuthService` 的單元測試，涵蓋系統驗證結果與生物辨識類型的映射
struct BiometricAuthServiceTests {

    /// 驗證系統回報成功時，不論是否同時提供底層錯誤，結果都是成功
    ///
    /// - Parameter error: 模擬系統同時提供的底層錯誤
    @Test(arguments: [nil, NSError(domain: "com.leoho.BuyLedger.test", code: -1)])
    func mapAuthenticationResult_成功回呼有無底層錯誤_回傳成功(error: NSError?) {
        // Given

        // When
        let result = BiometricAuthService.mapAuthenticationResult(success: true, error: error)

        // Then
        #expect(result == .success)
    }

    /// 驗證系統回報失敗、且沒有錯誤或錯誤不是 `LAError` 時，結果都是一般失敗
    ///
    /// - Parameter error: 模擬系統回報的底層錯誤
    @Test(arguments: [nil, NSError(domain: "com.leoho.BuyLedger.test", code: -1)])
    func mapAuthenticationResult_失敗回呼沒有LAError_回傳一般失敗(error: NSError?) {
        // Given

        // When
        let result = BiometricAuthService.mapAuthenticationResult(success: false, error: error)

        // Then
        #expect(result == .failure)
    }

    /// 驗證使用者、系統或 App 取消的 `LAError` 會映射為已取消
    ///
    /// - Parameter code: 本次映射使用的取消類錯誤碼
    @Test(arguments: [LAError.Code.userCancel, .systemCancel, .appCancel])
    func mapAuthenticationResult_取消類LAError_回傳已取消(code: LAError.Code) {
        // Given
        let error = LAError(code)

        // When
        let result = BiometricAuthService.mapAuthenticationResult(success: false, error: error)

        // Then
        #expect(result == .cancelled)
    }

    /// 驗證非取消類的 `LAError`，如生物辨識不可用、未登錄、鎖定或認證失敗，都映射為一般失敗
    ///
    /// - Parameter code: 本次映射使用的非取消類錯誤碼
    @Test(arguments: [
        LAError.Code.biometryNotAvailable,
        .biometryNotEnrolled,
        .biometryLockout,
        .authenticationFailed,
        .passcodeNotSet,
    ])
    func mapAuthenticationResult_非取消類LAError_回傳一般失敗(code: LAError.Code) {
        // Given
        let error = LAError(code)

        // When
        let result = BiometricAuthService.mapAuthenticationResult(success: false, error: error)

        // Then
        #expect(result == .failure)
    }

    /// 驗證裝置回報的生物辨識類型映射為對應種類，無生物辨識與 Optic ID 都映射為不可用 (Optic ID 尚未在支援裝置上提供)
    ///
    /// - Parameter scenario: 裝置回報的生物辨識類型與預期映射的種類
    @Test(arguments: [
        BiometryCase(biometryType: LABiometryType.none, expectedKind: .unavailable),
        BiometryCase(biometryType: .touchID, expectedKind: .touchID),
        BiometryCase(biometryType: .faceID, expectedKind: .faceID),
        BiometryCase(biometryType: .opticID, expectedKind: .unavailable),
    ])
    func mapBiometryType_裝置生物辨識類型_回傳對應種類(scenario: BiometryCase) {
        // Given

        // When
        let result = BiometricAuthService.mapBiometryType(scenario.biometryType)

        // Then
        #expect(result == scenario.expectedKind)
    }
}

// MARK: - Nested Types

extension BiometricAuthServiceTests {

    /// 生物辨識類型映射的測試案例：裝置回報的類型與預期映射的種類
    struct BiometryCase: Sendable {

        /// 裝置回報的生物辨識類型
        let biometryType: LABiometryType

        /// 預期映射的生物辨識種類
        let expectedKind: BiometricAuthService.BiometryKind
    }
}
