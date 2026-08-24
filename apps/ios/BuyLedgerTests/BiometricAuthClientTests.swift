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
    
    @Test func successIsMappedRegardlessOfError() {
        #expect(BiometricAuthClient.mapAuthenticationResult(success: true, error: nil) == .success)
    }
    
    @Test func failureWithNoErrorIsMappedToFailure() {
        #expect(BiometricAuthClient.mapAuthenticationResult(success: false, error: nil) == .failure)
    }
    
    @Test func failureWithNonLAErrorIsMappedToFailure() {
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
