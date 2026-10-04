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
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_開團儲存失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let existing = Campaign.fixture(
            id: "C1",
            name: "既有團",
            closeDate: nil,
            status: .ongoing
        )
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [existing]
        }
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [existing])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .create
        )

        await store.send(.list(.view(.newCampaignTapped)))
        await store.receive(\.list.delegate.requested) {
            $0.destination = .edit(
                CampaignEditFeature.State(
                    id: UUID(0),
                    currentDate: TestDependencies.fixedNow,
                    reminderTimestamp: Date(timeIntervalSince1970: 1_777_539_600)
                )
            )
        }
        await store.send(.destination(.presented(.edit(.binding(.set(\.draft.name, "新團")))))) {
            $0.destination?.modify(\.edit) {
                $0.draft.name = "新團"
            }
        }
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.presentationQueue.pendingNotice = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }

        // When
        await store.send(.list(.view(.task))) {
            $0.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.list.isLoading = true
        }

        // Then
        await store.receive(\.list.campaignsResponse.success) {
            $0.list.hasLoaded = true
            $0.list.isLoading = false
            $0.$campaigns.withLock {
                $0 = [existing]
            }
        }
    }

    /// 開團狀態寫入失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_開團狀態寫入失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
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
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }

        // When
        await store.send(.list(.view(.task))) {
            $0.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.list.isLoading = true
        }

        // Then
        await store.receive(\.list.campaignsResponse.success) {
            $0.list.hasLoaded = true
            $0.list.isLoading = false
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }

    /// 開團結算失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_開團結算失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .closed
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
            $0.destination = Self.settleAlert(id: "C1", name: "團")
        }
        await store.send(.destination(.presented(.alert(.confirmSettle("C1"))))) {
            $0.destination = nil
        }
        await store.receive(\.writes.settleRequested)
        await store.receive(\.writes.settleResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("結團失敗，請稍後再試。")
        }

        // When
        await store.send(.list(.view(.task))) {
            $0.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.list.isLoading = true
        }

        // Then
        await store.receive(\.list.campaignsResponse.success) {
            $0.list.hasLoaded = true
            $0.list.isLoading = false
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }
}
