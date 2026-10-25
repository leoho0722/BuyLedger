//
//  CampaignFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftData
import SwiftUI

@testable import BuyLedger

/// 提供開團與根功能測試共用的表單狀態、提示、詳情堆疊元素與重新載入用的資料庫
enum CampaignFeatureTestSupport {}

// MARK: - Nested Types

extension CampaignFeatureTestSupport {

    /// 重新載入前要在唯讀資料庫上觸發的失敗寫入操作種類
    enum ReloadConsistencyWrite: Sendable {

        /// 使用者新增開團，寫入時依序配發新的識別碼
        case create

        /// 使用者儲存既有開團的修改
        case save

        /// 使用者刪除既有開團
        case remove
    }

    /// 儲存開團後提醒子 Feature 收到的請求案例：建立、提醒時間重建與改名重建
    struct ReminderRequestScenario: Sendable {

        /// 新增與提醒時間重建的輸入與預期請求；提醒與事件時間以 UTC 的 epoch 秒數明寫，新開團的日期取固定現在時間
        static let scenarios = [
            Self(
                original: nil,
                existingCampaigns: [],
                links: [:],
                draftName: "新團",
                reminderTimestamp: Date(timeIntervalSince1970: 1_776_708_000),
                expectedCampaign: Campaign(
                    id: "00000000-0000-0000-0000-000000000001",
                    name: "新團",
                    openDate: TestDependencies.fixedNow,
                    closeDate: TestDependencies.fixedNow,
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
                expectedRequest: CampaignReminderRequest(
                    campaignID: "00000000-0000-0000-0000-000000000001",
                    reconcile: .create,
                    title: "「新團」訂購提醒",
                    eventDate: Date(timeIntervalSince1970: 1_776_643_200),
                    alarmOffset: 64_800,
                    timestamp: Date(timeIntervalSince1970: 1_776_708_000)
                )
            ),
            Self(
                original: Campaign.fixture(
                    id: "C1",
                    name: "四月團",
                    openDate: Date(timeIntervalSince1970: 1_775_001_600),
                    closeDate: Date(timeIntervalSince1970: 1_776_643_200),
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
                existingCampaigns: [
                    Campaign.fixture(
                        id: "C1",
                        name: "四月團",
                        openDate: Date(timeIntervalSince1970: 1_775_001_600),
                        closeDate: Date(timeIntervalSince1970: 1_776_643_200),
                        status: .ongoing,
                        settledDate: nil,
                        notes: ""
                    ),
                ],
                links: [
                    "C1": CampaignReminderLink(
                        eventIdentifier: "EVT-old",
                        reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
                    ),
                ],
                draftName: "四月團",
                reminderTimestamp: Date(timeIntervalSince1970: 1_777_226_400),
                expectedCampaign: Campaign(
                    id: "C1",
                    name: "四月團",
                    openDate: Date(timeIntervalSince1970: 1_775_001_600),
                    closeDate: Date(timeIntervalSince1970: 1_776_643_200),
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
                expectedRequest: CampaignReminderRequest(
                    campaignID: "C1",
                    reconcile: .rebuild(oldEventIdentifier: "EVT-old"),
                    title: "「四月團」訂購提醒",
                    eventDate: Date(timeIntervalSince1970: 1_777_161_600),
                    alarmOffset: 64_800,
                    timestamp: Date(timeIntervalSince1970: 1_777_226_400)
                )
            ),
        ]

        /// 原開團改名時的輸入與預期請求，不併入 `scenarios`
        static let renamedScenario = Self(
            original: Campaign.fixture(
                id: "C1",
                name: "舊團名",
                openDate: Date(timeIntervalSince1970: 1_775_001_600),
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            existingCampaigns: [
                Campaign.fixture(
                    id: "C1",
                    name: "舊團名",
                    openDate: Date(timeIntervalSince1970: 1_775_001_600),
                    closeDate: nil,
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
            ],
            links: [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-old",
                    reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
                ),
            ],
            draftName: "新團名",
            reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600),
            expectedCampaign: Campaign(
                id: "C1",
                name: "新團名",
                openDate: Date(timeIntervalSince1970: 1_775_001_600),
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            expectedRequest: CampaignReminderRequest(
                campaignID: "C1",
                reconcile: .rebuild(oldEventIdentifier: "EVT-old"),
                title: "「新團名」訂購提醒",
                eventDate: Date(timeIntervalSince1970: 1_776_643_200),
                alarmOffset: 32_400,
                timestamp: Date(timeIntervalSince1970: 1_776_675_600)
            )
        )

        /// 開啟表單時編輯的原開團；新開團為 `nil`
        let original: Campaign?

        /// 儲存前已在共用清單中的開團
        let existingCampaigns: [Campaign]

        /// 儲存前共用的提醒連結
        let links: [Campaign.ID: CampaignReminderLink]

        /// 使用者在表單輸入的開團名稱
        let draftName: String

        /// 使用者在表單選定的提醒時間
        let reminderTimestamp: Date

        /// 儲存後預期寫入共用清單的開團
        let expectedCampaign: Campaign

        /// 提醒子 Feature 預期收到的請求
        let expectedRequest: CampaignReminderRequest
    }
}

// MARK: - Computed Properties

extension CampaignFeatureTestSupport {

    /// 使用者拒絕行事曆權限時可前往系統設定的提示
    static var accessDeniedAlert: CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("campaigns.general.label.calendarAccessRequired")
            } actions: {
                ButtonState(action: .openSettings) {
                    TextState("orders.general.label.openSettings")
                }
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.allowCalendarAccess")
            }
        )
    }

