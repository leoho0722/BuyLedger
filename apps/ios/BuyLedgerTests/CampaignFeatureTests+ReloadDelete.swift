//
//  CampaignFeatureTests+ReloadDelete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 開團列表刪除失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_開團列表刪除失敗後重新載入_呈現清單一致() async throws {
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
            $0.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("orders.general.label.deleteCampaign")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete("C1")) {
                        TextState("common.action.button.delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("common.action.cancel")
                    }
                } message: {
                    TextState(
                        LocalizedStringResource(
                            "campaigns.detail.message.deleteUndoneNotice",
                            defaultValue: "\("團")"
                        )
                    )
                }
            )
        }
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("C1")))))) {
            $0.presentation.destination = nil
        }
        await store.receive(\.presentation.delegate.deleteConfirmed, "C1")
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, .writeFailure(.delete)) {
            $0.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("orders.list.label.operationFailed")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("orders.merge.label.ok")
                    }
                } message: {
                    TextState("campaigns.general.message.campaignDeletedTry")
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

    /// 明細刪除失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 `SwiftData` 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func list_明細刪除失敗後重新載入_呈現清單一致() async throws {
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
            write: .remove
        )

        await store.send(.path(.element(id: detailID, action: .detail(.view(.deleteTapped)))))
        await store.receive(\.path[id: detailID].detail.delegate.requested) {
            $0.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("orders.general.label.deleteCampaign")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete("C1")) {
                        TextState("common.action.button.delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("common.action.cancel")
                    }
                } message: {
                    TextState(
                        LocalizedStringResource(
                            "campaigns.detail.message.deleteUndoneNotice",
                            defaultValue: "\("團")"
                        )
                    )
                }
            )
        }
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("C1")))))) {
            $0.presentation.destination = nil
        }
        await store.receive(\.presentation.delegate.deleteConfirmed, "C1")
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, .writeFailure(.delete)) {
            $0.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("orders.list.label.operationFailed")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("orders.merge.label.ok")
                    }
                } message: {
                    TextState("campaigns.general.message.campaignDeletedTry")
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
