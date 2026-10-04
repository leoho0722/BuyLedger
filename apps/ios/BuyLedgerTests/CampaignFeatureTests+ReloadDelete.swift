//
//  CampaignFeatureTests+ReloadDelete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 開團列表刪除失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_開團列表刪除失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .remove
        )

        await store.send(.list(.view(.deleteCampaignTapped("C1"))))
        await store.receive(\.list.delegate.requested) {
            $0.destination = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.destination(.presented(.alert(.confirmDelete("C1"))))) {
            $0.destination = nil
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("開團刪除失敗，請稍後再試。")
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

    /// 明細刪除失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_明細刪除失敗後重新載入_呈現清單一致() async throws(any Error) {
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
            write: .remove
        )

        await store.send(.path(.element(id: detailID, action: .detail(.view(.deleteTapped)))))
        await store.receive(\.path[id: detailID].detail.delegate.requested) {
            $0.destination = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.destination(.presented(.alert(.confirmDelete("C1"))))) {
            $0.destination = nil
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("開團刪除失敗，請稍後再試。")
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
