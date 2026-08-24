//
//  CampaignEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/19.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
/// 驗證開團表單的編輯與儲存
struct CampaignEditFeatureTests {
    
    // MARK: - Tests
    
    // MARK: Dirty State
    
    @Test func newCampaignIsNotDirtyUntilEdited() async {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)
        
        state.draft.name = "四月團"
        #expect(state.isDirty == true)
    }
    
    @Test func existingCampaignIsDirtyThenCleanWhenRestored() async {
        let original = Campaign(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var state = CampaignEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)
        
        state.draft.name = "四月團"
        #expect(state.isDirty == true)
        
        state.draft.name = original.name
        #expect(state.isDirty == false)
    }
    
    @Test func reminderIntentChangeMarksDirty() async {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)
        
        // 提醒意圖屬可儲存內容，變更應觸發 dirty
        state.draft.wantsReminder = true
        #expect(state.isDirty == true)
    }
    
    @Test func reminderTimestampChangeMarksDirty() async {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)
        
        // 提醒時間戳屬可儲存內容，inline 編輯後應觸發 dirty
        state.draft.reminderTimestamp = TestDependencies.fixedNow.addingTimeInterval(3600)
        #expect(state.isDirty == true)
    }
    
    @Test func cancelWithChangesPresentsDiscardConfirmation() async {
        var initial = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        initial.draft.name = "四月團"
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {}
        }
        await store.send(.cancelTapped) {
            $0.discardConfirmation = AlertState {
                TextState("捨棄變更")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("捨棄變更")
                }
                ButtonState(role: .cancel) {
                    TextState("繼續編輯")
                }
            } message: {
                TextState("這個開團有尚未儲存的變更，離開後將不會保留。")
            }
        }
        #expect(store.state.discardConfirmation != nil)
        
        // 捨棄後關閉表單，AlertState 也會自動清空
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
        }
    }
    
    @Test func everyDraftFieldIndividuallyMarksDirty() async {
        // 逐欄位覆蓋率：7 個草稿欄位各自獨立改動一次即斷言 dirty 為真
        // 其餘欄位沒有獨立覆蓋測試
        /// 建立本測試使用的初始編輯狀態
        /// - Returns: 未變更的 CampaignEditFeature 狀態
        func freshState() -> CampaignEditFeature.State {
            CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                reminderTimestamp: TestDependencies.fixedNow
            )
        }
        
        var nameState = freshState()
        nameState.draft.name = "四月團"
        #expect(nameState.isDirty == true)
        
        var openDateState = freshState()
        openDateState.draft.openDate = TestDependencies.fixedNow.addingTimeInterval(3600)
        #expect(openDateState.isDirty == true)
        
        var closeDateState = freshState()
        closeDateState.draft.closeDate = TestDependencies.fixedNow.addingTimeInterval(3600)
        #expect(closeDateState.isDirty == true)
        
        var statusState = freshState()
        statusState.draft.status = .closed
        #expect(statusState.isDirty == true)
        
        var notesState = freshState()
        notesState.draft.notes = "備註"
        #expect(notesState.isDirty == true)
        
        var wantsReminderState = freshState()
        wantsReminderState.draft.wantsReminder = true
        #expect(wantsReminderState.isDirty == true)
        
        var reminderTimestampState = freshState()
        reminderTimestampState.draft.reminderTimestamp = TestDependencies.fixedNow
            .addingTimeInterval(3600)
        #expect(reminderTimestampState.isDirty == true)
    }
    
    // MARK: Name Conflict
    
    @Test func editingDraftNameClearsStaleNameConflictMessage() async {
        // 父層拒絕儲存後顯示錯誤，重新編輯名稱時應清空。
        // 避免修正後仍殘留過期的重複名稱提示
        var initial = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        initial.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }
        
        await store.send(.binding(.set(\.draft.name, "五月團"))) {
            $0.draft.name = "五月團"
            $0.nameConflictMessage = nil
        }
    }
    
    @Test func cancelWithoutChangesDismissesDirectly() async {
        let store = TestStore(
            initialState: CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                reminderTimestamp: TestDependencies.fixedNow
            )
        ) {
            CampaignEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {}
        }
        await store.send(.cancelTapped)
        #expect(store.state.discardConfirmation == nil)
    }
}
