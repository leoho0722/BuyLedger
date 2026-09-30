//
//  BiometricAuthServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import LocalAuthentication
import Testing

@testable import BuyLedger

/// 確認系統回報的驗證結果與辨識類型都轉成正確的 App 值
struct BiometricAuthServiceTests {

    // MARK: - Tests

    /// 系統回報驗證成功時，即使提供錯誤仍回報成功
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

    /// 失敗時沒有底層錯誤或錯誤不是 `LAError` 都回報一般失敗
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

    /// 使用者、系統或 App 取消的 `LAError` 會映射為已取消
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

    /// 非取消類的 `LAError` 會映射為一般失敗
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

    /// 依裝置回報的生物辨識類型映射種類；Optic ID 尚未在支援裝置上提供，因此映射為不可用
    ///
    /// - Parameters:
    ///   - biometryType: 裝置回報的生物辨識類型
    ///   - expectedKind: 預期映射的生物辨識種類
    @Test(arguments: [
        (LABiometryType.none, BiometricAuthService.BiometryKind.unavailable),
        (.touchID, .touchID),
        (.faceID, .faceID),
        (.opticID, .unavailable),
    ])
    func mapBiometryType_裝置生物辨識類型_回傳對應種類(
        biometryType: LABiometryType,
        expectedKind: BiometricAuthService.BiometryKind
    ) {
        // Given

        // When
        let result = BiometricAuthService.mapBiometryType(biometryType)

        // Then
        #expect(result == expectedKind)
    }
}
