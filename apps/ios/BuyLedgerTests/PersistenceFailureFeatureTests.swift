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

/// 驗證持久層失敗畫面
@MainActor
struct PersistenceFailureFeatureTests {

    // MARK: - Tests

    /// 驗證持久化失敗畫面的狀態與復原流程
    @Test func recoveryTapOnlyPresentsConfirmation() async {
        // Given

        let callCount = LockIsolated(0)
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: { () throws(PersistenceRecoveryError) in
                    callCount.withValue { $0 += 1 }
                }
            )
        }

        // When

        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }

        // Then

        #expect(store.state.phase == .blocked)
        #expect(callCount.value == 0)
    }

    /// 驗證持久化失敗畫面的狀態與復原流程
    @Test func cancellingConfirmationDismissesWithoutRecovering() async {
        // Given

        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }

        // When

        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.dismiss)) {
            $0.confirmation = nil
        }

        // Then

        #expect(store.state.phase == .blocked)
    }

    /// 驗證持久化失敗畫面的狀態與復原流程
    @Test func confirmedRecoveryMovesFilesThenRequiresRelaunch() async {
        // Given

        let callCount = LockIsolated(0)
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: {
                    callCount.withValue { $0 += 1 }
                }
            )
        }

        // When

        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }
        // Then

        await store.receive(.recoverySucceeded) {
            $0.phase = .relaunchRequired
        }
        #expect(callCount.value == 1)
    }

    /// 驗證持久化失敗畫面的狀態與復原流程
    @Test func failedRecoveryStaysBlockingAndShowsReason() async {
        // Given

        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: { () throws(PersistenceRecoveryError) in
                    throw .directoryCreationFailed(
                        underlying: NSError(
                            domain: "com.leoho.BuyLedger.recovery-test",
                            code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Backup could not be created.",
                            ]
                        )
                    )
                }
            )
        }

        // When

        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }
        // Then

        await store.receive(.recoveryFailed("Backup could not be created.")) {
            $0.recoveryFailureReason = "Backup could not be created."
        }
    }

    /// Application Support 解析失敗時應保留復原錯誤的顯示文字
    @Test func failedRecoveryWithDirectoryResolutionErrorShowsReason() async {
        // Given

        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: { () throws(PersistenceRecoveryError) in
                    throw .directoryResolutionFailed(
                        underlying: NSError(
                            domain: "com.leoho.BuyLedger.recovery-test",
                            code: 2,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Application Support 無法解析。",
                            ]
                        )
                    )
                }
            )
        }

        // When

        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }

        // Then

        await store.receive(.recoveryFailed("Application Support 無法解析。")) {
            $0.recoveryFailureReason = "Application Support 無法解析。"
        }
    }
}

// MARK: - Private Method

private extension PersistenceFailureFeatureTests {

    /// 復原確認 alert 的預期內容，供窮舉斷言比對
    static var expectedConfirmationAlert:
        AlertState<PersistenceFailureFeature.Action.Confirmation> {
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
