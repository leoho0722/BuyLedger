//
//  BiometricAuthClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import Foundation
import LocalAuthentication
import Testing
@testable import BuyLedger

/// 驗證 AuthenticationResult 的 LAError 映射
struct BiometricAuthClientTests {

    // MARK: - Tests

    /// 成功回呼即使帶有底層錯誤也應映射為成功
    ///
    /// - Parameter hasUnderlyingError: 是否提供底層錯誤
    @Test(arguments: [false, true])
    func successMapping_ignoresUnderlyingError(hasUnderlyingError: Bool) {
        // Given：驗證結果成功，底層錯誤可有可無
        let error: NSError? = hasUnderlyingError
            ? NSError(domain: "com.leoho.BuyLedger.test", code: -1)
            : nil

        // When：將成功回呼映射為領域結果
        let result = BiometricAuthClient.mapAuthenticationResult(success: true, error: error)

        // Then：無論錯誤欄位內容，結果都應為成功
        #expect(result == .success)
    }

    /// 驗證失敗且沒有底層錯誤時應映射為一般失敗
    @Test
    func failureResult_withoutUnderlyingError_mapsToFailure() {
        #expect(BiometricAuthClient.mapAuthenticationResult(success: false, error: nil) == .failure)
    }

    /// 驗證失敗且帶有非 LAError 時應映射為一般失敗
    @Test
    func failureResult_withNonLAError_mapsToFailure() {
        let error = NSError(domain: "com.leoho.BuyLedger.test", code: -1)
        #expect(
            BiometricAuthClient.mapAuthenticationResult(success: false, error: error) == .failure)
    }

    @Test(arguments: [LAError.Code.userCancel, .systemCancel, .appCancel])
    func cancellationCodesAreMappedToCancelled(code: LAError.Code) {
        let error = LAError(code)
        #expect(
            BiometricAuthClient.mapAuthenticationResult(success: false, error: error) == .cancelled)
    }

    @Test(arguments: [
        LAError.Code.biometryNotAvailable, .biometryNotEnrolled, .biometryLockout,
        .authenticationFailed, .passcodeNotSet,
    ])
    func nonCancellationErrorCodesAreMappedToFailure(code: LAError.Code) {
        let error = LAError(code)
        #expect(
            BiometricAuthClient.mapAuthenticationResult(success: false, error: error) == .failure)
    }

    // MARK: 生物辨識類型映射

    @Test func noHardwareIsMappedToUnavailable() {
        #expect(BiometricAuthClient.mapBiometryType(.none) == .unavailable)
    }

    @Test func touchIDHardwareIsMappedToTouchID() {
        #expect(BiometricAuthClient.mapBiometryType(.touchID) == .touchID)
    }

    @Test func faceIDHardwareIsMappedToFaceID() {
        #expect(BiometricAuthClient.mapBiometryType(.faceID) == .faceID)
    }

    @Test func opticIDIsMappedToUnavailable() {
        // opticID 不在支援裝置上，仍須映射為 unavailable。
        #expect(BiometricAuthClient.mapBiometryType(.opticID) == .unavailable)
    }
}