    /// 表單有未儲存變更時，按下取消會呈現的捨棄確認
    static var discardAlert: AlertState<CampaignEditFeature.Action.DiscardAlert> {
        AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("campaigns.edit.message.campaignHasUnsaved")
        }
    }
}

// MARK: - Internal Method

extension CampaignFeatureTestSupport {

    /// 建立沒有任何變更的新增開團表單狀態
    ///
    /// - Returns: 識別值與日期皆為固定值的表單狀態
    static func makeEditState() -> CampaignEditFeature.State {
        CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
    }

    /// 建立指向指定開團的詳情堆疊元素，資料與傳入的 `state` 共用
    ///
    /// - Parameters:
    ///   - campaignID: 要顯示詳情的開團識別值
    ///   - state: 提供共用資料的 `CampaignFeature` 狀態
    /// - Returns: 預期被推入堆疊的詳情元素
    /// - Note: `send` 的預期 closure 可直接 `append`
    /// - Note: `receive` 要以 `path[id:]` 明指實際配發的 id
    static func detailPath(
        _ campaignID: Campaign.ID,
        in state: CampaignFeature.State
    ) -> CampaignFeature.Path.State {
        .detail(
            CampaignDetailFeature.State(
                campaignID: campaignID,
                campaigns: SharedReader(state.$campaigns),
                orders: SharedReader(state.$orders),
                reminderLinks: SharedReader(state.$reminderLinks),
                isShowingUnpaidOnly: state.$isShowingUnpaidOnly
            )
        )
    }

