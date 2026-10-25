//
//  CampaignFeatureReloadTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋開團儲存、狀態變更與結算寫入失敗後，重新載入的清單與資料庫一致
@MainActor
struct CampaignFeatureReloadTests {

    /// 驗證表單儲存開團失敗後重新載入，清單與唯讀資料庫中的開團一致
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時丟出系統錯誤；寫入初始開團失敗時丟出 `PersistenceError`
    @Test
    func list_開團儲存失敗後重新載入_呈現清單一致() async throws {
        // Given
        let existing = Campaign(
            id: "C1",
            name: "既有團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: Date(timeIntervalSince1970: 1_777_507_200),
            reminderTimestamp: Date(timeIntervalSince1970: 1_777_539_600)
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [existing]
        }
        initial.presentation.destination = .edit(editState)
        let fixture = try await CampaignFeatureTestSupport.makeReloadConsistencyDatabase(seeding: [
            existing,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = CampaignFeatureTestSupport.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .create
        )

        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, .writeFailure(.save)) {
            $0.presentation.queue.pendingNotice = .alert(
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
        }

        // When
        let loading = await store.send(.list(.view(.task))) {
            $0.list.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await loading.finish()
        await store.receive(\.list.delegate.loadRequested) {
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.$campaigns.withLock {
                $0 = [existing]
            }
        }
        await store.receive(\.load.loadRequested)
        await store.receive(\.load.campaignsResponse.success)
    }

    /// 驗證從詳情頁變更開團狀態寫入失敗後重新載入，清單與唯讀資料庫中的開團一致
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時丟出系統錯誤；寫入初始開團失敗時丟出 `PersistenceError`
    @Test
    func list_開團狀態寫入失敗後重新載入_呈現清單一致() async throws {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        let detailID = try #require(initial.path.ids.first)
        let fixture = try await CampaignFeatureTestSupport.makeReloadConsistencyDatabase(seeding: [
            campaign,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = CampaignFeatureTestSupport.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .save
        )

        await store.send(\.path[id: detailID].detail.view.statusChanged, .closed)
        await store.receive(\.path[id: detailID].detail.delegate.requested)
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, .writeFailure(.status)) {
            $0.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("orders.list.label.operationFailed")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("orders.merge.label.ok")
                    }
                } message: {
                    TextState("campaigns.general.message.campaignStatusUpdated")
                }
            )
        }

        // When
        let loading = await store.send(.list(.view(.task))) {
            $0.list.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await loading.finish()
        await store.receive(\.list.delegate.loadRequested) {
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.receive(\.load.loadRequested)
        await store.receive(\.load.campaignsResponse.success)
    }

    /// 驗證從詳情頁結算開團失敗後重新載入，清單與唯讀資料庫中的開團一致
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時丟出系統錯誤；寫入初始開團失敗時丟出 `PersistenceError`
    @Test
    func list_開團結算失敗後重新載入_呈現清單一致() async throws {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        initial.presentation.destination = CampaignFeatureTestSupport.settleAlert(
            id: "C1",
            name: "團"
        )
        let fixture = try await CampaignFeatureTestSupport.makeReloadConsistencyDatabase(seeding: [
            campaign,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = CampaignFeatureTestSupport.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .save
        )

        await store.send(.presentation(.destination(.presented(.alert(.confirmSettle("C1")))))) {
            $0.presentation.destination = nil
        }
        await store.receive(\.presentation.delegate.settleConfirmed, "C1")
        await store.receive(\.writes.settleRequested)
        await store.receive(\.writes.settleResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, .writeFailure(.settle)) {
            $0.presentation.destination = .alert(
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
        }

        // When
        let loading = await store.send(.list(.view(.task))) {
            $0.list.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await loading.finish()
        await store.receive(\.list.delegate.loadRequested) {
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.receive(\.load.loadRequested)
        await store.receive(\.load.campaignsResponse.success)
    }
}
