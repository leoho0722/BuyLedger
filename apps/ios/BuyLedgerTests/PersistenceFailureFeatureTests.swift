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
    
    @Test func recoveryTapOnlyPresentsConfirmation() async {
        let box = QuarantineCallBox()
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: { () throws(PersistenceRecoveryError) in
                    box.callCount += 1
                }
            )
        }
        
        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        
        #expect(store.state.phase == .blocked)
        #expect(box.callCount == 0)
    }
    
    @Test func cancellingConfirmationDismissesWithoutRecovering() async {
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }
        
        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.dismiss)) {
            $0.confirmation = nil
        }
        
        #expect(store.state.phase == .blocked)
    }
    
    @Test func confirmedRecoveryMovesFilesThenRequiresRelaunch() async {
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: {})
        }
        
        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }
        await store.receive(.recoverySucceeded) {
            $0.phase = .relaunchRequired
        }
    }
    
    @Test func failedRecoveryStaysBlockingAndShowsReason() async {
        let store = TestStore(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        } withDependencies: {
            $0[PersistenceStoreQuarantineClient.self] = PersistenceStoreQuarantineClient(
                quarantine: { () throws(PersistenceRecoveryError) in
                    throw .directoryCreationFailed(message: "Backup could not be created.")
                }
            )
        }
        
        await store.send(.recoveryTapped) {
            $0.confirmation = Self.expectedConfirmationAlert
        }
        await store.send(.confirmation(.presented(.confirmRecovery))) {
            $0.confirmation = nil
        }
        await store.receive(.recoveryFailed("Backup could not be created.")) {
            $0.recoveryFailureReason = "Backup could not be created."
        }
    }
}

// MARK: - Private Method

private extension PersistenceFailureFeatureTests {
    
    /// 復原確認 alert 的預期內容，供窮舉斷言比對
    static var expectedConfirmationAlert: AlertState<PersistenceFailureFeature.Action.Confirmation> {
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

/// 記錄 quarantine client 呼叫次數
private final class QuarantineCallBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 呼叫次數
    var callCount = 0
}
