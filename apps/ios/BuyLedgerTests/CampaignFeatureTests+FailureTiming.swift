//
//  CampaignFeatureTests+FailureTiming.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 儲存新開團失敗時表單先關閉，失敗提示等表單關好才出現，清單沒有該開團
    ///
    /// - Note: 規格範例：寫入失敗時，新增表單內容為「失敗開團」，按下儲存
    @Test
    func formSheetDismissed_儲存失敗後表單關好_呈現失敗提示() async {
        // Given
        var editState = Self.makeEditState()
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
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))
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

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
        #expect(store.state.campaigns.isEmpty)
        #expect(savedCampaignNames.value == ["失敗開團"])
    }

    /// 新增表單開啟中結單日自動轉狀態失敗，使用者取消表單後才出現失敗提示
    ///
    /// - Note: 規格範例：新增表單開啟中自動轉狀態失敗，之後對沒有變更的表單按取消
    @Test
    func formSheetDismissed_表單開啟中自動轉狀態失敗後取消_表單關好才呈現通知() async {
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
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(Self.makeEditState())
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
        await store.send(.load(.campaignsResponse(.success([overdue])))) {
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [closed]
            }
        }
        await store.receive(\.load.autoCloseResponse)
        await store.receive(\.load.delegate.autoCloseFailed)
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        await store.send(.presentation(.destination(.presented(.edit(.view(.cancelButtonTapped))))))
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
        #expect(store.state.presentation.queue == CampaignPresentationQueue())
    }

    /// 表單關閉中連續到達兩則失敗，表單關好後只呈現後一則
    @Test
    func formSheetDismissed_關閉中連續兩則失敗_只呈現後一則() async {
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
        await store.send(.writes(.delegate(.failed(.settle))))
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
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
