//
//  AppScenePhaseCoordinatorTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import SwiftUI
import Testing
@testable import BuyLedger

/// 釘住「哪個場景轉換觸發了哪個 ``AppLockFeature/Action``」
@MainActor
struct AppScenePhaseCoordinatorTests {
    
    // MARK: - Tests
    
    @Test func backgroundSendsResignActive() {
        var sentActions: [AppLockFeature.Action] = []
        
        AppScenePhaseCoordinator.handle(newPhase: .background) { sentActions.append($0) }
        
        #expect(sentActions == [.appDidResignActive])
    }
    
    @Test func activeSendsBecameActive() {
        var sentActions: [AppLockFeature.Action] = []
        
        AppScenePhaseCoordinator.handle(newPhase: .active) { sentActions.append($0) }
        
        #expect(sentActions == [.appDidBecomeActive])
    }
    
    @Test func inactiveSendsNothing() {
        var sentActions: [AppLockFeature.Action] = []
        
        AppScenePhaseCoordinator.handle(newPhase: .inactive) { sentActions.append($0) }
        
        #expect(sentActions.isEmpty)
    }
}
