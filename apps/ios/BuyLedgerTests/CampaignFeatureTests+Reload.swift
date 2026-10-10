//
//  CampaignFeatureTests+Reload.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 儲存失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
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
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [existing])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
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
                    TextState("操作失敗")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("知道了")
                    }
                } message: {
                    TextState("開團儲存失敗，請稍後再試。")
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

    /// 開團狀態寫入失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
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
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
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
                    TextState("操作失敗")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("知道了")
                    }
                } message: {
                    TextState("開團狀態更新失敗，請稍後再試。")
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

    /// 開團結算失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
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
        let detailID = try #require(initial.path.ids.first)
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .save
        )

        await store.send(\.path[id: detailID].detail.view.settleTapped)
        await store.receive(\.path[id: detailID].detail.delegate.requested) {
            $0.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("結團結算")
                } actions: {
                    ButtonState(action: .confirmSettle("C1")) {
                        TextState("結團")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState("結算「團」後就無法再改回進行中。確定要結團嗎？")
                }
            )
        }
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
                    TextState("操作失敗")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("知道了")
                    }
                } message: {
                    TextState("結團失敗，請稍後再試。")
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
