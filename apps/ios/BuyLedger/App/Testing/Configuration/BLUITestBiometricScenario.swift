//
//  BLUITestBiometricScenario.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

#if DEBUG

/// UI 測試要模擬的本機驗證情境
enum BLUITestBiometricScenario: String, CaseIterable, Sendable {

    /// 驗證一律成功
    case success

    /// 驗證一律失敗
    case failure
}

#endif
