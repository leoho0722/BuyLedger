//
//  CampaignFeatureFailureTimingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋表單關閉期間到達的寫入失敗，提示延到表單關好才呈現
@MainActor
struct CampaignFeatureFailureTimingTests {

    /// 驗證儲存新開團失敗時，表單先關閉，失敗提示先暫存，清單不加入該開團
    ///
    /// - Note: 規格範例：寫入失敗時，新增表單內容為「失敗開團」，按下儲存
    @Test
    func presentation_儲存新開團失敗_表單先關閉並暫存失敗提示() async {
        // Given
        var editState = CampaignFeatureTestSupport.makeEditState()
        editState.draft.name = "失敗開團"
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(editState)
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSavedTry")
            }
        )
        let savedCampaignNames = LockIsolated<[String]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign throws(PersistenceError) in
            savedCampaignNames.withValue {
                $0.append(campaign.name)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(1))
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.campaigns.isEmpty)
        #expect(savedCampaignNames.value == ["失敗開團"])
    }

    /// 驗證表單正在關閉、儲存失敗的提示已暫存時，表單關好後才呈現該提示，並清除暫存
    ///
    /// - Note: 規格範例：寫入失敗時，新增表單內容為「失敗開團」，按下儲存
    @Test
    func formSheetDismissed_儲存失敗後表單關好_呈現失敗提示() async {
        // Given
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSavedTry")
            }
        )
        var initial = CampaignFeature.State()
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = expectedNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
    }

    /// 驗證表單開啟中載入到結單日已過的開團、自動轉狀態失敗時，失敗提示暫存、表單維持開啟
    ///
    /// - Note: 規格範例：新增表單開啟中自動轉狀態失敗，之後對沒有變更的表單按取消
    @Test
    func load_表單開啟中自動轉狀態失敗_暫存通知且表單維持開啟() async {
        // Given
        let overdue = Campaign(
            id: "C1",
            name: "過期團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_777_539_600),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let closed = Campaign(
            id: "C1",
            name: "過期團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_777_539_600),
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.automaticallyUpdatingCampaign")
            }
        )
        let editState = CampaignFeatureTestSupport.makeEditState()
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(editState)
        let failingSave: CampaignService.SaveCampaign = { _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_777_597_200))
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.load(.campaignsResponse(.success([overdue])))) {
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [closed]
            }
        }

        // Then
        await store.receive(\.load.autoCloseResponse)
        await store.receive(\.load.delegate.autoCloseFailed)
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        #expect(store.state.presentation.destination == .edit(editState))
    }

    /// 驗證表單開啟中自動轉狀態失敗、使用者取消表單後，失敗提示等表單關好才呈現，並清除暫存
    ///
    /// - Note: 規格範例：新增表單開啟中自動轉狀態失敗，之後對沒有變更的表單按取消
    @Test
    func formSheetDismissed_表單開啟中自動轉狀態失敗後取消_表單關好才呈現通知() async {
        // Given
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.automaticallyUpdatingCampaign")
            }
        )
        var initial = CampaignFeature.State()
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = expectedNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
        #expect(store.state.presentation.queue.isFormClosing == false)
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }

    /// 驗證表單關閉中已暫存一則失敗提示時，又到達另一則失敗，暫存改為後一則
    @Test
    func writes_表單關閉中再次失敗_暫存通知改為後一則() async {
        // Given
        let firstNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSavedTry")
            }
        )
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSettledTry")
            }
        )
        var initial = CampaignFeature.State()
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = firstNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.writes(.delegate(.failed(.settle))))

        // Then
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        #expect(store.state.presentation.destination == nil)
    }

    /// 驗證表單關閉中已暫存結算失敗提示時，表單關好後呈現該提示並清除暫存
    @Test
    func formSheetDismissed_關閉中已有結算失敗提示_呈現提示並清除暫存() async {
        // Given
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSettledTry")
            }
        )
        var initial = CampaignFeature.State()
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = expectedNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }
}
