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

/// 驗證持久層失敗畫面的復原確認與結果
@MainActor
struct PersistenceFailureFeatureTests {

    // MARK: - Tests

    /// 未確認復原時只顯示確認視窗
    ///
    /// - Note: `testValue` 的 `quarantineStore` 為 `unimplemented`，非預期呼叫會使測試失敗
    @Test
    func recoveryTapped_尚未確認復原_只呈現確認視窗() async {
        // Given
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }

        // When
        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }

        // Then
        #expect(store.state.phase == .blocked)
    }

    /// 取消確認時關閉視窗且不執行復原
    ///
    /// - Note: `testValue` 的 `quarantineStore` 為 `unimplemented`，非預期呼叫會使測試失敗
    @Test
    func confirmation_取消確認視窗_維持阻斷且不搬移檔案() async {
        // Given
        var initial = PersistenceFailureFeature.State()
        initial.confirmation = Self.expectedConfirmationAlert
        let store = TestStore(initialState: initial) {
            PersistenceFailureFeature()
        }

        // When
        await store.send(.confirmation(.dismiss)) {
            $0.confirmation = nil
        }

        // Then
        #expect(store.state.phase == .blocked)
    }

    /// 確認復原後把資料庫檔案搬到隔離備份一次，搬移成功就切到要求重新啟動的階段
    @Test
    func confirmation_確認復原且隔離完成_要求重新啟動() async {
        // Given
        let callCount = LockIsolated(0)
        var initial = PersistenceFailureFeature.State()
        initial.confirmation = Self.expectedConfirmationAlert
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
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }

        // Then
        await store.receive(\.recoverySucceeded) {
            $0.phase = .relaunchRequired
        }
        #expect(callCount.value == 1)
    }

    /// 確認復原後隔離目錄建立或解析失敗時，畫面顯示底層錯誤原因，並維持阻斷不切到重新啟動
    ///
    /// - Parameters:
    ///   - error: 隔離失敗的分類與底層錯誤
    ///   - expectedReason: 預期顯示的底層錯誤訊息
    @Test(arguments: [
        (
            PersistenceRecoveryError.directoryCreationFailed(
                underlying: NSError(
                    domain: "com.leoho.BuyLedger.recovery-test",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Backup could not be created."]
                )
            ),
            "Backup could not be created."
        ),
        (
            .directoryResolutionFailed(
                underlying: NSError(
                    domain: "com.leoho.BuyLedger.recovery-test",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Application Support 無法解析。"]
                )
            ),
            "Application Support 無法解析。"
        ),
    ])
    func confirmation_確認復原但隔離目錄建立或解析失敗_顯示原因並維持阻斷(
        error: PersistenceRecoveryError,
        expectedReason: String
    ) async {
        // Given
        let failingQuarantineStore: PersistenceRecoveryService.QuarantineStore = {
            throw error
        }
        var initial = PersistenceFailureFeature.State()
        initial.confirmation = Self.expectedConfirmationAlert
        let store = TestStore(initialState: initial) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0.persistenceRecoveryService.quarantineStore = failingQuarantineStore
        }

        // When
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }

        // Then
        await store.receive(\.recoveryFailed, expectedReason) {
            $0.recoveryFailureReason = expectedReason
        }
    }
}

// MARK: - Nested Types

private extension PersistenceFailureFeatureTests {

    /// 復原確認視窗的型別
    typealias ConfirmationAlert = AlertState<PersistenceFailureFeature.Action.Confirmation>
}

// MARK: - Private Method

private extension PersistenceFailureFeatureTests {

    /// 復原確認視窗的預期內容
    static var expectedConfirmationAlert: ConfirmationAlert {
        AlertState {
            TextState("改用空白資料庫繼續")
        } actions: {
            ButtonState(role: .destructive, action: .confirmRecovery) {
                TextState("保留備份並繼續")
            }
            ButtonState(role: .cancel) {
                TextState("取消")
            }
        } message: {
            TextState("這會將目前無法開啟的資料搬到裝置上的備份目錄。資料不會被刪除。完成後請關閉並重新開啟 App。")
        }
    }
}