    /// 建立結團確認對話框
    ///
    /// - Parameters:
    ///   - id: 要結團的開團識別碼
    ///   - name: 要結團的開團名稱
    /// - Returns: 結團提示狀態
    static func settleAlert(
        id: Campaign.ID,
        name: String
    ) -> CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("campaigns.detail.label.campaignSettlement")
            } actions: {
                ButtonState(action: .confirmSettle(id)) {
                    TextState("campaigns.list.label.settle")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "campaigns.detail.message.settleUndoneNotice",
                        defaultValue: "\(name)"
                    )
                )
            }
        )
    }

    /// 建立刪除確認對話框
    ///
    /// - Parameters:
    ///   - id: 要刪除的開團識別碼
    ///   - name: 要刪除的開團名稱
    /// - Returns: 刪除提示狀態
    static func deletionAlert(
        id: Campaign.ID,
        name: String
    ) -> CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.general.label.deleteCampaign")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(id)) {
                    TextState("common.action.button.delete")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "campaigns.detail.message.deleteUndoneNotice",
                        defaultValue: "\(name)"
                    )
                )
            }
        )
    }

    /// 建立標題為「操作失敗」的寫入失敗提示
    ///
    /// - Parameter message: 要顯示的錯誤訊息
    /// - Returns: 錯誤提示狀態
    static func failureAlert(
        _ message: LocalizedStringKey
    ) -> CampaignPresentationFeature.Destination.State {
        titledAlert("orders.list.label.operationFailed", message: message)
    }

    /// 建立只有「知道了」按鈕、標題自訂的提示
    ///
    /// - Parameters:
    ///   - title: 提示標題
    ///   - message: 提示訊息
    /// - Returns: 提示狀態
    static func titledAlert(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey
    ) -> CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState(title)
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState(message)
            }
        )
    }

    /// 建立含初始開團的 V17 唯讀資料庫
    ///
    /// - Parameter initialCampaigns: 要寫入資料庫的開團清單
    /// - Returns: 只能讀取的資料庫與專屬暫存目錄
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時丟出系統錯誤；寫入初始開團失敗時丟出 `PersistenceError`
    static func makeReloadConsistencyDatabase(
        seeding initialCampaigns: [Campaign]
    ) async throws -> (database: BuyLedgerDatabase, directoryURL: URL) {
        let directoryURL = FileManager.default.temporaryDirectory
            .appending(
                path: "BuyLedgerCampaignReloadTest-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        var isDirectoryTransferred = false
        defer {
            if !isDirectoryTransferred {
                BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
            }
        }
        let storeURL = directoryURL.appending(
            path: "CampaignReload.store",
            directoryHint: .notDirectory
        )
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let writableConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let writableContainer = try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: writableConfiguration
            )
        }
        let writableDatabase = BuyLedgerDatabase(
            modelContainer: writableContainer,
            storeLocation: .directory(directoryURL)
        )
        let campaignService = CampaignServiceTestSupport.makeService(database: writableDatabase)
        for campaign in initialCampaigns {
            try await campaignService.saveCampaign(campaign)
        }

        let readOnlyConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let readOnlyContainer = try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: readOnlyConfiguration
            )
        }
        let database = BuyLedgerDatabase(
            modelContainer: readOnlyContainer,
            storeLocation: .directory(directoryURL)
        )
        isDirectoryTransferred = true
        return (database, directoryURL)
    }

    /// 建立只注入重新載入與指定失敗寫入的 `CampaignFeature` `TestStore`
    ///
    /// - Parameters:
    ///   - initialState: 測試開始時的 `CampaignFeature` 狀態
    ///   - database: 重新載入與失敗寫入使用的唯讀資料庫
    ///   - write: 要注入的寫入操作
    /// - Returns: 已注入唯讀資料庫與指定寫入的 `TestStore`
    @MainActor
    static func makeReloadConsistencyStore(
        initialState: CampaignFeature.State,
        database: any BuyLedgerDatabaseProtocol,
        write: ReloadConsistencyWrite
    ) -> TestStoreOf<CampaignFeature> {
        let campaignService = CampaignServiceTestSupport.makeService(database: database)

        return TestStore(initialState: initialState) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = campaignService.fetchCampaigns
            switch write {
            case .create:
                $0.uuid = .incrementing
                $0.campaignService.saveCampaign = campaignService.saveCampaign

            case .save:
                $0.campaignService.saveCampaign = campaignService.saveCampaign

            case .remove:
                $0.campaignService.removeCampaign = campaignService.removeCampaign
            }
        }
    }
}
