//
//  PersistenceFailureFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/26.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `PersistenceFailureFeature` 的單元測試，以 TestStore 逐步驗證持久層失敗畫面的復原確認與結果
@MainActor
struct PersistenceFailureFeatureTests {

    /// 驗證尚未確認時按下復原，只呈現確認視窗，畫面仍維持阻斷
    ///
    /// - Note: `testValue` 的 `quarantineStore` 為 `unimplemented`，非預期呼叫會使測試失敗
    @Test
    func recoveryTapped_尚未確認復原_只呈現確認視窗() async {
        // Given
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }

        // When
        await store.send(.view(.recoveryTapped)) {
            $0.destination = .alert(Self.expectedConfirmationAlert)
        }

        // Then
        #expect(store.state.phase == .blocked)
    }

    /// 驗證取消復原確認時關閉確認視窗，畫面仍維持阻斷，且不執行復原
    ///
    /// - Note: `testValue` 的 `quarantineStore` 為 `unimplemented`，非預期呼叫會使測試失敗
    @Test
    func destination_取消確認視窗_維持阻斷且不搬移檔案() async {
        // Given
        var initial = PersistenceFailureFeature.State()
        initial.destination = .alert(Self.expectedConfirmationAlert)
        let store = TestStore(initialState: initial) {
            PersistenceFailureFeature()
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }

        // Then
        #expect(store.state.phase == .blocked)
    }

    /// 驗證確認復原後 `quarantineStore` 只呼叫一次，隔離成功即切到要求重新啟動的階段
    @Test
    func destination_確認復原且隔離完成_要求重新啟動() async {
        // Given
        let callCount = LockIsolated(0)
        var initial = PersistenceFailureFeature.State()
        initial.destination = .alert(Self.expectedConfirmationAlert)
        let store = TestStore(initialState: initial) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0.persistenceRecoveryService.quarantineStore = {
                callCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmRecovery)))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.recoveryResponse) {
            $0.phase = .relaunchRequired
        }
        await store.finish()
        #expect(callCount.value == 1)
    }

    /// 驗證確認復原後隔離目錄建立或解析失敗時，畫面顯示底層錯誤的訊息作為原因，並維持阻斷、不切到重新啟動
    ///
    /// - Parameter scenario: 隔離失敗的分類與底層錯誤，以及預期顯示的底層錯誤訊息
    @Test(arguments: QuarantineFailureCase.allCases)
    func destination_確認復原但隔離目錄建立或解析失敗_顯示原因並維持阻斷(scenario: QuarantineFailureCase) async {
        // Given
        let failingQuarantineStore: PersistenceRecoveryService.QuarantineStore = { () throws(PersistenceRecoveryError) in
            throw scenario.error
        }
        var initial = PersistenceFailureFeature.State()
        initial.destination = .alert(Self.expectedConfirmationAlert)
        let store = TestStore(initialState: initial) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0.persistenceRecoveryService.quarantineStore = failingQuarantineStore
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmRecovery)))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.recoveryResponse) {
            $0.recoveryFailureReason = scenario.expectedReason
        }
        await store.finish()
    }
}

// MARK: - Nested Types

extension PersistenceFailureFeatureTests {

    /// 復原確認視窗的型別
    typealias ConfirmationAlert = AlertState<PersistenceFailureFeature.Destination.Alert>

    /// 一組隔離失敗的測試案例，含失敗分類、底層錯誤與預期顯示的原因
    struct QuarantineFailureCase: Sendable {

        /// 隔離目錄建立失敗與解析失敗兩種案例，各自帶不同的底層錯誤訊息
        static let allCases = [
            Self(
                error: .directoryCreationFailed(
                    underlying: NSError(
                        domain: "com.leoho.BuyLedger.recovery-test",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Backup could not be created."]
                    )
                ),
                expectedReason: "Backup could not be created."
            ),
            Self(
                error: .directoryResolutionFailed(
                    underlying: NSError(
                        domain: "com.leoho.BuyLedger.recovery-test",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Application Support 無法解析。"]
                    )
                ),
                expectedReason: "Application Support 無法解析。"
            ),
        ]

        /// 隔離失敗的分類與底層錯誤
        let error: PersistenceRecoveryError

        /// 預期顯示的底層錯誤訊息
        let expectedReason: String
    }
}

// MARK: - Private Method

private extension PersistenceFailureFeatureTests {

    /// 復原確認視窗的預期內容
    static var expectedConfirmationAlert: ConfirmationAlert {
        AlertState {
            TextState("common.general.label.continueBlankDatabase")
        } actions: {
            ButtonState(role: .destructive, action: .confirmRecovery) {
                TextState("common.general.label.keepBackupContinue")
            }
            ButtonState(role: .cancel) {
                TextState("common.action.cancel")
            }
        } message: {
            TextState("common.general.message.movesDataCannot")
        }
    }
}
